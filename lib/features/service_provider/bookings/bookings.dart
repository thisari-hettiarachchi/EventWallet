import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/provider_bottom_nav.dart';
import '../../../services/booking_service.dart';
import '../../../services/chat_service.dart';
import '../../chat/booking_chat_list_page.dart';
import '../../chat/booking_chat_thread_page.dart';

class ServiceProviderBookingsPage extends StatefulWidget {
  const ServiceProviderBookingsPage({
    super.key,
    this.initialBookingId,
    this.initialStatus,
  });

  final String? initialBookingId;
  final String? initialStatus;

  @override
  State<ServiceProviderBookingsPage> createState() =>
      _ServiceProviderBookingsPageState();
}

class _ServiceProviderBookingsPageState
    extends State<ServiceProviderBookingsPage>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateBookingStatus(
    String bookingId,
    String status, {
    String? statusReason,
    String? cancelledBy,
  }) async {
    final normalizedStatus = BookingStatuses.normalize(status);

    final updateData = <String, dynamic>{
      'status': normalizedStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (normalizedStatus == BookingStatuses.rejected) {
      updateData['statusReason'] = statusReason ?? 'rejected';

      if ((cancelledBy ?? '').isNotEmpty) {
        updateData['cancelledBy'] = cancelledBy;
        updateData['cancelledAt'] = FieldValue.serverTimestamp();
      } else {
        updateData['cancelledBy'] = FieldValue.delete();
        updateData['cancelledAt'] = FieldValue.delete();
      }
    } else {
      updateData['statusReason'] = FieldValue.delete();
      updateData['cancelledBy'] = FieldValue.delete();
      updateData['cancelledAt'] = FieldValue.delete();
    }

    var shouldCleanupLegacyExpense = false;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final bookingRef =
            FirebaseFirestore.instance.collection('bookings').doc(bookingId);
        final bookingSnap = await transaction.get(bookingRef);

        if (!bookingSnap.exists) return;

        final data = bookingSnap.data() as Map<String, dynamic>;
        final oldStatus = BookingStatuses.normalize(data['status']);
        final eventId = data['eventId']?.toString();
        final amount = bookingAmountFrom(data['amount']);

        // Fetch event data BEFORE any updates to satisfy transaction requirements
        DocumentSnapshot? eventSnap;
        if (eventId != null && eventId.isNotEmpty) {
          eventSnap = await transaction.get(
            FirebaseFirestore.instance.collection('events').doc(eventId),
          );
        }

        // Update booking status
        transaction.update(bookingRef, updateData);

        // Update event budget if status changed
        if (eventSnap != null && eventSnap.exists && oldStatus != normalizedStatus) {
          final eventData = eventSnap.data() as Map<String, dynamic>?;
          final spentValue = eventData?['spent'];
          final currentSpent = spentValue is num
              ? spentValue.toDouble()
              : double.tryParse(spentValue?.toString() ?? '') ?? 0.0;

          // Define which statuses count towards the budget
          final bool wasActive = oldStatus == BookingStatuses.accepted || 
                               oldStatus == BookingStatuses.completed;
          final bool isNowActive = normalizedStatus == BookingStatuses.accepted || 
                                 normalizedStatus == BookingStatuses.completed;

          if (isNowActive && !wasActive) {
            // Add to budget
            transaction.update(eventSnap.reference, {'spent': currentSpent + amount});

            // Keep one canonical expense doc per booking
            final expenseRef = FirebaseFirestore.instance
                .collection('expenses')
                .doc(bookingId);
            transaction.set(expenseRef, {
              'userId': data['userId'],
              'title': '${data['providerName']} - ${bookingPackageNameFrom(data)}',
              'amount': amount,
              'category': data['providerType'] ?? 'Service',
              'eventId': eventId,
              'bookingId': bookingId,
              'timestamp': FieldValue.serverTimestamp(),
            });
          } else if (!isNowActive && wasActive) {
            // Remove from budget
            transaction.update(eventSnap.reference, {
              'spent': (currentSpent - amount).clamp(0.0, double.infinity),
            });

            // Remove canonical expense doc
            final expenseRef = FirebaseFirestore.instance
                .collection('expenses')
                .doc(bookingId);
            transaction.delete(expenseRef);
            shouldCleanupLegacyExpense = true;
          }
        }
      });

      if (shouldCleanupLegacyExpense) {
        final legacyExpenses = await FirebaseFirestore.instance
            .collection('expenses')
            .where('bookingId', isEqualTo: bookingId)
            .get();

        final cleanupBatch = FirebaseFirestore.instance.batch();
        var deleteCount = 0;
        for (final doc in legacyExpenses.docs) {
          if (doc.id != bookingId) {
            cleanupBatch.delete(doc.reference);
            deleteCount++;
          }
        }
        if (deleteCount > 0) {
          await cleanupBatch.commit();
        }
      }

      await ChatService().syncThreadMetadataForBooking(bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking ${BookingStatuses.label(normalizedStatus).toLowerCase()} successfully',
              style: TextStyle(fontSize: 14.sp),
            ),
            backgroundColor: _getStatusColor(normalizedStatus),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: TextStyle(fontSize: 14.sp)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int _initialTabIndex() {
    switch (BookingStatuses.normalize(widget.initialStatus)) {
      case BookingStatuses.accepted:
        return 1;
      case BookingStatuses.rejected:
        return 2;
      case BookingStatuses.completed:
        return 3;
      case BookingStatuses.pending:
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('Please login', style: TextStyle(fontSize: 16.sp)),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      initialIndex: _initialTabIndex(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF00897B), Color(0xFF1565C0)],
              stops: [0.0, 0.3],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 20.h),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(35.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        TabBar(
                          isScrollable: true,
                          labelColor: const Color(0xFF00897B),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF00897B),
                          indicatorWeight: 3.h,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                          tabs: const [
                            Tab(text: 'Pending'),
                            Tab(text: 'Accepted'),
                            Tab(text: 'Cancelled'),
                            Tab(text: 'History'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildBookingList(BookingStatuses.pending),
                              _buildBookingList(BookingStatuses.accepted),
                              _buildBookingList(BookingStatuses.rejected),
                              _buildBookingList(BookingStatuses.completed),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const ProviderBottomNav(currentIndex: 1),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            Text(
              'My Bookings',
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5.w,
              ),
            ),
            const Spacer(),
            if (user != null)
              _BookingInboxButton(userId: user!.uid, isProviderView: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(String status, {String? otherStatus}) {
    final statusFilters = {
      ...BookingStatuses.aliasesFor(status),
      if (otherStatus != null) ...BookingStatuses.aliasesFor(otherStatus),
    }.toList();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00897B)),
          );
        }

        final docs =
            (snapshot.data?.docs ?? const <QueryDocumentSnapshot>[]).where((
              doc,
            ) {
              final data = doc.data() as Map<String, dynamic>;
              return statusFilters.contains(
                BookingStatuses.normalize(data['status']),
              );
            }).toList()..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aDate =
                  bookingEventDateFromMap(aData) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate =
                  bookingEventDateFromMap(bData) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return aDate.compareTo(bDate);
            });

        if ((widget.initialBookingId ?? '').isNotEmpty) {
          docs.sort((a, b) {
            if (a.id == widget.initialBookingId) return -1;
            if (b.id == widget.initialBookingId) return 1;
            return 0;
          });
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80.sp, color: Colors.grey[300]),
                SizedBox(height: 16.h),
                Text(
                  'No ${BookingStatuses.label(status).toLowerCase()} bookings',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildBookingCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(String id, Map<String, dynamic> data) {
    final DateTime? eventDate = bookingEventDateFromMap(data);
    final String status = BookingStatuses.normalize(data['status']);
    final double amount = bookingAmountFrom(data['amount']);
    final String packageName = bookingPackageNameFrom(data);

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4.h,
              width: double.infinity,
              color: _getStatusColor(status),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bookingEventNameFrom(data),
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1F36),
                          ),
                        ),
                      ),
                      _buildStatusBadge(data),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoTile(
                    Icons.person,
                    'Client',
                    bookingClientNameFrom(data),
                    const Color(0xFF1565C0),
                  ),
                  _buildInfoTile(
                    Icons.calendar_today,
                    'Date',
                    eventDate != null ? _formatDate(eventDate) : 'Date not set',
                    const Color(0xFF00897B),
                  ),
                  _buildInfoTile(
                    Icons.location_on,
                    'Location',
                    bookingLocationFrom(data),
                    Colors.orange,
                  ),
                  _buildInfoTile(
                    Icons.category,
                    'Event Type',
                    firstNonEmpty([data['eventType']], fallback: 'N/A'),
                    Colors.purple,
                  ),
                  _buildInfoTile(
                    Icons.inventory_2_outlined,
                    'Package',
                    packageName,
                    const Color(0xFF00897B),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: const Divider(height: 1),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount Selected',
                        style: TextStyle(
                          color: const Color(0xFF4A5568),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        amount > 0 ? '\$${amount.toStringAsFixed(2)}' : 'TBD',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00897B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _BookingChatSection(
                    bookingId: id,
                    bookingData: data,
                    isProviderView: true,
                  ),
                ],
              ),
            ),
            if (status == BookingStatuses.pending)
              _buildPendingActions(id)
            else if (status == BookingStatuses.accepted)
              _buildAcceptedActions(id),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingActions(String id) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _updateBookingStatus(
                  id,
                  BookingStatuses.rejected,
                  statusReason: 'rejected',
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 20.sp, color: Colors.red[700]),
                      SizedBox(width: 8.w),
                      Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1.w, height: 30.h, color: Colors.grey[300]),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _updateBookingStatus(id, BookingStatuses.accepted),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        size: 20.sp,
                        color: const Color(0xFF00897B),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Accept',
                        style: TextStyle(
                          color: const Color(0xFF00897B),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedActions(String id) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _updateBookingStatus(
                  id,
                  BookingStatuses.rejected,
                  statusReason: 'cancelled',
                  cancelledBy: 'provider',
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 20.sp,
                        color: Colors.red[700],
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1.w, height: 30.h, color: Colors.grey[300]),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    _updateBookingStatus(id, BookingStatuses.completed),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 20.sp,
                        color: const Color(0xFF1565C0),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Complete',
                        style: TextStyle(
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF1A1F36),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (BookingStatuses.normalize(status)) {
      case BookingStatuses.accepted:
        return const Color(0xFF00897B);
      case BookingStatuses.rejected:
        return Colors.red;
      case BookingStatuses.completed:
        return const Color(0xFF1565C0);
      case BookingStatuses.pending:
      default:
        return Colors.orange;
    }
  }

  Widget _buildStatusBadge(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? BookingStatuses.pending;
    final color = _getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        bookingStatusLabelFrom(data).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5.w,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _BookingInboxButton extends StatelessWidget {
  const _BookingInboxButton({
    required this.userId,
    required this.isProviderView,
  });

  final String userId;
  final bool isProviderView;

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: isProviderView
          ? chatService.watchThreadsForProvider(userId)
          : chatService.watchThreadsForUser(userId),
      builder: (context, snapshot) {
        final unreadCount = (snapshot.data?.docs ?? const []).fold<int>(
          0,
          (total, doc) =>
              total + bookingChatUnreadCountFrom(doc.data(), userId),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingChatListPage(isProviderView: isProviderView),
                    ),
                  );
                },
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 22.sp,
                ),
                tooltip: 'Messages',
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2.w,
                top: -4.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3D00),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(color: Colors.white, width: 2.w),
                  ),
                  constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.h),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BookingChatSection extends StatelessWidget {
  const _BookingChatSection({
    required this.bookingId,
    required this.bookingData,
    required this.isProviderView,
  });

  final String bookingId;
  final Map<String, dynamic> bookingData;
  final bool isProviderView;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final chatService = ChatService();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: chatService.watchThread(bookingId),
      builder: (context, snapshot) {
        final threadData = snapshot.data?.data();
        final unreadCount = threadData == null
            ? 0
            : bookingChatUnreadCountFrom(threadData, currentUser.uid);
        final preview = threadData == null
            ? 'Start a booking chat with your client.'
            : bookingChatLastMessagePreviewFrom(threadData);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(0xFF1565C0).withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 18.sp,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Booking Chat',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1F36),
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount new',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.45,
                  color: const Color(0xFF4A5568),
                  fontWeight: unreadCount > 0
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await chatService.ensureThreadExistsForBooking(
                      bookingId: bookingId,
                      bookingData: bookingData,
                    );
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingChatThreadPage(
                          bookingId: bookingId,
                          initialThreadData: {
                            ...bookingData,
                            if (threadData != null) ...threadData,
                          },
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.forum_outlined, size: 18.sp),
                  label: Text(
                    isProviderView ? 'Open Client Chat' : 'Message Provider',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    side: BorderSide(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.25),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

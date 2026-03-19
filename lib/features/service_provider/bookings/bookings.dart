import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/provider_bottom_nav.dart';
import '../../../services/booking_service.dart';
import '../../../services/chat_service.dart';
import '../../chat/booking_chat_list_page.dart';
import 'booking_details_page.dart';

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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceProviderBookingDetailsPage(bookingId: id),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.event,
                color: _getStatusColor(status),
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bookingEventNameFrom(data),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1F36),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _buildStatusBadge(data),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    bookingClientNameFrom(data),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF4A5568),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14.sp, color: Colors.grey),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          eventDate != null ? _formatDate(eventDate) : 'Date not set',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        amount > 0
                            ? 'Rs. ${amount.toStringAsFixed(2)}'
                            : 'TBD',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00897B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right, color: Colors.grey[500], size: 24.sp),
          ],
        ),
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


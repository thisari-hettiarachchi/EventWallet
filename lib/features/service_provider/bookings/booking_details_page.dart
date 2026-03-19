import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/chat_service.dart';
import '../../chat/booking_chat_thread_page.dart';

class ServiceProviderBookingDetailsPage extends StatefulWidget {
  const ServiceProviderBookingDetailsPage({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  State<ServiceProviderBookingDetailsPage> createState() =>
      _ServiceProviderBookingDetailsPageState();
}

class _ServiceProviderBookingDetailsPageState
    extends State<ServiceProviderBookingDetailsPage> {
  bool _isUpdating = false;

  Future<void> _updateBookingStatus(
    String status, {
    String? statusReason,
    String? cancelledBy,
  }) async {
    if (_isUpdating) return;

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
    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final bookingRef =
            FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);
        final bookingSnap = await transaction.get(bookingRef);
        if (!bookingSnap.exists) return;

        final data = bookingSnap.data() as Map<String, dynamic>;
        final oldStatus = BookingStatuses.normalize(data['status']);
        final eventId = data['eventId']?.toString();
        final amount = bookingAmountFrom(data['amount']);

        DocumentSnapshot? eventSnap;
        if (eventId != null && eventId.isNotEmpty) {
          eventSnap = await transaction.get(
            FirebaseFirestore.instance.collection('events').doc(eventId),
          );
        }

        transaction.update(bookingRef, updateData);

        if (eventSnap != null && eventSnap.exists && oldStatus != normalizedStatus) {
          final eventData = eventSnap.data() as Map<String, dynamic>?;
          final spentValue = eventData?['spent'];
          final currentSpent = spentValue is num
              ? spentValue.toDouble()
              : double.tryParse(spentValue?.toString() ?? '') ?? 0.0;

          final wasActive =
              oldStatus == BookingStatuses.accepted || oldStatus == BookingStatuses.completed;
          final isNowActive = normalizedStatus == BookingStatuses.accepted ||
              normalizedStatus == BookingStatuses.completed;

          if (isNowActive && !wasActive) {
            transaction.update(eventSnap.reference, {'spent': currentSpent + amount});

            final expenseRef =
                FirebaseFirestore.instance.collection('expenses').doc(widget.bookingId);
            transaction.set(expenseRef, {
              'userId': data['userId'],
              'title': '${data['providerName']} - ${bookingPackageNameFrom(data)}',
              'amount': amount,
              'category': data['providerType'] ?? 'Service',
              'eventId': eventId,
              'bookingId': widget.bookingId,
              'timestamp': FieldValue.serverTimestamp(),
            });
          } else if (!isNowActive && wasActive) {
            transaction.update(eventSnap.reference, {
              'spent': (currentSpent - amount).clamp(0.0, double.infinity),
            });

            final expenseRef =
                FirebaseFirestore.instance.collection('expenses').doc(widget.bookingId);
            transaction.delete(expenseRef);
            shouldCleanupLegacyExpense = true;
          }
        }
      });

      if (shouldCleanupLegacyExpense) {
        final legacyExpenses = await FirebaseFirestore.instance
            .collection('expenses')
            .where('bookingId', isEqualTo: widget.bookingId)
            .get();

        final cleanupBatch = FirebaseFirestore.instance.batch();
        var deleteCount = 0;
        for (final doc in legacyExpenses.docs) {
          if (doc.id != widget.bookingId) {
            cleanupBatch.delete(doc.reference);
            deleteCount++;
          }
        }

        if (deleteCount > 0) {
          await cleanupBatch.commit();
        }
      }

      await ChatService().syncThreadMetadataForBooking(widget.bookingId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking ${BookingStatuses.label(normalizedStatus).toLowerCase()} successfully',
          ),
          backgroundColor: _statusColor(normalizedStatus),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Send notification to user/client about status change
      final bookingSnap =
          await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).get();
      final bookingData = bookingSnap.data();
      if (bookingData != null) {
        final userId = bookingData['userId'];
        final eventName = bookingData['eventName'] ?? 'Your booking';
        final statusLabel = BookingStatuses.label(normalizedStatus);

        String notificationMessage = '';
        if (normalizedStatus == BookingStatuses.accepted) {
          notificationMessage = '$statusLabel: $eventName has been accepted by the provider!';
        } else if (normalizedStatus == BookingStatuses.rejected) {
          notificationMessage = '$statusLabel: $eventName was declined by the provider.';
        } else if (normalizedStatus == BookingStatuses.completed) {
          notificationMessage = '$statusLabel: $eventName has been completed!';
        }

        if (notificationMessage.isNotEmpty && userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .add({
                'title': 'Booking $statusLabel',
                'message': notificationMessage,
                'type': 'booking',
                'bookingId': widget.bookingId,
                'providerId': bookingData['providerId'],
                'timestamp': FieldValue.serverTimestamp(),
                'isRead': false,
              });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              SizedBox(height: 20.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
                  ),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(widget.bookingId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryGreen),
                        );
                      }

                      final data = snapshot.data?.data();
                      if (data == null) {
                        return Center(
                          child: Text(
                            'Booking not found',
                            style: TextStyle(fontSize: 16.sp, color: AppColors.textGrey),
                          ),
                        );
                      }

                      return _buildContent(data);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'View complete information and manage booking actions.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final status = BookingStatuses.normalize(data['status']);
    final amount = bookingAmountFrom(data['amount']);
    final eventDate = bookingEventDateFromMap(data);

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 120.h),
      children: [
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14.r,
                offset: Offset(0, 5.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  _buildStatusBadge(status),
                ],
              ),
              SizedBox(height: 16.h),
              _infoTile(Icons.person, 'Client', bookingClientNameFrom(data), const Color(0xFF1565C0)),
              _infoTile(
                Icons.calendar_today,
                'Date',
                eventDate != null ? _formatDate(eventDate) : 'Date not set',
                const Color(0xFF00897B),
              ),
              _infoTile(Icons.location_on, 'Location', bookingLocationFrom(data), Colors.orange),
              _infoTile(
                Icons.category,
                'Event Type',
                firstNonEmpty([data['eventType']], fallback: 'N/A'),
                Colors.purple,
              ),
              _infoTile(
                Icons.inventory_2_outlined,
                'Package',
                bookingPackageNameFrom(data),
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
                    amount > 0
                        ? 'Rs. ${amount.toStringAsFixed(2)}'
                        : 'TBD',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF00897B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _BookingChatPanel(bookingId: widget.bookingId, bookingData: data),
        SizedBox(height: 16.h),
        if (status == BookingStatuses.pending)
          _buildPendingActions()
        else if (status == BookingStatuses.accepted)
          _buildAcceptedActions(),
      ],
    );
  }

  Widget _buildPendingActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUpdating
                ? null
                : () => _updateBookingStatus(
                      BookingStatuses.rejected,
                      statusReason: 'rejected',
                    ),
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isUpdating
                ? null
                : () => _updateBookingStatus(BookingStatuses.accepted),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptedActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUpdating
                ? null
                : () => _updateBookingStatus(
                      BookingStatuses.rejected,
                      statusReason: 'cancelled',
                      cancelledBy: 'provider',
                    ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isUpdating
                ? null
                : () => _updateBookingStatus(BookingStatuses.completed),
            icon: const Icon(Icons.task_alt),
            label: const Text('Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        BookingStatuses.label(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color color) {
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

  Color _statusColor(String status) {
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

class _BookingChatPanel extends StatelessWidget {
  const _BookingChatPanel({
    required this.bookingId,
    required this.bookingData,
  });

  final String bookingId;
  final Map<String, dynamic> bookingData;

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
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
                  fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
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
                  label: const Text('Open Client Chat'),
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


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/colors.dart';
import '../../../services/booking_service.dart';
import '../auth/login.dart';

class UserBookingStatusPage extends StatelessWidget {
  const UserBookingStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Future.microtask(() {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(35.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 12.h),
                        TabBar(
                          isScrollable: true,
                          labelColor: AppColors.primaryGreen,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppColors.primaryGreen,
                          indicatorWeight: 3.h,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                          tabs: const [
                            Tab(text: 'Pending'),
                            Tab(text: 'Accepted'),
                            Tab(text: 'Rejected'),
                            Tab(text: 'Completed'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _BookingTab(
                                userId: user.uid,
                                status: BookingStatuses.pending,
                                emptyTitle: 'No pending bookings',
                                emptySubtitle:
                                    'New booking requests will show up here until a provider responds.',
                                newestFirst: false,
                              ),
                              _BookingTab(
                                userId: user.uid,
                                status: BookingStatuses.accepted,
                                emptyTitle: 'No accepted bookings',
                                emptySubtitle:
                                    'Accepted or confirmed bookings will appear here.',
                                newestFirst: false,
                              ),
                              _BookingTab(
                                userId: user.uid,
                                status: BookingStatuses.rejected,
                                emptyTitle: 'No rejected bookings',
                                emptySubtitle:
                                    'Rejected or cancelled requests will appear here.',
                                newestFirst: true,
                              ),
                              _BookingTab(
                                userId: user.uid,
                                status: BookingStatuses.completed,
                                emptyTitle: 'No completed bookings',
                                emptySubtitle:
                                    'Completed bookings will appear here after the event is done.',
                                newestFirst: true,
                              ),
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
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Booking Requests',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Track every request from pending to completed.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTab extends StatelessWidget {
  const _BookingTab({
    required this.userId,
    required this.status,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.newestFirst,
  });

  final String userId;
  final String status;
  final String emptyTitle;
  final String emptySubtitle;
  final bool newestFirst;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (snapshot.hasError) {
          return const _BookingEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load bookings',
            subtitle: 'Please try again in a moment.',
          );
        }

        final docs =
            (snapshot.data?.docs ?? const <QueryDocumentSnapshot>[]).where((
              doc,
            ) {
              final data = doc.data() as Map<String, dynamic>;
              return BookingStatuses.normalize(data['status']) == status;
            }).toList()..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aDate =
                  bookingEventDateFromMap(aData) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate =
                  bookingEventDateFromMap(bData) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return newestFirst
                  ? bDate.compareTo(aDate)
                  : aDate.compareTo(bDate);
            });

        if (docs.isEmpty) {
          return _BookingEmptyState(
            icon: _statusIcon(status),
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 32.h),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _BookingCard(bookingId: doc.id, data: data);
          },
        );
      },
    );
  }

  static IconData _statusIcon(String status) {
    switch (BookingStatuses.normalize(status)) {
      case BookingStatuses.accepted:
        return Icons.verified_outlined;
      case BookingStatuses.rejected:
        return Icons.cancel_outlined;
      case BookingStatuses.completed:
        return Icons.task_alt_outlined;
      case BookingStatuses.pending:
      default:
        return Icons.hourglass_top_rounded;
    }
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.bookingId, required this.data});

  final String bookingId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = BookingStatuses.normalize(data['status']);
    final statusColor = _statusColor(status);
    final providerName = bookingProviderNameFrom(data);
    final eventName = bookingEventNameFrom(data);
    final eventDate = bookingEventDateFromMap(data);
    final packageName = bookingPackageNameFrom(data);
    final location = bookingLocationFrom(data);
    final amount = bookingAmountFrom(data['amount']);
    final eventType = firstNonEmpty([
      data['eventType'],
    ], fallback: 'Not specified');

    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 5.h, color: statusColor),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventName,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              providerName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      _StatusBadge(data: data),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _InfoTile(
                    icon: Icons.calendar_today,
                    label: 'Event Date',
                    value: eventDate == null
                        ? 'Date not set'
                        : _formatDate(eventDate),
                    color: AppColors.primaryGreen,
                  ),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: location,
                    color: Colors.orange,
                  ),
                  _InfoTile(
                    icon: Icons.sell_outlined,
                    label: 'Package',
                    value: packageName,
                    color: AppColors.primaryBlue,
                  ),
                  _InfoTile(
                    icon: Icons.category_outlined,
                    label: 'Event Type',
                    value: eventType,
                    color: Colors.purple,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: const Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount Selected',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              amount > 0
                                  ? '\$${amount.toStringAsFixed(2)}'
                                  : 'TBD',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Text(
                            _statusMessage(data),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (bookingCanBeCancelledByUser(data))
              _buildActionSection(context, status),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, String status) {
    final isAccepted = status == BookingStatuses.accepted;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: OutlinedButton.icon(
          onPressed: () =>
              _confirmAndCancelBooking(context, isAccepted: isAccepted),
          icon: Icon(Icons.close_rounded, color: AppColors.error, size: 18.sp),
          label: Text(
            isAccepted ? 'Cancel Booking' : 'Cancel Request',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
            foregroundColor: AppColors.error,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndCancelBooking(
    BuildContext context, {
    required bool isAccepted,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAccepted ? 'Cancel booking?' : 'Cancel request?'),
        content: Text(
          isAccepted
              ? 'This booking will move to the rejected/cancelled status and the provider will no longer treat it as active.'
              : 'This request will be removed from active bookings and moved to the rejected/cancelled status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              isAccepted ? 'Cancel Booking' : 'Cancel Request',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': BookingStatuses.rejected,
            'statusReason': 'cancelled',
            'cancelledBy': 'user',
            'cancelledByUid': user.uid,
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAccepted
                ? 'Booking cancelled successfully.'
                : 'Booking request cancelled successfully.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to cancel booking: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Color _statusColor(String status) {
    switch (BookingStatuses.normalize(status)) {
      case BookingStatuses.accepted:
        return AppColors.primaryGreen;
      case BookingStatuses.rejected:
        return AppColors.error;
      case BookingStatuses.completed:
        return AppColors.primaryBlue;
      case BookingStatuses.pending:
      default:
        return Colors.orange;
    }
  }

  static String _statusMessage(Map<String, dynamic> data) {
    final status = BookingStatuses.normalize(data['status']);
    final cancelledBy = data['cancelledBy']?.toString().trim().toLowerCase();

    switch (status) {
      case BookingStatuses.accepted:
        return 'Provider confirmed this booking';
      case BookingStatuses.rejected:
        if (bookingWasCancelled(data)) {
          if (cancelledBy == 'user') {
            return 'You cancelled this booking request';
          }
          if (cancelledBy == 'provider') {
            return 'Provider cancelled this booking';
          }
          return 'This booking was cancelled';
        }
        return 'This request was declined';
      case BookingStatuses.completed:
        return 'This booking has been completed';
      case BookingStatuses.pending:
      default:
        return 'Waiting for provider response';
    }
  }

  static String _formatDate(DateTime date) {
    const months = [
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.textDark,
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
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final color = _BookingCard._statusColor(
      data['status']?.toString() ?? BookingStatuses.pending,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
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
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _BookingEmptyState extends StatelessWidget {
  const _BookingEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 76.sp, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.5,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/colors.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import 'package:eventwallet/features/chat/booking_chat_thread_page.dart';

class BookingChatListPage extends StatefulWidget {
  const BookingChatListPage({super.key, required this.isProviderView});

  final bool isProviderView;

  @override
  State<BookingChatListPage> createState() => _BookingChatListPageState();
}

class _BookingChatListPageState extends State<BookingChatListPage> {
  final ChatService _chatService = ChatService();
  bool _isBackfilling = false;

  @override
  void initState() {
    super.initState();
    _ensureThreadsExist();
  }

  Future<void> _ensureThreadsExist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isBackfilling) return;

    setState(() => _isBackfilling = true);
    try {
      await _chatService.ensureThreadsForRole(
        currentUserId: user.uid,
        isProviderView: widget.isProviderView,
      );
    } catch (e) {
      debugPrint('Error ensuring threads: $e');
    } finally {
      if (mounted) {
        setState(() => _isBackfilling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(35.r),
                    ),
                  ),
                  child: user == null
                      ? _buildLoginPrompt()
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: widget.isProviderView
                        ? _chatService.watchThreadsForProvider(user.uid)
                        : _chatService.watchThreadsForUser(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        String title = 'Could not load messages';
                        String subtitle = 'Please try again in a moment.';

                        if (snapshot.error is FirebaseException &&
                            (snapshot.error as FirebaseException).code ==
                                'permission-denied') {
                          title = 'Error loading messages';
                          subtitle =
                          'The caller does not have permission to execute the specific operation.';
                        }

                        return _buildInfoState(
                          icon: Icons.error_outline,
                          title: title,
                          subtitle: subtitle,
                        );
                      }

                      final threads =
                          snapshot.data?.docs.toList() ??
                              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                      threads.sort(
                            (a, b) => bookingChatSortDateFrom(
                          b.data(),
                        ).compareTo(bookingChatSortDateFrom(a.data())),
                      );

                      if (threads.isEmpty) {
                        return _buildInfoState(
                          icon: Icons.chat_bubble_outline,
                          title: 'No booking chats yet',
                          subtitle: widget.isProviderView
                              ? 'Booking conversations with clients will appear here.'
                              : 'Your conversations with providers will appear here.',
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.primaryGreen,
                        onRefresh: _ensureThreadsExist,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            20.w,
                            18.h,
                            20.w,
                            32.h,
                          ),
                          itemCount: threads.length,
                          itemBuilder: (context, index) {
                            final doc = threads[index];
                            return _BookingChatThreadCard(
                              threadId: doc.id,
                              data: doc.data(),
                              currentUserId: user.uid,
                              isProviderView: widget.isProviderView,
                            );
                          },
                        ),
                      );
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
                  'Messages',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.isProviderView
                      ? 'Stay in sync with every client booking.'
                      : 'Chat with providers on each booking thread.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          if (_isBackfilling)
            SizedBox(
              width: 22.w,
              height: 22.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
                fontSize: 18.sp,
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

  Widget _buildLoginPrompt() {
    return Center(
      child: Text(
        'Please login to view your messages.',
        style: TextStyle(fontSize: 16.sp),
      ),
    );
  }
}

class _BookingChatThreadCard extends StatelessWidget {
  const _BookingChatThreadCard({
    required this.threadId,
    required this.data,
    required this.currentUserId,
    required this.isProviderView,
  });

  final String threadId;
  final Map<String, dynamic> data;
  final String currentUserId;
  final bool isProviderView;

  @override
  Widget build(BuildContext context) {
    final unreadCount = bookingChatUnreadCountFrom(data, currentUserId);
    final counterpartName = bookingChatCounterpartNameFrom(data, currentUserId);
    final counterpartLabel = bookingChatCounterpartLabelFrom(
      data,
      currentUserId,
    );
    final preview = bookingChatLastMessagePreviewFrom(data);
    final eventName = data['eventName']?.toString().trim().isNotEmpty == true
        ? data['eventName'].toString().trim()
        : 'Booking Chat';
    final packageName =
        data['selectedPackage']?.toString().trim() ?? 'Custom Package';
    final status = data['bookingStatus']?.toString() ?? 'pending';
    final activityDate = bookingChatSortDateFrom(data);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingChatThreadPage(
                bookingId: threadId,
                initialThreadData: data,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(18.r),
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
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          '$counterpartLabel • $counterpartName',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _ThreadStatusBadge(
                        status: status,
                        userFacing: !isProviderView,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _formatDateTime(activityDate),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16.sp,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        packageName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.4,
                        color: unreadCount > 0
                            ? AppColors.textDark
                            : AppColors.textGrey,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value);

    if (difference.inDays >= 7) {
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
      return '${months[value.month - 1]} ${value.day}';
    }

    if (difference.inDays >= 1) return '${difference.inDays}d ago';
    if (difference.inHours >= 1) return '${difference.inHours}h ago';
    if (difference.inMinutes >= 1) return '${difference.inMinutes}m ago';
    return 'Now';
  }
}

class _ThreadStatusBadge extends StatelessWidget {
  const _ThreadStatusBadge({required this.status, this.userFacing = false});

  final String status;
  final bool userFacing;

  @override
  Widget build(BuildContext context) {
    final normalized = BookingStatuses.normalize(status);
    final color = switch (normalized) {
      BookingStatuses.accepted => AppColors.primaryGreen,
      BookingStatuses.rejected => AppColors.error,
      BookingStatuses.completed => AppColors.primaryBlue,
      _ => Colors.orange,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        (userFacing && normalized == BookingStatuses.accepted
            ? 'Booked'
            : BookingStatuses.label(normalized))
            .toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import 'package:intl/intl.dart';

class ServiceProviderNotificationsPage extends StatelessWidget {
  final String providerId;

  const ServiceProviderNotificationsPage({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('service_providers')
                        .doc(providerId)
                        .collection('notifications')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(20.r),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildNotificationCard(doc.id, data);
                        },
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white, size: 24.sp),
            onPressed: () => _markAllAsRead(),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String id, Map<String, dynamic> data) {
    final bool isRead = data['isRead'] ?? false;
    final timestamp =
        (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final String timeAgo = _formatTimestamp(timestamp);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isRead
            ? Colors.white
            : AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: isRead
            ? null
            : Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: _getIconColor(data['type']).withValues(alpha: 0.1),
          child: Icon(
            _getIcon(data['type']),
            color: _getIconColor(data['type']),
            size: 24.sp,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                data['title'] ?? 'Notification',
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              data['message'] ?? '',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              timeAgo,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12.sp),
            ),
          ],
        ),
        onTap: () => _markAsRead(id),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'booking':
        return Icons.event_available;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'review':
        return Icons.rate_review_outlined;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'message':
        return Colors.green;
      case 'review':
        return Colors.orange;
      case 'payment':
        return Colors.purple;
      default:
        return AppColors.primaryGreen;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(timestamp);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'No new notifications at the moment.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(String id) async {
    await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(providerId)
        .collection('notifications')
        .doc(id)
        .update({'isRead': true});
  }

  Future<void> _markAllAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshots = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(providerId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

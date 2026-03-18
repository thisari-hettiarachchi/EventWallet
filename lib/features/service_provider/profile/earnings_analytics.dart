import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../services/booking_service.dart';

class EarningsAnalyticsPage extends StatelessWidget {
  const EarningsAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(35.r),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('providerId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      final bookings = snapshot.data!.docs;
                      return _buildContent(bookings);
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
                  'Earnings & Analytics',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Track revenue, bookings, and recent performance.',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            'No booking data yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your earnings will appear here once you complete bookings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<QueryDocumentSnapshot> docs) {
    double totalRevenue = 0;
    int completedCount = 0;
    int pendingCount = 0;

    final List<Map<String, dynamic>> completedBookings = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = BookingStatuses.normalize(data['status']);
      final amount = bookingAmountFrom(data['amount']);

      if (status == BookingStatuses.completed) {
        completedCount++;
        totalRevenue += amount;
        completedBookings.add(data);
      } else if (status == BookingStatuses.pending ||
          status == BookingStatuses.accepted) {
        pendingCount++;
      }
    }

    // Sort completed bookings by date
    completedBookings.sort((a, b) {
      final dateA = bookingEventDateFromMap(a) ?? DateTime(2000);
      final dateB = bookingEventDateFromMap(b) ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    final avgBookingValue = completedCount > 0
        ? totalRevenue / completedCount
        : 0.0;

    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        _buildRevenueCard(totalRevenue),
        SizedBox(height: 24.h),
        Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 16.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.5,
          children: [
            _buildStatBox(
              'Total Bookings',
              docs.length.toString(),
              Colors.blue,
            ),
            _buildStatBox(
              'Completed',
              completedCount.toString(),
              AppColors.primaryGreen,
            ),
            _buildStatBox(
              'Avg. Value',
              '\$${avgBookingValue.toStringAsFixed(0)}',
              Colors.orange,
            ),
            _buildStatBox('Pending', pendingCount.toString(), Colors.purple),
          ],
        ),
        SizedBox(height: 24.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Earnings',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            if (completedBookings.length > 5)
              TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        SizedBox(height: 12.h),
        if (completedBookings.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                'No completed bookings yet.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp),
              ),
            ),
          )
        else
          ...completedBookings
              .take(5)
              .map((booking) => _buildEarningItem(booking)),
      ],
    );
  }

  Widget _buildRevenueCard(double total) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Revenue',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 16.sp),
                SizedBox(width: 4.w),
                Text(
                  'Keep growing!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningItem(Map<String, dynamic> booking) {
    final clientName = bookingClientNameFrom(booking);
    final amount = bookingAmountFrom(booking['amount']);
    final date = bookingEventDateFromMap(booking);
    final dateStr = date != null
        ? DateFormat('MMM dd, yyyy').format(date)
        : 'N/A';
    final service = bookingPackageNameFrom(booking);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.attach_money,
              color: AppColors.primaryGreen,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '$service • $dateStr',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Text(
            '+\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../services/booking_service.dart';

class AllReviewsPage extends StatelessWidget {
  final String providerId;

  const AllReviewsPage({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
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
                        .collection('service_providers')
                        .doc(providerId)
                        .collection('reviews')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final reviews = snapshot.data?.docs ?? [];

                      if (reviews.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 64.sp,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No reviews yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final data =
                              reviews[index].data() as Map<String, dynamic>;
                          return _buildReviewCard(data);
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
                  'All Reviews',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'See what clients say about your services.',
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

  Widget _buildReviewCard(Map<String, dynamic> data) {
    final rating = (data['rating'] ?? 0.0).toDouble();
    final userName = data['userName'] ?? 'Anonymous';
    final comment = data['comment'] ?? '';
    final createdAt = bookingDateFrom(data['createdAt']);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              if (createdAt != null)
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 18.sp,
              );
            }),
          ),
          if (comment.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              comment,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../services/review_service.dart';

class AllProviderReviewsPage extends StatelessWidget {
  final String providerId;
  final String providerName;

  const AllProviderReviewsPage({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Reviews for $providerName',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ReviewService().getProviderReviews(providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          final reviews = snapshot.data?.docs ?? [];
          if (reviews.isEmpty) {
            return Center(
              child: Text(
                'No reviews yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16.sp),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(20.r),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index].data() as Map<String, dynamic>;
              return _buildReviewTile(review);
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> review) {
    final userName = review['userName'] ?? 'Anonymous';
    final rating = (review['rating'] ?? 0.0).toDouble();
    final comment = review['comment'] ?? '';
    final createdAt = (review['createdAt'] as Timestamp?)?.toDate();

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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
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
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade800, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

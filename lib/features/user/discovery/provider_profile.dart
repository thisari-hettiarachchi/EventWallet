import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';

class ProviderProfilePage extends StatelessWidget {
  final String providerId;
  final Map<String, dynamic> providerData;

  const ProviderProfilePage({
    super.key,
    required this.providerId,
    required this.providerData,
  });

  @override
  Widget build(BuildContext context) {
    final name = providerData['businessName'] ?? providerData['name'] ?? 'Unknown Provider';
    final type = providerData['providerType'] ?? providerData['category'] ?? 'Service';
    final rating = (providerData['rating'] ?? 0.0).toDouble();
    final price = (providerData['price'] ?? 0.0).toDouble();
    final imageUrl = providerData['imageUrl'] ?? '';
    final availability = providerData['availability'] ?? 'Available';
    final description = providerData['description'] ?? 'No description provided.';
    final location = providerData['location'] ?? 'Location not specified';
    final phone = providerData['phone'] ?? 'Not provided';
    final email = providerData['email'] ?? 'Not provided';
    
    // Social Links
    final website = providerData['website'] ?? '';
    final facebook = providerData['facebook'] ?? '';
    final instagram = providerData['instagram'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, imageUrl, name),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(name, type, rating, price),
                  SizedBox(height: 25.h),
                  _buildQuickStats(availability, location),
                  SizedBox(height: 30.h),
                  
                  if (website.isNotEmpty || facebook.isNotEmpty || instagram.isNotEmpty) ...[
                    Text(
                      'Social Media & Links',
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    SizedBox(height: 15.h),
                    _buildSocialLinks(website, facebook, instagram),
                    SizedBox(height: 30.h),
                  ],

                  Text(
                    'About',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700, height: 1.5),
                  ),
                  SizedBox(height: 30.h),
                  Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 15.h),
                  _buildContactTile(Icons.phone, phone, 'tel:$phone'),
                  _buildContactTile(Icons.email, email, 'mailto:$email'),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(context, name),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String imageUrl, String name) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      leading: Padding(
        padding: EdgeInsets.all(8.r),
        child: CircleAvatar(
          backgroundColor: Colors.black26,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(gradient: AppColors.headerGradient),
                  child: Icon(Icons.broken_image, size: 100.sp, color: Colors.white54),
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: Icon(Icons.business, size: 100.sp, color: Colors.white54),
              ),
      ),
    );
  }

  Widget _buildHeaderInfo(String name, String type, double rating, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(fontSize: 14.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.w700, letterSpacing: 1.w),
                  ),
                ],
              ),
            ),
            if (price > 0)
              Text(
                '\$${price.toInt()}',
                style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 24.sp),
            SizedBox(width: 4.w),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : 'New',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10.w),
            Text('(24 Reviews)', style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(String availability, String location) {
    return Row(
      children: [
        _statItem(Icons.calendar_today_rounded, 'Availability', availability),
        SizedBox(width: 15.w),
        _statItem(Icons.location_on_rounded, 'Location', location),
      ],
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(15.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10.r, offset: Offset(0, 4.h)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 20.sp),
            SizedBox(height: 8.h),
            Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
            SizedBox(height: 2.h),
            Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks(String website, String facebook, String instagram) {
    return Row(
      children: [
        if (website.isNotEmpty)
          _socialIcon(Icons.language, website, Colors.blue),
        if (facebook.isNotEmpty)
          _socialIcon(Icons.facebook, facebook, const Color(0xFF1877F2)),
        if (instagram.isNotEmpty)
          _socialIcon(Icons.camera_alt, instagram, const Color(0xFFE4405F)),
      ],
    );
  }

  Widget _socialIcon(IconData icon, String url, Color color) {
    return Padding(
      padding: EdgeInsets.only(right: 15.w),
      child: InkWell(
        onTap: () async {
          String finalUrl = url;
          if (!url.startsWith('http')) {
            finalUrl = 'https://$url';
          }
          final Uri uri = Uri.parse(finalUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String value, String url) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () async {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 20.sp),
            ),
            SizedBox(width: 15.w),
            Text(value, style: TextStyle(fontSize: 16.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, String providerName) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20.r, offset: Offset(0, -5.h)),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => _handleBooking(context, providerName),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          child: Text('Book Now', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _handleBooking(BuildContext context, String providerName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book services')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Booking', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text('Do you want to request a booking from $providerName?', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(fontSize: 14.sp))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('bookings').add({
          'userId': user.uid,
          'providerId': providerId,
          'providerName': providerName,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'providerData': providerData,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'title': 'Booking Requested',
          'message': 'Your booking request for $providerName has been sent.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'service',
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request sent successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/gradient_elevated_button.dart';
import '../../../services/booking_service.dart';
import '../../../services/chat_service.dart';
import '../../chat/booking_chat_thread_page.dart';
import 'event_selection_bottom_sheet.dart';

class ProviderProfilePage extends StatelessWidget {
  final String providerId;
  final String category;
  final bool isEventSaving;
  final String? eventId;

  const ProviderProfilePage({
    super.key,
    required this.providerId,
    required this.category,
    this.isEventSaving = false,
    this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Provider not found')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final String name = data['businessName'] ?? 'Service Provider';
        final String imageUrl = data['imageUrl'] ?? '';
        final String description =
            data['description'] ?? 'No description available.';
        final double rating = (data['rating'] ?? 0.0).toDouble();
        final int reviewCount = (data['reviewCount'] ?? 0).toInt();
        final String location = data['location'] ?? 'Location not specified';
        final String phone = data['phone'] ?? '';
        final String email = data['email'] ?? '';
        final Map<String, String> socialLinks = _extractSocialLinks(data);
        final String displayCategory = _resolveProviderCategory(
          data,
          fallback: category,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context, imageUrl, name),
                Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      Text(
                        displayCategory.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF1E5BB1),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 24.sp),
                          SizedBox(width: 8.w),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '($reviewCount Reviews)',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              Icons.calendar_today,
                              'Availability',
                              'Available',
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Expanded(
                            child: _buildInfoCard(
                              Icons.location_on,
                              'Location',
                              location,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),
                      _buildSectionTitle('Social Media & Links'),
                      SizedBox(height: 15.h),
                      _buildSocialMediaSection(socialLinks),
                      SizedBox(height: 30.h),
                      _buildSectionTitle('About'),
                      SizedBox(height: 12.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF4A4D54),
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      _buildSectionTitle('Packages'),
                      SizedBox(height: 15.h),
                      _buildPackagesList(displayCategory, data),
                      SizedBox(height: 30.h),
                      _buildSectionTitle('Contact Information'),
                      SizedBox(height: 15.h),
                      _buildContactItem(Icons.phone_outlined, phone, 'tel:$phone'),
                      SizedBox(height: 12.h),
                      _buildContactItem(Icons.email_outlined, email, 'mailto:$email'),
                      SizedBox(height: 30.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Reviews'),
                          TextButton(
                            onPressed: () => _showAddReviewDialog(context),
                            child: Text(
                              'Add Review',
                              style: TextStyle(
                                color: const Color(0xFF008069),
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15.h),
                      _buildReviewsSection(),
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomAction(
            context,
            name,
            isEventSaving ? 'Add to Event' : 'Book Now',
            data,
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, String imageUrl, String name) {
    return Stack(
      children: [
        Container(
          height: 220.h,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF008069),
                Color(0xFF1E5BB1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.business_outlined,
                      size: 80.sp,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.business_outlined,
                    size: 80.sp,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Container(
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
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF008069), size: 22.sp),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1C1E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF1A1C1E),
      ),
    );
  }

  Map<String, String> _extractSocialLinks(Map<String, dynamic> data) {
    final socialLinks = <String, String>{};

    // Extract from dedicated social fields
    final platforms = {
      'facebook': data['facebook'] ?? '',
      'instagram': data['instagram'] ?? '',
      'twitter': data['twitter'] ?? '',
      'linkedin': data['linkedin'] ?? '',
      'youtube': data['youtube'] ?? '',
      'website': data['website'] ?? '',
      'tiktok': data['tiktok'] ?? '',
      'whatsapp': data['whatsapp'] ?? '',
    };

    // Add only non-empty links
    platforms.forEach((platform, url) {
      if (url.toString().trim().isNotEmpty) {
        socialLinks[platform] = url.toString().trim();
      }
    });

    // Also check for a socialLinks map if it exists
    if (data['socialLinks'] is Map) {
      final socialLinksMap = data['socialLinks'] as Map<String, dynamic>;
      socialLinksMap.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          socialLinks[key.toString().toLowerCase()] = value.toString().trim();
        }
      });
    }

    return socialLinks;
  }

  Widget _buildSocialMediaSection(Map<String, String> socialLinks) {
    if (socialLinks.isEmpty) {
      return Container(
        padding: EdgeInsets.all(15.r),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Center(
          child: Text(
            'No social media links available',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: socialLinks.entries.map((entry) {
        return _buildSocialIcon(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildSocialIcon(String platform, String url) {
    final IconData icon = _getSocialIconForPlatform(platform);
    final Color color = _getColorForPlatform(platform);

    return GestureDetector(
      onTap: () async {
        if (url.isNotEmpty) {
          try {
            final uri = Uri.parse(_formatUrl(url, platform));
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {
            // Silently fail if URL is invalid
          }
        }
      },
      child: Tooltip(
        message: platform[0].toUpperCase() + platform.substring(1),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
      ),
    );
  }

  IconData _getSocialIconForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'twitter':
      case 'x':
        return Icons.share;
      case 'linkedin':
        return Icons.business;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'tiktok':
        return Icons.music_note;
      case 'whatsapp':
        return Icons.chat_bubble_outline;
      case 'website':
      default:
        return Icons.language;
    }
  }

  Color _getColorForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'twitter':
      case 'x':
        return const Color(0xFF000000);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'tiktok':
        return const Color(0xFF000000);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'website':
      default:
        return const Color(0xFF1E5BB1);
    }
  }

  String _formatUrl(String url, String platform) {
    String formattedUrl = url.trim();

    // If URL already has a protocol, return as is
    if (formattedUrl.startsWith('http://') ||
        formattedUrl.startsWith('https://')) {
      return formattedUrl;
    }

    // Format based on platform
    switch (platform.toLowerCase()) {
      case 'facebook':
        if (!formattedUrl.startsWith('facebook.com') &&
            !formattedUrl.startsWith('www.')) {
          return 'https://facebook.com/$formattedUrl';
        }
        return 'https://www.${formattedUrl.replaceFirst(RegExp(r'^(https?://)?(www\.)?'), '')}';
      case 'instagram':
        if (!formattedUrl.startsWith('instagram.com') &&
            !formattedUrl.startsWith('www.')) {
          return 'https://instagram.com/$formattedUrl';
        }
        return 'https://www.${formattedUrl.replaceFirst(RegExp(r'^(https?://)?(www\.)?'), '')}';
      case 'twitter':
      case 'x':
        if (!formattedUrl.startsWith('twitter.com') &&
            !formattedUrl.startsWith('x.com') &&
            !formattedUrl.startsWith('www.')) {
          return 'https://twitter.com/$formattedUrl';
        }
        return 'https://www.${formattedUrl.replaceFirst(RegExp(r'^(https?://)?(www\.)?'), '')}';
      case 'linkedin':
        if (!formattedUrl.startsWith('linkedin.com') &&
            !formattedUrl.startsWith('www.')) {
          return 'https://linkedin.com/in/$formattedUrl';
        }
        return 'https://www.${formattedUrl.replaceFirst(RegExp(r'^(https?://)?(www\.)?'), '')}';
      case 'youtube':
        if (!formattedUrl.startsWith('youtube.com') &&
            !formattedUrl.startsWith('youtu.be') &&
            !formattedUrl.startsWith('www.')) {
          return 'https://youtube.com/@$formattedUrl';
        }
        return 'https://www.${formattedUrl.replaceFirst(RegExp(r'^(https?://)?(www\.)?'), '')}';
      case 'tiktok':
        if (!formattedUrl.startsWith('tiktok.com') &&
            !formattedUrl.startsWith('www.')) {
          return 'https://tiktok.com/@$formattedUrl';
        }
        return 'https://www.${formattedUrl.replaceFirst(RegExp(r'^(https?://)?(www\.)?'), '')}';
      case 'whatsapp':
        // Remove special characters from phone number
        final phoneNumber = formattedUrl.replaceAll(RegExp(r'[^0-9+]'), '');
        return 'https://wa.me/$phoneNumber';
      case 'website':
      default:
        return 'https://$formattedUrl';
    }
  }

  Widget _buildPackagesList(
      String displayCategory,
      Map<String, dynamic> providerData,
      ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .collection('services')
          .snapshots(),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> packages = [];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (var doc in snapshot.data!.docs) {
            packages.add(doc.data() as Map<String, dynamic>);
          }
        } else {
          final rawServices = providerData['services'];
          if (rawServices is List) {
            for (var item in rawServices) {
              if (item is Map) packages.add(Map<String, dynamic>.from(item));
            }
          }
        }

        if (packages.isEmpty) {
          packages.add({
            'name': '$displayCategory Package',
            'price': providerData['price'] ?? 0.0,
            'description': 'Standard package details available on booking',
          });
        }

        return Column(
          children: packages.map((pkg) {
            final double price = (pkg['price'] ?? pkg['amount'] ?? 0.0).toDouble();
            return Container(
              margin: EdgeInsets.only(bottom: 15.h),
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008069).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        color: const Color(0xFF008069), size: 24.sp),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                pkg['name'] ?? 'Package',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A1C1E),
                                ),
                              ),
                            ),
                            Text(
                              'Rs. ${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF008069),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          pkg['description'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildContactItem(IconData icon, String value, String url) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: const Color(0xFF008069).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF008069), size: 20.sp),
          SizedBox(width: 15.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No reviews yet',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final reviewerName = data['userName'] ?? 'Anonymous';
            final comment = data['comment'] ?? '';
            final reviewRating = (data['rating'] ?? 0.0).toDouble();

            return Container(
              margin: EdgeInsets.only(bottom: 15.h),
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
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
                        reviewerName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16.sp),
                          SizedBox(width: 4.w),
                          Text(
                            reviewRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      comment,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF4A4D54),
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add a review')),
      );
      return;
    }

    double selectedRating = 5.0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32.sp,
                    ),
                    onPressed: () => setState(() => selectedRating = index + 1.0),
                  );
                }),
              ),
              SizedBox(height: 15.h),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            GradientElevatedButton(
              onPressed: () async {
                final reviewData = {
                  'userId': user.uid,
                  'userName': user.displayName ?? 'Anonymous',
                  'rating': selectedRating,
                  'comment': commentController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                };

                await FirebaseFirestore.instance
                    .collection('service_providers')
                    .doc(providerId)
                    .collection('reviews')
                    .add(reviewData);

                // Update provider average rating (simplified)
                final reviewsSnapshot = await FirebaseFirestore.instance
                    .collection('service_providers')
                    .doc(providerId)
                    .collection('reviews')
                    .get();

                double totalRating = 0;
                for (var doc in reviewsSnapshot.docs) {
                  totalRating += (doc.data()['rating'] ?? 0.0).toDouble();
                }
                final avgRating = totalRating / reviewsSnapshot.docs.length;

                await FirebaseFirestore.instance
                    .collection('service_providers')
                    .doc(providerId)
                    .update({
                  'rating': avgRating,
                  'reviewCount': reviewsSnapshot.docs.length,
                });

                if (context.mounted) Navigator.pop(context);
              },
              borderRadius: 12.r,
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(
      BuildContext context,
      String providerName,
      String buttonText,
      Map<String, dynamic> providerData,
      ) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _handleMessage(context),
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F3F1),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: const Color(0xFF008069),
                size: 24.sp,
              ),
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: GradientElevatedButton(
              onPressed: () => _handleBooking(context, providerName, providerData),
              padding: EdgeInsets.symmetric(vertical: 18.h),
              borderRadius: 12.r,
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMessage(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messageTarget = await _resolveMessageTargetForProvider(
      userId: user.uid,
      providerId: providerId,
    );

    if (!context.mounted) return;

    if (messageTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Send a booking request first to start messaging.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final bookingId = messageTarget.bookingId;
    final bookingData = messageTarget.initialThreadData;

    try {
      await ChatService().ensureThreadExistsForBooking(
        bookingId: bookingId,
        bookingData: bookingData,
      );
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingChatThreadPage(
          bookingId: bookingId,
          initialThreadData: bookingData,
        ),
      ),
    );
  }

  Future<_MessageTarget?> _resolveMessageTargetForProvider({
    required String userId,
    required String providerId,
  }) async {
    final threadSnapshot = await FirebaseFirestore.instance
        .collection(bookingChatsCollection)
        .where('userId', isEqualTo: userId)
        .where('providerId', isEqualTo: providerId)
        .where('hasMessages', isEqualTo: true)
        .get();

    final activeThreads = threadSnapshot.docs.toList()
      ..sort(
        (a, b) => bookingChatSortDateFrom(
          b.data(),
        ).compareTo(bookingChatSortDateFrom(a.data())),
      );

    if (activeThreads.isNotEmpty) {
      final thread = activeThreads.first;
      return _MessageTarget(
        bookingId: thread.id,
        initialThreadData: thread.data(),
      );
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    final matching = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['providerId']?.toString() == providerId;
    }).toList();

    if (matching.isEmpty) return null;

    matching.sort((a, b) {
      final aDate = _bookingActivityDate(a.data());
      final bDate = _bookingActivityDate(b.data());
      return bDate.compareTo(aDate);
    });

    final booking = matching.first;
    return _MessageTarget(
      bookingId: booking.id,
      initialThreadData: booking.data(),
    );
  }

  DateTime _bookingActivityDate(Map<String, dynamic> data) {
    return bookingDateFrom(data['updatedAt']) ??
        bookingDateFrom(data['createdAt']) ??
        bookingEventDateFromMap(data) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _handleBooking(
      BuildContext context,
      String providerName,
      Map<String, dynamic> providerData,
      ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send a booking request')),
      );
      return;
    }

    final eventOptions = await _loadEventOptions(user.uid);
    if (!context.mounted) return;

    if (eventOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create an event first to send a request'),
        ),
      );
      return;
    }

    final effectiveCategory = _resolveProviderCategory(
      providerData,
      fallback: category,
    );
    final packageOptions = await _buildPackageOptions(
      providerName,
      providerData,
      effectiveCategory,
    );
    if (!context.mounted) return;

    final selection = await showModalBottomSheet<BookingSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventSelectionBottomSheet(
        providerName: providerName,
        clientName: user.displayName ?? user.email ?? 'Client',
        eventOptions: eventOptions,
        packageOptions: packageOptions,
        isFixedEvent: isEventSaving && eventId != null,
      ),
    );

    if (!context.mounted || selection == null) return;

    final selectedEventId =
    (isEventSaving && eventId != null) ? eventId! : selection.event.id;

    final payload = buildBookingPayload(
      userId: user.uid,
      providerId: providerId,
      providerName: providerName,
      clientName: user.displayName ?? user.email?.split('@').first ?? 'Client',
      clientEmail: user.email,
      eventId: selectedEventId,
      eventName: selection.event.name,
      eventType: selection.event.type,
      eventDate: selection.event.date,
      location: selection.event.location,
      selectedPackage: selection.package.name,
      amount: selection.package.amount,
      status: BookingStatuses.pending,
      providerType: effectiveCategory,
      providerLocation:
      providerData['location']?.toString() ?? selection.event.location,
      providerData: {
        'businessName': providerData['businessName'] ?? providerName,
        'imageUrl': providerData['imageUrl'] ?? '',
        'category': effectiveCategory,
      },
    );

    try {
      await FirebaseFirestore.instance.collection('bookings').add(payload);
      
      // Send notification to provider
      await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .collection('notifications')
          .add({
            'title': 'New Booking Request',
            'message':
                'You received a new booking request from ${user.displayName ?? user.email?.split('@').first ?? 'a client'} for ${selection.event.name}',
            'type': 'booking',
            'bookingId': payload['id'],
            'userId': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send request. Please try again'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<List<BookingEventOption>> _loadEventOptions(String userId) async {
    if (isEventSaving && eventId != null) {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      if (!eventDoc.exists) return const [];
      return [_toBookingEventOption(eventDoc.id, eventDoc.data() ?? {})];
    }

    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('userId', isEqualTo: userId)
        .get();

    final options = eventsSnapshot.docs
        .map((doc) => _toBookingEventOption(doc.id, doc.data()))
        .toList();

    options.sort((a, b) => a.date.compareTo(b.date));
    return options;
  }

  BookingEventOption _toBookingEventOption(
      String id,
      Map<String, dynamic> data,
      ) {
    final rawDate = data['date'] ?? data['eventDate'] ?? data['createdAt'];
    final eventDate = bookingDateFrom(rawDate) ?? DateTime.now();

    return BookingEventOption(
      id: id,
      name: (data['eventName'] ?? data['name'] ?? 'Untitled Event').toString(),
      type: (data['category'] ?? data['eventType'] ?? 'Event').toString(),
      date: eventDate,
      location: (data['venue'] ?? data['location'] ?? 'Location not specified')
          .toString(),
    );
  }

  Future<List<BookingPackageOption>> _buildPackageOptions(
      String providerName,
      Map<String, dynamic> providerData,
      String displayCategory,
      ) async {
    final options = <BookingPackageOption>[];

    final servicesSnapshot = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(providerId)
        .collection('services')
        .get();

    if (servicesSnapshot.docs.isNotEmpty) {
      for (var doc in servicesSnapshot.docs) {
        final data = doc.data();
        options.add(
          BookingPackageOption(
            id: doc.id,
            name: (data['name'] ?? 'Package').toString(),
            amount: bookingAmountFrom(data['price'] ?? data['amount']),
            description: (data['description'] ?? '').toString(),
          ),
        );
      }
    } else {
      final rawServices = providerData['services'];
      if (rawServices is List) {
        for (var i = 0; i < rawServices.length; i++) {
          final item = rawServices[i];
          if (item is! Map) continue;
          options.add(
            BookingPackageOption(
              id: 'pkg_$i',
              name: (item['name'] ?? item['title'] ?? 'Package ${i + 1}')
                  .toString(),
              amount: bookingAmountFrom(item['price'] ?? item['amount']),
              description: (item['description'] ?? '').toString(),
            ),
          );
        }
      }
    }

    if (options.isEmpty) {
      options.add(
        BookingPackageOption(
          id: 'default',
          name: '$displayCategory Package',
          amount: bookingAmountFrom(providerData['price']),
          description: 'Custom package details available on booking',
        ),
      );
    }

    return options;
  }

  String _resolveProviderCategory(
      Map<String, dynamic> data, {
        required String fallback,
      }) {
    final raw = (data['category'] ?? data['providerType'] ?? data['type'] ?? '')
        .toString()
        .trim();
    final source = raw.isEmpty ? fallback : raw;

    switch (source.toLowerCase()) {
      case 'photographer':
      case 'photography':
        return 'Photography';
      case 'venue':
        return 'Venue';
      case 'music':
      case 'musician':
        return 'Music';
      case 'catering':
      case 'caterer':
        return 'Catering';
      case 'decoration':
      case 'decor':
        return 'Decoration';
      case 'transport':
        return 'Transport';
      default:
        if (source.isEmpty) return 'Service';
        return source[0].toUpperCase() + source.substring(1);
    }
  }
}

class _MessageTarget {
  const _MessageTarget({
    required this.bookingId,
    required this.initialThreadData,
  });

  final String bookingId;
  final Map<String, dynamic> initialThreadData;
}

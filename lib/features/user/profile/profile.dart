import 'package:eventwallet/features/user/info/help.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/styles.dart';
import '../auth/login.dart';
import '../../../services/auth_service.dart';
import '../bookings/my_booking_requests.dart';
import 'edit_profile.dart';
import '../info/privacy.dart';
import '../info/about.dart';
import '../info/service_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

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

    return FutureBuilder<DocumentSnapshot>(
      future: _getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('User data not found')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final bool isServiceProvider = userData.containsKey('businessName');
        final displayName = isServiceProvider
            ? userData['businessName'] ?? 'Service Provider'
            : userData['name'] ?? 'User';
        final email = userData['email'] ?? 'No email';
        final initials = displayName.isNotEmpty
            ? displayName.trim().split(' ').map((e) => e[0]).take(2).join()
            : 'U';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            decoration: AppDecorations.pageGradientHeader,
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10.r,
                          offset: Offset(0, 5.h),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    displayName,
                    style: AppTextStyles.whiteText(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    email,
                    style: AppTextStyles.whiteText(
                      fontSize: 15,
                    ).copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  SizedBox(height: 24.h),
                  if (!isServiceProvider)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('events')
                          .where('userId', isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, eventSnapshot) {
                        int eventsCount = 0;
                        double totalBudget = 0;
                        double totalSpent = 0;

                        if (eventSnapshot.hasData) {
                          eventsCount = eventSnapshot.data!.docs.length;
                          for (var doc in eventSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            totalBudget += (data['budget'] ?? 0).toDouble();
                            totalSpent += (data['spent'] ?? 0).toDouble();
                          }
                        }

                        return Container(
                          margin: AppSpacing.horizontalPadding,
                          padding: EdgeInsets.all(20.r),
                          decoration: AppDecorations.overlayButton.copyWith(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5.w,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Total Events', '$eventsCount'),
                              Container(
                                width: 1.w,
                                height: 40.h,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              _buildStatItem(
                                'Total Budget',
                                '\$${totalBudget.toStringAsFixed(0)}',
                              ),
                              Container(
                                width: 1.w,
                                height: 40.h,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              _buildStatItem(
                                'Amount Spent',
                                '\$${totalSpent.toStringAsFixed(0)}',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: Container(
                      decoration: AppDecorations.roundedContent(),
                      child: ListView(
                        padding: EdgeInsets.all(20.r),
                        children: [
                          Text(
                            'Account Settings',
                            style: AppTextStyles.sectionTitle,
                          ),
                          SizedBox(height: 16.h),
                          _buildSettingsCard(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            subtitle: 'Update your account info',
                            color: const Color(0xFF1565C0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12.h),
                          _buildSettingsCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'My Booking Requests',
                            subtitle:
                                'Track pending requests, booked services, rejected, and completed bookings',
                            color: AppColors.primaryGreen,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserBookingStatusPage(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12.h),
                          _buildSettingsCard(
                            icon: Icons.lock_outline,
                            title: 'Privacy & Security',
                            subtitle: 'Password and security settings',
                            color: const Color(0xFF00897B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacySecurityPage(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Support',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1F36),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _buildSettingsCard(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            subtitle: 'Get assistance',
                            color: Colors.cyan.shade800,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpSupportPage(),
                                ),
                              );
                            },
                          ),
                          if (!isServiceProvider) ...[
                            SizedBox(height: 16.h),
                            _buildSettingsCard(
                              icon: Icons.person_add_alt_1,
                              title: 'Become a Service Provider',
                              subtitle:
                                  'Offer your services for events and get bookings',
                              color: Colors.cyan.shade800,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ServiceProviderPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                          SizedBox(height: 12.h),
                          _buildSettingsCard(
                            icon: Icons.info_outline,
                            title: 'About',
                            subtitle: 'Version 1.0.0',
                            color: Colors.blueGrey,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AboutPage(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 24.h),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _showLogoutDialog(context);
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Padding(
                                  padding: EdgeInsets.all(16.r),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10.r),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.logout,
                                          color: Colors.red.shade700,
                                          size: 22.sp,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          'Logout',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.red.shade400,
                                        size: 16.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const AppBottomNav(currentIndex: 3),
        );
      },
    );
  }

  Future<DocumentSnapshot> _getUserData(String uid) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (userDoc.exists) return userDoc;

    return await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(uid)
        .get();
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.whiteText(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTextStyles.whiteText(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ).copyWith(color: Colors.white.withValues(alpha: 0.9)),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppDecorations.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: color, size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.bodyLarge),
                      SizedBox(height: 4.h),
                      Text(subtitle, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textGrey,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: Text(
              'Logout',
              style: TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

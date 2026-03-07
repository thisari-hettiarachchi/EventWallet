import 'package:eventwallet/features/user/info/help.dart';
import 'package:eventwallet/features/user/events/manage_event.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../auth/login.dart';
import '../../../services/auth_service.dart';
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
      // If user is not signed in, redirect to login
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Fetch user data from Firestore - Check both 'users' and 'service_providers'
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
          backgroundColor: const Color(0xFFF5F7FA),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00897B), // Teal/Green
                  Color(0xFF1565C0), // Blue
                ],
                stops: [0.0, 0.3], // Color covers top 30% like an app bar
              ),
            ),
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
                          color: Colors.black.withOpacity(0.2),
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
                          color: const Color(0xFF00897B),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  if (!isServiceProvider) Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5.w,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Total Events
                        _buildStatItem(
                          'Total Events',
                          userData['eventsCount'] != null ? userData['eventsCount'].toString() : '0',
                        ),

                        Container(
                          width: 1.w,
                          height: 40.h,
                          color: Colors.white.withOpacity(0.3),
                        ),

                        // Total Budget
                        _buildStatItem(
                          'Total Budget',
                          userData['totalBudget'] != null
                              ? '\$${userData['totalBudget'].toString()}'
                              : '\$0',
                        ),

                        Container(
                          width: 1.w,
                          height: 40.h,
                          color: Colors.white.withOpacity(0.3),
                        ),

                        // Amount Spent
                        _buildStatItem(
                          'Amount Spent',
                          userData['spent'] != null
                              ? '\$${userData['spent'].toString()}'
                              : '\$0',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
                      ),
                      child: ListView(
                        padding: EdgeInsets.all(20.r),
                        children: [
                          Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1F36),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _buildSettingsCard(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            subtitle: 'Update your account info',
                            color: const Color(0xFF1565C0),
                            onTap: () {
                              // Navigate to EditProfilePage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                            },
                          ),
                          if (!isServiceProvider) ...[
                            SizedBox(height: 12.h),
                            _buildSettingsCard(
                              icon: Icons.event_note_outlined,
                              title: 'Manage Events',
                              subtitle: 'View, edit, or delete your events',
                              color: Colors.orange.shade800,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ManageEventsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
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
                                  builder: (context) => const PrivacySecurityPage(),
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
                              subtitle: 'Offer your services for events and get bookings',
                              color: Colors.cyan.shade800,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ServiceProviderPage(),
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
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Icon(Icons.logout,
                                            color: Colors.red.shade700, size: 22.sp),
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
                                      Icon(Icons.arrow_forward_ios,
                                          color: Colors.red.shade400, size: 16.sp),
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
    // Try to get from 'users' collection first
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) return userDoc;

    // If not found, try 'service_providers' collection
    return await FirebaseFirestore.instance.collection('service_providers').doc(uid).get();
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: color, size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1F36),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF4A5568),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.grey.shade400, size: 16.sp),
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
        content: Text('Are you sure you want to logout?', style: TextStyle(fontSize: 14.sp)),
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
            child: Text('Logout', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

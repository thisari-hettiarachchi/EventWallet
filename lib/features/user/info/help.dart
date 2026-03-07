import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/styles.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Help & Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20.sp)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF1565C0)],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: AppDecorations.pageGradientHeader,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.support_agent,
                      size: 50.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'We\'re Here to Help',
                    style: AppTextStyles.whiteText(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Get assistance for your events and queries',
                    style: AppTextStyles.whiteText(fontSize: 14).copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Us',
                    style: AppTextStyles.sectionTitle,
                  ),
                  SizedBox(height: 16.h),
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'support@eventwallet.com',
                    color: AppColors.primaryBlue,
                    onTap: () => _launchEmail('support@eventwallet.com'),
                  ),
                  SizedBox(height: 12.h),
                  _buildContactCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    subtitle: '+94 77 123 4567',
                    color: AppColors.primaryGreen,
                    onTap: () => _launchPhone('+15551234567'),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    'Frequently Asked Questions',
                    style: AppTextStyles.sectionTitle,
                  ),
                  SizedBox(height: 16.h),
                  _buildFAQItem(
                    question: 'How do I create an event?',
                    answer: 'To create an event, go to the Home screen and tap the "+" button. Fill in the event details like name, date, and budget, then tap "Create Event".',
                  ),
                  _buildFAQItem(
                    question: 'How can I track my event budget?',
                    answer: 'Each event has a budget tracker where you can add expenses. The app automatically calculates your spending and shows remaining budget.',
                  ),
                  _buildFAQItem(
                    question: 'Can I edit or delete events?',
                    answer: 'Yes! Go to "Manage Events" from your profile page. You can edit event details or delete events you no longer need.',
                  ),
                  _buildFAQItem(
                    question: 'How do I reset my password?',
                    answer: 'Go to Privacy & Security in your profile settings. Enter your current password and choose a new password to update it.',
                  ),
                  _buildFAQItem(
                    question: 'Is my data secure?',
                    answer: 'Yes, all your data is securely stored using Firebase encryption. We follow industry-standard security practices to protect your information.',
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
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
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: AppColors.textGrey, size: 16.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: AppDecorations.card(),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          leading: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.help_outline, color: AppColors.primaryGreen, size: 20.sp),
          ),
          title: Text(
            question,
            style: AppTextStyles.bodyLarge,
          ),
          children: [
            Text(
              answer,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Event Planner Support',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}

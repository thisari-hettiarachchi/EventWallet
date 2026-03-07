import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../result/result_page.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'User not logged in',
        );
      }

      // 🔐 Force fresh login
      await auth.signInWithEmailAndPassword(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      // 🔄 Reload user session
      await user.reload();
      final refreshedUser = auth.currentUser;

      if (refreshedUser == null) {
        throw FirebaseAuthException(
          code: 'session-error',
          message: 'Session expired',
        );
      }

      // 🔑 Update password
      await refreshedUser.updatePassword(
        _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            isSuccess: true,
            message: 'Your password has been changed successfully.',
            onButtonPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Password change failed';

      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        message = 'New password is too weak';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log in again to change password';
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            isSuccess: false,
            message: message,
            onButtonPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            isSuccess: false,
            message: 'Unexpected error occurred',
            onButtonPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00897B),
              Color(0xFF1565C0),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 100.h), // Space for AppBar
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_outline,
                                size: 50.sp,
                                color: const Color(0xFF00897B),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Keep Your Account Safe',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1F36),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Manage your password and security settings',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF4A5568),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Change Password',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1F36),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              _buildPasswordField(
                                controller: _currentPasswordController,
                                label: 'Current Password',
                                isVisible: _showCurrentPassword,
                                onToggle: () =>
                                    setState(() => _showCurrentPassword = !_showCurrentPassword),
                                validator: (value) =>
                                value!.isEmpty ? 'Enter current password' : null,
                              ),
                              SizedBox(height: 16.h),
                              _buildPasswordField(
                                controller: _newPasswordController,
                                label: 'New Password',
                                isVisible: _showNewPassword,
                                onToggle: () =>
                                    setState(() => _showNewPassword = !_showNewPassword),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter new password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16.h),
                              _buildPasswordField(
                                controller: _confirmPasswordController,
                                label: 'Confirm New Password',
                                isVisible: _showConfirmPassword,
                                onToggle: () =>
                                    setState(() => _showConfirmPassword = !_showConfirmPassword),
                                validator: (value) =>
                                value != _newPasswordController.text
                                    ? 'Passwords do not match'
                                    : null,
                              ),
                              SizedBox(height: 32.h),
                              SizedBox(
                                width: double.infinity,
                                height: 56.h,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00897B), Color(0xFF1565C0)],
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _changePassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                      'Change Password',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      style: TextStyle(color: const Color(0xFF1A1F36), fontSize: 15.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF4A5568), fontSize: 14.sp),
        prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFF00897B), size: 24.sp),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF4A5568),
            size: 24.sp,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

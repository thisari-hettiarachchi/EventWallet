import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/gradient_elevated_button.dart';
import '../../../services/profile_image_storage_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  final _profileImageStorageService = ProfileImageStorageService();

  String _profileImageUrl = '';
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _profileImageUrl = data['imageUrl'] ?? '';
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  Future<void> _deleteImage() async {
    if (_profileImageUrl.isEmpty && _imageFile == null) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // If there was an old image on Supabase, delete it
        if (_profileImageUrl.isNotEmpty) {
          await _profileImageStorageService.deleteProfileImage(_profileImageUrl);
        }

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'imageUrl': ''});

        setState(() {
          _profileImageUrl = '';
          _imageFile = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image removed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String imageUrl = _profileImageUrl;

        if (_imageFile != null) {
          // Delete old image if it exists before uploading new one
          if (_profileImageUrl.isNotEmpty) {
            await _profileImageStorageService.deleteProfileImage(_profileImageUrl);
          }

          final pickedImage = XFile(_imageFile!.path);
          imageUrl = await _profileImageStorageService.uploadProfileImage(
            uid: user.uid,
            role: 'users',
            image: pickedImage,
          );
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'imageUrl': imageUrl,
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.r),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: 120.w,
                                      height: 120.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppColors.primaryGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryBlue.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 20.r,
                                            offset: Offset(0, 10.h),
                                          ),
                                        ],
                                        image: _imageFile != null
                                            ? DecorationImage(
                                                image: FileImage(_imageFile!),
                                                fit: BoxFit.cover,
                                              )
                                            : (_profileImageUrl.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        _profileImageUrl,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null),
                                      ),
                                      child:
                                          _imageFile == null &&
                                              _profileImageUrl.isEmpty
                                          ? Icon(
                                              Icons.person,
                                              size: 60.sp,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3.w,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 20.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_profileImageUrl.isNotEmpty || _imageFile != null)
                                TextButton.icon(
                                  onPressed: _isLoading ? null : _deleteImage,
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  label: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          enabled: false,
                          hint: 'Email cannot be changed',
                        ),
                        SizedBox(height: 16.h),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 40.h),
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: GradientElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            borderRadius: 12.r,
                            child: _isLoading
                                ? SizedBox(
                                    height: 24.w,
                                    width: 24.w,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        ],
                      ),
                    ),
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
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Update your personal details and profile photo.',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 15.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14.sp),
        prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 24.sp),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.error, width: 2.w),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

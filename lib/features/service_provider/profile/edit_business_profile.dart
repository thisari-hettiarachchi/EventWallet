import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';

class EditBusinessProfilePage extends StatefulWidget {
  const EditBusinessProfilePage({super.key});

  @override
  State<EditBusinessProfilePage> createState() => _EditBusinessProfilePageState();
}

class _EditBusinessProfilePageState extends State<EditBusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  
  String _profileImageUrl = '';
  File? _imageFile;
  final _picker = ImagePicker();
  
  String _selectedProviderType = 'Photography';
  bool _isLoading = false;

  final List<String> _providerTypes = [
    'Photography',
    'Catering',
    'Venue',
    'Music',
    'Decoration',
    'Transport',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _businessNameController.text = data['businessName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _locationController.text = data['location'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _facebookController.text = data['facebook'] ?? '';
          _instagramController.text = data['instagram'] ?? '';
          _profileImageUrl = data['imageUrl'] ?? '';
          
          String type = data['providerType'] ?? 'Photography';
          if (type.isNotEmpty) {
            type = type[0].toUpperCase() + type.substring(1);
          }
          if (_providerTypes.contains(type)) {
            _selectedProviderType = type;
          } else {
            _selectedProviderType = 'Other';
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return _profileImageUrl;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('provider_profiles')
          .child('$uid.jpg');
      
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl = await _uploadImage(user.uid);
        
        await FirebaseFirestore.instance.collection('service_providers').doc(user.uid).update({
          'businessName': _businessNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'description': _descriptionController.text.trim(),
          'website': _websiteController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'imageUrl': imageUrl ?? _profileImageUrl,
          'providerType': _selectedProviderType.toLowerCase(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Business profile updated successfully!'),
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
      appBar: AppBar(
        title: Text('Edit Business Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20.sp)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryBlue,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.r),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 120.w,
                                  height: 120.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[200],
                                    border: Border.all(color: Colors.white, width: 4.w),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10.r,
                                        offset: Offset(0, 5.h),
                                      ),
                                    ],
                                    image: _imageFile != null
                                        ? DecorationImage(
                                            image: FileImage(_imageFile!),
                                            fit: BoxFit.cover,
                                          )
                                        : (_profileImageUrl.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(_profileImageUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null),
                                  ),
                                  child: _imageFile == null && _profileImageUrl.isEmpty
                                      ? Icon(
                                          Icons.business,
                                          size: 60.sp,
                                          color: AppColors.primaryGreen,
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
                                      border: Border.all(color: Colors.white, width: 3.w),
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
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          'Business Information',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildTextField(
                          controller: _businessNameController,
                          label: 'Business Name',
                          icon: Icons.business_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter business name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        _buildDropdownField(
                          label: 'Service Category',
                          icon: Icons.category_outlined,
                          value: _selectedProviderType,
                          items: _providerTypes,
                          onChanged: (value) {
                            setState(() => _selectedProviderType = value!);
                          },
                        ),
                        SizedBox(height: 16.h),
                        _buildTextField(
                          controller: _locationController,
                          label: 'Location',
                          icon: Icons.location_on_outlined,
                          hint: 'e.g. New York, USA',
                        ),
                        SizedBox(height: 16.h),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Business Description',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          hint: 'Tell customers about your services...',
                        ),
                        SizedBox(height: 32.h),
                        Text(
                          'Social Media & Links',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Website',
                          icon: Icons.language_outlined,
                          hint: 'https://www.yourbusiness.com',
                          keyboardType: TextInputType.url,
                        ),
                        SizedBox(height: 16.h),
                        _buildTextField(
                          controller: _facebookController,
                          label: 'Facebook',
                          icon: Icons.facebook_outlined,
                          hint: 'facebook.com/yourpage',
                        ),
                        SizedBox(height: 16.h),
                        _buildTextField(
                          controller: _instagramController,
                          label: 'Instagram',
                          icon: Icons.camera_alt_outlined,
                          hint: '@yourhandle',
                        ),
                        SizedBox(height: 32.h),
                        Text(
                          'Contact Details',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Business Email',
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
                        Container(
                          width: double.infinity,
                          height: 56.h,
                          decoration: BoxDecoration(
                            gradient: AppColors.buttonGradient,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                                blurRadius: 12.r,
                                offset: Offset(0, 6.h),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
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
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen, size: 24.sp),
              items: items.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, style: TextStyle(fontSize: 15.sp)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }
}

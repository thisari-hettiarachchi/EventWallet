import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/provider_bottom_nav.dart';
import '../../../core/constants/colors.dart';

class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryGreen, AppColors.primaryBlue],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 20.h),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildServicesList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.4),
              blurRadius: 16.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddServiceDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(Icons.add, color: Colors.white, size: 26.sp),
          label: Text(
            'Add Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5.w,
            ),
          ),
        ),
      ),
      bottomNavigationBar: const ProviderBottomNav(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Services',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.w,
                ),
              ),
              Text(
                'Manage your offerings',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: Icon(Icons.room_service_outlined, color: Colors.white, size: 24.sp),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    if (userId == null) return Center(child: Text('Please login', style: TextStyle(fontSize: 16.sp)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_providers')
          .doc(userId)
          .collection('services')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 100.h),
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildServiceCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildServiceCard(String id, Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(Icons.room_service, color: AppColors.primaryGreen, size: 28.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['name'] ?? 'Untitled Service',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18.sp,
                                color: AppColors.textDark,
                                letterSpacing: -0.5.w,
                              ),
                            ),
                          ),
                          Text(
                            '\$${data['price'] ?? 0}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20.sp,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        data['description'] ?? 'No description provided',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCardAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: AppColors.primaryBlue,
                  onTap: () => _showEditServiceDialog(id, data),
                ),
                SizedBox(width: 8.w),
                _buildCardAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: Colors.redAccent,
                  onTap: () => _deleteService(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18.sp, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13.sp),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30.r),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_business_outlined, size: 80.sp, color: AppColors.primaryGreen.withOpacity(0.2)),
          ),
          SizedBox(height: 24.h),
          Text(
            'No services yet',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.5.w,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Add your first service to start growing\nyour business on EventWallet',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 15.sp, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildServiceForm(
        title: 'Add New Service',
        buttonLabel: 'Add Service',
        nameController: nameController,
        priceController: priceController,
        descController: descController,
        onSave: () async {
          if (nameController.text.isNotEmpty && userId != null) {
            await FirebaseFirestore.instance
                .collection('service_providers')
                .doc(userId)
                .collection('services')
                .add({
              'name': nameController.text,
              'price': double.tryParse(priceController.text) ?? 0,
              'description': descController.text,
              'createdAt': FieldValue.serverTimestamp(),
            });
            if (mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showEditServiceDialog(String id, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']);
    final priceController = TextEditingController(text: data['price'].toString());
    final descController = TextEditingController(text: data['description']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildServiceForm(
        title: 'Edit Service',
        buttonLabel: 'Update Service',
        nameController: nameController,
        priceController: priceController,
        descController: descController,
        onSave: () async {
          if (nameController.text.isNotEmpty && userId != null) {
            await FirebaseFirestore.instance
                .collection('service_providers')
                .doc(userId)
                .collection('services')
                .doc(id)
                .update({
              'name': nameController.text,
              'price': double.tryParse(priceController.text) ?? 0,
              'description': descController.text,
            });
            if (mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildServiceForm({
    required String title,
    required String buttonLabel,
    required TextEditingController nameController,
    required TextEditingController priceController,
    required TextEditingController descController,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(30.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 50.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 25.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.5.w,
              ),
            ),
            SizedBox(height: 25.h),
            _buildTextField(
              label: 'Service Name',
              hint: 'e.g. Wedding Photography Package',
              controller: nameController,
              icon: Icons.badge_outlined,
            ),
            SizedBox(height: 20.h),
            _buildTextField(
              label: 'Price',
              hint: '0.00',
              controller: priceController,
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.h),
            _buildTextField(
              label: 'Description',
              hint: 'What does this service include?',
              controller: descController,
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
            SizedBox(height: 35.h),
            Container(
              width: double.infinity,
              height: 60.h,
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                ),
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(fontSize: 15.sp),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
              prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 22.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.r),
            ),
          ),
        ),
      ],
    );
  }

  void _deleteService(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Delete Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
        content: Text('Are you sure you want to delete this service? This action cannot be undone.', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
          TextButton(
            onPressed: () async {
              if (userId != null) {
                await FirebaseFirestore.instance
                    .collection('service_providers')
                    .doc(userId)
                    .collection('services')
                    .doc(id)
                    .delete();
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}

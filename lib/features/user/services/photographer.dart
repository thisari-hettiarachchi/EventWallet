import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/gradient_elevated_button.dart';

class PhotographyPage extends StatefulWidget {
  const PhotographyPage({super.key});

  @override
  State<PhotographyPage> createState() => _PhotographyPageState();
}

class _PhotographyPageState extends State<PhotographyPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Wedding',
    'Portrait',
    'Event',
    'Commercial',
  ];

  List<DocumentSnapshot> _photographers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPhotographers();
  }

  void _fetchPhotographers() async {
    setState(() => _isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('photographers')
        .orderBy('rating', descending: true)
        .get();

    setState(() {
      _photographers = snapshot.docs;
      _isLoading = false;
    });
  }

  List<DocumentSnapshot> get _filteredPhotographers {
    if (_selectedFilter == 'All') return _photographers;
    return _photographers.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final specialties = List<String>.from(data['specialties'] ?? []);
      return specialties.contains(_selectedFilter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.r),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Photography',
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_photographers.length} photographers available',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                          onPressed: () => _showSearchDialog(),
                        ),
                      ],
                    ),
                  ),
                  _buildFilterChips(),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPhotographers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(20.r),
                    itemCount: _filteredPhotographers.length,
                    itemBuilder: (context, index) {
                      final doc = _filteredPhotographers[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildPhotographerCard(data, doc.id);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return FilterChip(
            label: Text(
              filter,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _selectedFilter = filter);
            },
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            selectedColor: Colors.white.withValues(alpha: 0.3),
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.w,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotographerCard(Map<String, dynamic> data, String id) {
    final name = data['name'] ?? 'Unknown Photographer';
    final rating = (data['rating'] ?? 0.0).toDouble();
    final reviews = data['reviews'] ?? 0;
    final hourlyRate = (data['hourlyRate'] ?? 0).toDouble();
    final specialties = List<String>.from(data['specialties'] ?? []);
    final imageUrl = data['imageUrl'] ?? '';
    final location = data['location'] ?? 'Location not specified';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            child: Stack(
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 200.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16.sp),
                        SizedBox(width: 4.w),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      'Rs. ${hourlyRate.toStringAsFixed(0)}/hr',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16.sp,
                      color: AppColors.textGrey.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textGrey.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    Text(
                      '$reviews reviews',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textGrey.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: specialties.map((specialty) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewDetails(id, data),
                        icon: Icon(Icons.info_outline, size: 18.sp),
                        label: Text(
                          'Details',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          side: const BorderSide(color: AppColors.primaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GradientElevatedButton(
                        onPressed: () => _bookPhotographer(id, data),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        borderRadius: 12.r,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 18.sp, color: Colors.white),
                            SizedBox(width: 6.w),
                            Text('Book', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.3),
            AppColors.primaryBlue.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Icon(Icons.camera_alt, size: 64.sp, color: Colors.white),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 80.sp,
            color: AppColors.textGrey.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'No photographers found',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.textGrey.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try changing your filter',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textGrey.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Photographers',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          style: TextStyle(fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: 'Enter photographer name...',
            hintStyle: TextStyle(fontSize: 14.sp),
            prefixIcon: Icon(Icons.search, size: 24.sp),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            // Implement search logic
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _viewDetails(String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 0.75.sh,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'Photographer',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      data['description'] ?? 'No description available.',
                      style: TextStyle(fontSize: 15.sp),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Portfolio',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Add portfolio images grid here
                    Text(
                      'Portfolio images coming soon...',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookPhotographer(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Book ${data['name']}',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate: Rs. ${data['hourlyRate']}/hour',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'Select a date and time for your event:',
              style: TextStyle(fontSize: 14.sp),
            ),
            // Add date picker here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          GradientElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking request sent!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            borderRadius: 12.r,
            child: Text(
              'Confirm',
              style: TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

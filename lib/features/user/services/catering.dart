import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/gradient_elevated_button.dart';

class CateringPage extends StatefulWidget {
  const CateringPage({super.key});

  @override
  State<CateringPage> createState() => _CateringPageState();
}

class _CateringPageState extends State<CateringPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Buffet',
    'Plated',
    'BBQ',
    'Desserts',
    'Cocktails',
  ];

  List<DocumentSnapshot> _caterers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCaterers();
  }

  void _fetchCaterers() async {
    setState(() => _isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('caterers')
        .orderBy('rating', descending: true)
        .get();

    setState(() {
      _caterers = snapshot.docs;
      _isLoading = false;
    });
  }

  List<DocumentSnapshot> get _filteredCaterers {
    if (_selectedFilter == 'All') return _caterers;
    return _caterers.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final cuisines = List<String>.from(data['cuisines'] ?? []);
      return cuisines.contains(_selectedFilter);
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
                                'Catering',
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_caterers.length} caterers available',
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
                            Icons.filter_list,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                          onPressed: () => _showFilterOptions(),
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
                : _filteredCaterers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(20.r),
                    itemCount: _filteredCaterers.length,
                    itemBuilder: (context, index) {
                      final doc = _filteredCaterers[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildCatererCard(data, doc.id);
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

  Widget _buildCatererCard(Map<String, dynamic> data, String id) {
    final name = data['name'] ?? 'Unknown Caterer';
    final rating = (data['rating'] ?? 0.0).toDouble();
    final reviews = data['reviews'] ?? 0;
    final pricePerPerson = (data['pricePerPerson'] ?? 0).toDouble();
    final cuisines = List<String>.from(data['cuisines'] ?? []);
    final imageUrl = data['imageUrl'] ?? '';
    final minGuests = data['minGuests'] ?? 0;

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
                        height: 180.h,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. ${pricePerPerson.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        Text(
                          'per person',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16.sp,
                      color: AppColors.textGrey.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Min. $minGuests guests',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textGrey.withValues(alpha: 0.8),
                      ),
                    ),
                    const Spacer(),
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
                  children: cuisines.map((cuisine) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant,
                            size: 14.sp,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            cuisine,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewMenu(id, data),
                        icon: Icon(Icons.menu_book, size: 18.sp),
                        label: Text('Menu', style: TextStyle(fontSize: 14.sp)),
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
                        onPressed: () => _getQuote(id, data),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        borderRadius: 12.r,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.request_quote, size: 18.sp, color: Colors.white),
                            SizedBox(width: 6.w),
                            Text('Quote', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
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
      height: 180.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.3),
            AppColors.primaryBlue.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Icon(Icons.restaurant_menu, size: 64.sp, color: Colors.white),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 80.sp,
            color: AppColors.textGrey.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'No caterers found',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.textGrey.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Options',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Text('Price Range', style: TextStyle(fontSize: 14.sp)),
            // Add price range slider here
            SizedBox(height: 16.h),
            Text('Dietary Options', style: TextStyle(fontSize: 14.sp)),
            // Add dietary checkboxes here
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: GradientElevatedButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.symmetric(vertical: 15.h),
                borderRadius: 12.r,
                child: Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewMenu(String id, Map<String, dynamic> data) {
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
                      '${data['name']} Menu',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildMenuSection('Appetizers', data['appetizers']),
                    SizedBox(height: 16.h),
                    _buildMenuSection('Main Course', data['mainCourse']),
                    SizedBox(height: 16.h),
                    _buildMenuSection('Desserts', data['desserts']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, dynamic items) {
    final menuItems = items is List ? items : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        SizedBox(height: 8.h),
        if (menuItems.isEmpty)
          Text('No items available', style: TextStyle(fontSize: 14.sp))
        else
          ...menuItems.map(
            (item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16.sp,
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(width: 8.w),
                  Text(item.toString(), style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _getQuote(String id, Map<String, dynamic> data) {
    final guestController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Get Quote from ${data['name']}',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Base price: Rs. ${data['pricePerPerson']}/person',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: guestController,
              style: TextStyle(fontSize: 15.sp),
              decoration: InputDecoration(
                labelText: 'Number of guests',
                labelStyle: TextStyle(fontSize: 14.sp),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12.h),
            Text(
              'We\'ll send you a detailed quote based on your requirements.',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textGrey),
            ),
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
                  content: Text('Quote request sent!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            borderRadius: 12.r,
            child: Text(
              'Request Quote',
              style: TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

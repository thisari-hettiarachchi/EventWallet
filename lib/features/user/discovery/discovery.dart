import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/constants/colors.dart';
import 'provider_profile.dart';

class DiscoveryPage extends StatefulWidget {
  final String initialCategory;
  final bool isEventSaving;
  final String? eventId;

  const DiscoveryPage({
    super.key,
    this.initialCategory = 'All',
    this.isEventSaving = false,
    this.eventId,
  });

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _selectedCategory;
  bool _showSavedOnly = false;

  final List<String> _categories = [
    'All',
    'Catering',
    'Venue',
    'Photography',
    'Music',
    'Decoration',
    'Transport',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleSaveProvider(
    String providerId,
    Map<String, dynamic> data,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to save providers')),
        );
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_providers')
          .doc(providerId);

      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await docRef.set({
          ...data,
          'providerId': providerId,
          'savedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
              _buildHeader(),
              _buildSearchAndFilter(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(35.r),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildProvidersList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.isEventSaving
          ? null
          : const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEventSaving
                      ? 'Add Services'
                      : (_showSavedOnly ? 'My Favorites' : 'Discovery'),
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.w,
                  ),
                ),
                Text(
                  widget.isEventSaving
                      ? 'Select services for your event'
                      : 'Quality services for your events',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.isEventSaving)
            GestureDetector(
              onTap: () => setState(() => _showSavedOnly = !_showSavedOnly),
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  _showSavedOnly ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.primaryGreen,
                        size: 24.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.tune,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 45.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 25.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersList() {
    final user = FirebaseAuth.instance.currentUser;
    if (_showSavedOnly) {
      if (user == null) return _buildLoginPrompt();
      return _buildStreamList(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_providers'),
      );
    }

    Query query = FirebaseFirestore.instance.collection('service_providers');
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    return _buildStreamList(query);
  }

  Widget _buildStreamList(Query query) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['businessName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) return _buildEmptyState();

        if (user == null) {
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(20.w, 25.h, 20.w, 100.h),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildProviderCard(data, docs[index].id, false);
            },
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('saved_providers')
              .snapshots(),
          builder: (context, savedSnapshot) {
            final savedIds = savedSnapshot.hasData
                ? savedSnapshot.data!.docs.map((doc) => doc.id).toSet()
                : <String>{};

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(20.w, 25.h, 20.w, 100.h),
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final providerId = docs[index].id;
                final isSaved = savedIds.contains(providerId);
                return _buildProviderCard(data, providerId, isSaved);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProviderCard(
      Map<String, dynamic> data, String id, bool isSaved) {
    final name = data['businessName'] ?? 'Service Provider';
    final type = data['category'] ?? 'Service';
    final rating = (data['rating'] ?? 0.0).toDouble();
    final imageUrl = data['imageUrl'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 25.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30.r),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 250.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              Positioned(
                top: 15.h,
                right: 15.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16.sp),
                      SizedBox(width: 4.w),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20.h,
                left: 20.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5BB1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    type.toLowerCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Available',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderProfilePage(
                                providerId: id,
                                category: type,
                                isEventSaving: widget.isEventSaving,
                                eventId: widget.eventId,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: Text(
                          widget.isEventSaving
                              ? 'Select Service'
                              : 'View Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    GestureDetector(
                      onTap: () => _toggleSaveProvider(id, data),
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(
                            color: isSaved
                                ? AppColors.primaryGreen
                                : AppColors.primaryGreen.withOpacity(0.5),
                            width: 2.w,
                          ),
                        ),
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: AppColors.primaryGreen,
                          size: 24.sp,
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
      height: 250.h,
      width: double.infinity,
      color: Colors.grey[100],
      child: Icon(Icons.image_outlined, size: 60.sp, color: Colors.grey[300]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 100.sp, color: Colors.grey[200]),
          SizedBox(height: 20.h),
          Text(
            _showSavedOnly ? 'No favorites yet' : 'No results found',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            'Login to see favorites',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
          ),
        ],
      ),
    );
  }
}

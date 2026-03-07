import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/styles.dart';
import 'provider_profile.dart';

class DiscoveryPage extends StatefulWidget {
  final String initialCategory;
  final String? eventId;
  final bool isEventSaving;
  
  const DiscoveryPage({
    super.key,
    this.initialCategory = 'All',
    this.eventId,
    this.isEventSaving = false,
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
    'Transport'
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleSaveProvider(String providerId, Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to save providers')),
        );
        return;
      }

      // If this is event-specific saving
      if (widget.isEventSaving && widget.eventId != null) {
        final docRef = FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId!)
            .collection('services')
            .doc(providerId);

        final doc = await docRef.get();

        if (doc.exists) {
          await docRef.delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service removed from event'),
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
          
          // Add notification for adding service to event
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .add({
            'title': 'Service Added',
            'message': '${data['businessName'] ?? data['name'] ?? 'A service'} has been added to your event.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'service',
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service added to event'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        return;
      }

      // Original behavior for general favorites
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

        // Add notification for adding to favorites
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'title': 'New Favorite',
          'message': '${data['businessName'] ?? data['name'] ?? 'A provider'} has been added to your favorites.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'service',
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Filters',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              SizedBox(height: 20.h),
              Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 10.w,
                children: [
                  ChoiceChip(label: Text('Rating', style: TextStyle(fontSize: 12.sp)), selected: true, onSelected: (_) {}),
                  ChoiceChip(label: Text('Price: Low to High', style: TextStyle(fontSize: 12.sp)), selected: false, onSelected: (_) {}),
                  ChoiceChip(label: Text('Popularity', style: TextStyle(fontSize: 12.sp)), selected: false, onSelected: (_) {}),
                ],
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
        ),
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
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
      bottomNavigationBar: widget.isEventSaving ? null : const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.isEventSaving || _showSavedOnly)
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
                  onPressed: () {
                    if (widget.isEventSaving) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _showSavedOnly = false;
                      });
                    }
                  },
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEventSaving
                        ? 'Add Services'
                        : (_showSavedOnly ? 'My Favorites' : 'Discovery'),
                    style: TextStyle(
                      fontSize: 32.sp,
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
                      fontSize: 14.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!widget.isEventSaving)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showSavedOnly = !_showSavedOnly;
                });
              },
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: _showSavedOnly ? Colors.white : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  _showSavedOnly ? Icons.bookmark : Icons.bookmark_border,
                  color: _showSavedOnly ? AppColors.primaryBlue : Colors.white,
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
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 15.sp),
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 15.sp),
                      prefixIcon: Icon(Icons.search, color: AppColors.primaryGreen, size: 24.sp),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, size: 20.sp),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  padding: EdgeInsets.all(15.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Icon(Icons.tune, color: AppColors.primaryBlue, size: 24.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          SizedBox(
            height: 38.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 22.w),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? AppColors.primaryBlue : Colors.white,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13.sp,
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

  String _getCategoryForQuery(String category) {
    switch (category) {
      case 'Photography':
        return 'photographer';
      default:
        return category.toLowerCase();
    }
  }

  Widget _buildProvidersList() {
    if (_showSavedOnly) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return _buildLoginPrompt();
      return _buildStreamList(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('saved_providers')
      );
    }

    Query query = FirebaseFirestore.instance.collection('service_providers');
    if (_selectedCategory != 'All') {
      final categoryForQuery = _getCategoryForQuery(_selectedCategory);
      query = query.where(Filter.or(
          Filter('providerType', isEqualTo: categoryForQuery),
          Filter('category', isEqualTo: categoryForQuery)
      ));
    }
    return _buildStreamList(query);
  }

  Widget _buildStreamList(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['businessName'] ?? data['name'] ?? '').toString().toLowerCase();
          final type = (data['providerType'] ?? data['category'] ?? '').toString().toLowerCase();
          final location = (data['location'] ?? '').toString().toLowerCase();

          return name.contains(_searchQuery) ||
              type.contains(_searchQuery) ||
              location.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20.w, 25.h, 20.w, 100.h),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildProviderCard(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> data, String id) {
    final name = data['businessName'] ?? data['name'] ?? 'Unknown Provider';
    final type = data['providerType'] ?? data['category'] ?? 'Service';
    final rating = (data['rating'] ?? 0.0).toDouble();
    final price = (data['price'] ?? 0.0).toDouble();
    final imageUrl = data['imageUrl'] ?? '';
    final availability = data['availability'] ?? 'Available';
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      margin: EdgeInsets.only(bottom: 22.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                  top: 15.h,
                  right: 15.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 18.sp),
                        SizedBox(width: 4.w),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : 'New',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 15.h,
                  left: 15.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.5.w,
                        ),
                      ),
                    ),
                    if (price > 0)
                      Text(
                        '\$${price.toInt()}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16.sp, color: Colors.grey),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        availability,
                        style: TextStyle(color: Colors.grey, fontSize: 14.sp, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                                providerData: data,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: Text('View Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp)),
                      ),
                    ),
                    SizedBox(width: 15.w),
                    StreamBuilder<DocumentSnapshot>(
                        stream: user == null
                            ? null
                            : (widget.isEventSaving && widget.eventId != null
                                ? FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(widget.eventId!)
                                    .collection('services')
                                    .doc(id)
                                    .snapshots()
                                : FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('saved_providers')
                                    .doc(id)
                                    .snapshots()),
                        builder: (context, snapshot) {
                          final isSaved = snapshot.hasData && snapshot.data!.exists;
                          return GestureDetector(
                            onTap: () => _toggleSaveProvider(id, data),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isSaved ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
                                border: Border.all(
                                  color: isSaved ? AppColors.primaryBlue : Colors.grey.withOpacity(0.3),
                                  width: 1.5.w,
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Icon(
                                isSaved ? (widget.isEventSaving ? Icons.check_circle : Icons.bookmark) : (widget.isEventSaving ? Icons.add_circle_outline : Icons.bookmark_border_rounded),
                                color: AppColors.primaryBlue,
                                size: 24.sp,
                              ),
                            ),
                          );
                        }
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withOpacity(0.1),
            AppColors.primaryBlue.withOpacity(0.1)
          ],
        ),
      ),
      child: Icon(Icons.image_outlined, size: 60.sp, color: AppColors.primaryBlue.withOpacity(0.3)),
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
          SizedBox(height: 8.h),
          Text(
            _showSavedOnly ? 'Start exploring and save your top picks' : 'Try a different keyword or category',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
          if (!_showSavedOnly && (_searchQuery.isNotEmpty || _selectedCategory != 'All'))
            Padding(
              padding: EdgeInsets.only(top: 24.h),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedCategory = 'All';
                  });
                },
                icon: Icon(Icons.refresh_rounded, size: 24.sp),
                label: Text('Reset Discovery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
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
          Text('Login to see favorites', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: Text('Go to Login', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}

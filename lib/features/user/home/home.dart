import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/styles.dart';
import '../../../core/constants/strings.dart';
import '../discovery/discovery.dart';
import 'notifications.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  double _totalBudget = 0;
  double _totalSpent = 0;

  List<DocumentSnapshot> _upcomingEvents = [];
  List<DocumentSnapshot> _todayExpenses = [];

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    _fetchUpcomingEvents();
    _fetchTodayExpenses();
    _fetchTotalBudget();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fetchTotalBudget() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('events').get();

    double budget = 0;
    double spent = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      budget += (data['budget'] ?? 0).toDouble();
      spent += (data['spent'] ?? 0).toDouble();
    }

    setState(() {
      _totalBudget = budget;
      _totalSpent = spent;
    });
  }

  void _fetchUpcomingEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .orderBy('date')
        .get();

    setState(() {
      _upcomingEvents = snapshot.docs;
    });
  }

  void _fetchTodayExpenses() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .get();

    setState(() {
      _todayExpenses = snapshot.docs;
    });
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${now.day} ${months[now.month - 1]}, ${now.year}";
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No Date';
    DateTime dt;
    if (date is Timestamp) {
      dt = date.toDate();
    } else if (date is String) {
      return date;
    } else {
      return 'Invalid Date';
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${dt.day} ${months[dt.month - 1]}, ${dt.year}";
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
              SizedBox(height: 20.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
                  ),
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                    children: [
                      _buildBudgetOverview(),
                      SizedBox(height: 28.h),
                      _buildPromoBanners(),
                      SizedBox(height: 28.h),
                      _buildCategories(),
                      SizedBox(height: 28.h),
                      _buildUpcomingEvents(),
                      SizedBox(height: 28.h),
                      _buildTodayExpenses(),
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.welcomeBack,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5.w,
                          ),
                        ),
                      ]
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: user == null
                      ? null
                      : FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('notifications')
                          .where('isRead', isEqualTo: false)
                          .snapshots(),
                  builder: (context, snapshot) {
                    final int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.w,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 28.sp),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationsPage()),
                              );
                            },
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 6.w,
                            top: 6.h,
                            child: Container(
                              padding: EdgeInsets.all(5.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3D00),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.white, width: 2.5.w),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF3D00).withOpacity(0.5),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20.w,
                                minHeight: 20.w,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                      ],
                    );
                  }
                )
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.7), size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  _getCurrentDate(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= BUDGET OVERVIEW =================
  Widget _buildBudgetOverview() {
    final remaining = _totalBudget - _totalSpent;
    final percentage = _totalBudget > 0 ? (_totalSpent / _totalBudget) : 0.0;

    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [AppColors.primaryShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalBudget,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}% Used',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '\$${_totalBudget.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.w,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _budgetInfoTile(AppStrings.spent, _totalSpent, Icons.arrow_upward),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _budgetInfoTile(AppStrings.remaining, remaining, Icons.arrow_downward),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _budgetInfoTile(String label, double amount, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================= PROMO BANNERS =================
  Widget _buildPromoBanners() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Text(
            AppStrings.specialOffers,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.5.w,
            ),
          ),
        ),
        SizedBox(
          height: 180.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _promoCard(
                'Hire Best Photographers',
                'Up to 30% off',
                Icons.camera_alt_rounded,
                [AppColors.primaryBlue, AppColors.primaryGreen],
                imagePath: 'assets/images/hire.jpg',
              ),
              _promoCard(
                'Luxury Hotels',
                'Special event rates',
                Icons.hotel_rounded,
                [AppColors.primaryGreen, const Color(0xFF26A69A)],
                imagePath: 'assets/images/hire2.jpg',
              ),
              _promoCard(
                'Outdoor Locations',
                'Book now',
                Icons.park_rounded,
                [const Color(0xFF26A69A), AppColors.primaryGreen],
                imagePath: 'assets/images/hire3.jpg',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _promoCard(String title, String subtitle, IconData icon, List<Color> colors, {String? imagePath}) {
    return Container(
      width: 315.w,
      margin: EdgeInsets.only(right: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.2),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: imagePath != null
            ? Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                  child: Center(child: Icon(icon, color: Colors.white, size: 40.sp)),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20.w,
                      top: -20.h,
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: colors[1], size: 32.sp),
                          ),
                          const Spacer(),
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3.w,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ================= CATEGORIES =================
  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.camera_alt, 'label': 'Photography', 'category': 'Photography'},
      {'icon': Icons.location_city, 'label': 'Venues', 'category': 'Venue'},
      {'icon': Icons.restaurant, 'label': 'Catering', 'category': 'Catering'},
      {'icon': Icons.music_note, 'label': 'Music', 'category': 'Music'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.categories,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 110.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final item = categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiscoveryPage(
                        initialCategory: item['category'] as String,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 90.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10.r,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'] as IconData,
                          size: 32.sp, color: AppColors.primaryGreen),
                      SizedBox(height: 8.h),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= UPCOMING EVENTS =================
  Widget _buildUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.upcomingEvents,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 16.h),
        if (_upcomingEvents.isEmpty)
          Text('No upcoming events', style: TextStyle(color: Colors.grey, fontSize: 14.sp))
        else
          ..._upcomingEvents.take(3).map((e) {
            final data = e.data() as Map<String, dynamic>;
            return Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              margin: EdgeInsets.only(bottom: 12.h),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.event, color: AppColors.primaryGreen, size: 24.sp),
                ),
                title: Text(data['eventName'] ?? data['name'] ?? 'Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                subtitle: Text(_formatDate(data['date']), style: TextStyle(fontSize: 14.sp)),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              ),
            );
          }).toList(),
      ],
    );
  }

  // ================= TODAY EXPENSES =================
  Widget _buildTodayExpenses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.todayExpenses,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 16.h),
        if (_todayExpenses.isEmpty)
          Text('No expenses today', style: TextStyle(color: Colors.grey, fontSize: 14.sp))
        else
          ..._todayExpenses.map((e) {
            final data = e.data() as Map<String, dynamic>;
            return Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              margin: EdgeInsets.only(bottom: 12.h),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.money, color: AppColors.primaryBlue, size: 24.sp),
                ),
                title: Text(data['description'] ?? data['title'] ?? 'Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                subtitle: Text('\$${(data['amount'] ?? 0).toStringAsFixed(2)}', style: TextStyle(fontSize: 14.sp)),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              ),
            );
          }).toList(),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/provider_bottom_nav.dart';
import '../../../core/constants/colors.dart';
import '../services/my_services.dart';

class ServiceProviderDashboard extends StatefulWidget {
  final String providerId;
  final String providerType;

  const ServiceProviderDashboard({
    super.key,
    required this.providerId,
    required this.providerType,
  });

  @override
  State<ServiceProviderDashboard> createState() => _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  double _totalRevenue = 0;
  double _monthlyRevenue = 0;
  int _totalBookings = 0;
  int _pendingBookings = 0;
  int _completedBookings = 0;
  double _averageRating = 0;
  int _totalReviews = 0;

  List<DocumentSnapshot> _recentBookings = [];
  List<DocumentSnapshot> _upcomingEvents = [];
  Map<String, dynamic>? _providerData;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _fetchProviderData();
    _fetchBookingStats();
    _fetchRecentBookings();
    _fetchUpcomingEvents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchProviderData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.providerId)
          .get();

      if (doc.exists) {
        setState(() {
          _providerData = doc.data();
          _averageRating = (_providerData?['rating'] ?? 0).toDouble();
          _totalReviews = (_providerData?['reviewCount'] ?? 0);
        });
      }
    } catch (e) {
      debugPrint('Error fetching provider data: $e');
    }
  }

  Future<void> _fetchBookingStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: widget.providerId)
          .get();

      double totalRev = 0;
      double monthlyRev = 0;
      int pending = 0;
      int completed = 0;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        totalRev += amount;

        final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
        if (timestamp != null && timestamp.isAfter(monthStart)) {
          monthlyRev += amount;
        }

        final status = data['status'] ?? '';
        if (status == 'pending') pending++;
        if (status == 'completed') completed++;
      }

      setState(() {
        _totalRevenue = totalRev;
        _monthlyRevenue = monthlyRev;
        _totalBookings = snapshot.docs.length;
        _pendingBookings = pending;
        _completedBookings = completed;
      });
    } catch (e) {
      debugPrint('Error fetching booking stats: $e');
    }
  }

  Future<void> _fetchRecentBookings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: widget.providerId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        _recentBookings = snapshot.docs;
      });
    } catch (e) {
      debugPrint('Error fetching recent bookings: $e');
    }
  }

  Future<void> _fetchUpcomingEvents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: widget.providerId)
          .where('status', isEqualTo: 'confirmed')
          .orderBy('eventDate')
          .limit(5)
          .get();

      setState(() {
        _upcomingEvents = snapshot.docs;
      });
    } catch (e) {
      debugPrint('Error fetching upcoming events: $e');
    }
  }

  String _getProviderTitle() {
    switch (widget.providerType.toLowerCase()) {
      case 'photographer':
      case 'photography':
        return 'Photography Dashboard';
      case 'catering':
        return 'Catering Dashboard';
      case 'venue':
        return 'Venue Dashboard';
      case 'music':
        return 'Music Dashboard';
      case 'decoration':
        return 'Decoration Dashboard';
      default:
        return 'Service Provider Dashboard';
    }
  }

  IconData _getProviderIcon() {
    switch (widget.providerType.toLowerCase()) {
      case 'photographer':
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'catering':
        return Icons.restaurant_rounded;
      case 'venue':
        return Icons.location_city_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'decoration':
        return Icons.celebration_rounded;
      default:
        return Icons.business_rounded;
    }
  }

  void _navigateToServices() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyServicesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
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
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchProviderData();
                      await _fetchBookingStats();
                      await _fetchRecentBookings();
                      await _fetchUpcomingEvents();
                    },
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                      children: [
                        _buildRevenueOverview(),
                        SizedBox(height: 24.h),
                        _buildStatsGrid(),
                        SizedBox(height: 28.h),
                        _buildQuickActions(),
                        SizedBox(height: 28.h),
                        _buildRecentBookings(),
                        SizedBox(height: 28.h),
                        _buildUpcomingEvents(),
                        SizedBox(height: 28.h),
                        _buildPerformanceMetrics(),
                        SizedBox(height: 100.h),
                      ],
                    ),
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
          onPressed: _navigateToServices,
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
      bottomNavigationBar: const ProviderBottomNav(currentIndex: 0),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    final imageUrl = _providerData?['imageUrl'] ?? '';
    
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2.w,
                    ),
                    image: imageUrl.isNotEmpty 
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                  ),
                  child: imageUrl.isEmpty 
                    ? Icon(_getProviderIcon(), color: Colors.white, size: 32.sp)
                    : null,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _providerData?['businessName'] ?? 'Service Provider',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5.w,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _getProviderTitle(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: Colors.white, size: 28.sp),
                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20.sp),
                SizedBox(width: 6.w),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  '($_totalReviews reviews)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= REVENUE OVERVIEW =================
  Widget _buildRevenueOverview() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Revenue',
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
                  'All Time',
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
            '\$${_totalRevenue.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.w,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '\$${_monthlyRevenue.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATS GRID =================
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          'Total Bookings',
          _totalBookings.toString(),
          Icons.event_available,
          AppColors.primaryGreen,
        ),
        _buildStatCard(
          'Pending',
          _pendingBookings.toString(),
          Icons.schedule,
          const Color(0xFFFF6F00),
        ),
        _buildStatCard(
          'Completed',
          _completedBookings.toString(),
          Icons.check_circle,
          AppColors.primaryBlue,
        ),
        _buildStatCard(
          'Rating',
          _averageRating.toStringAsFixed(1),
          Icons.star,
          const Color(0xFFFFC107),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= QUICK ACTIONS =================
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.5.w,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Manage\nServices',
                Icons.tune,
                AppColors.primaryGreen,
                _navigateToServices,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActionButton(
                'View\nBookings',
                Icons.calendar_today,
                AppColors.primaryBlue,
                () {
                  // Navigate to bookings
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActionButton(
                'Analytics',
                Icons.analytics,
                const Color(0xFF26A69A),
                () {
                  // Navigate to analytics
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [AppColors.cardShadow()],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ================= RECENT BOOKINGS =================
  Widget _buildRecentBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (_recentBookings.isEmpty)
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [AppColors.cardShadow()],
            ),
            child: const Center(
              child: Text(
                'No bookings yet',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          )
        else
          ..._recentBookings.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildBookingCard(data);
          }).toList(),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = AppColors.primaryGreen;
        break;
      case 'completed':
        statusColor = AppColors.primaryBlue;
        break;
      case 'cancelled':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = const Color(0xFFFF6F00);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.event, color: statusColor, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['eventName'] ?? 'Event Booking',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      data['clientName'] ?? 'Client',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5.w,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey[600]),
                  SizedBox(width: 6.w),
                  Text(
                    _formatDate(data['eventDate']),
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              Text(
                '\$${(data['amount'] ?? 0).toDouble().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= UPCOMING EVENTS =================
  Widget _buildUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 16.h),
        if (_upcomingEvents.isEmpty)
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [AppColors.cardShadow()],
            ),
            child: const Center(
              child: Text(
                'No upcoming events',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          )
        else
          ..._upcomingEvents.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGreen, Color(0xFF26A69A)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [AppColors.cardShadow()],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.event, color: Colors.white, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['eventName'] ?? 'Event',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatDate(data['eventDate']),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16.sp),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  // ================= PERFORMANCE METRICS =================
  Widget _buildPerformanceMetrics() {
    final completionRate = _totalBookings > 0
        ? ((_completedBookings / _totalBookings) * 100).toStringAsFixed(0)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [AppColors.cardShadow()],
          ),
          child: Column(
            children: [
              _buildMetricRow('Completion Rate', '$completionRate%', Icons.check_circle, Colors.green),
              Divider(height: 24.h),
              _buildMetricRow('Average Rating', _averageRating.toStringAsFixed(1), Icons.star, Colors.amber),
              Divider(height: 24.h),
              _buildMetricRow('Total Reviews', _totalReviews.toString(), Icons.rate_review, AppColors.primaryBlue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ================= HELPERS =================
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

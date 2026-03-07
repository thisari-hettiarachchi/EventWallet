import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/provider_bottom_nav.dart';

class ServiceProviderBookingsPage extends StatefulWidget {
  const ServiceProviderBookingsPage({super.key});

  @override
  State<ServiceProviderBookingsPage> createState() => _ServiceProviderBookingsPageState();
}

class _ServiceProviderBookingsPageState extends State<ServiceProviderBookingsPage> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking $status successfully', style: TextStyle(fontSize: 14.sp)),
            backgroundColor: status == 'confirmed' ? const Color(0xFF00897B) : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: TextStyle(fontSize: 14.sp)), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return Scaffold(body: Center(child: Text('Please login', style: TextStyle(fontSize: 16.sp))));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
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
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 20.h),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        TabBar(
                          labelColor: const Color(0xFF00897B),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF00897B),
                          indicatorWeight: 3.h,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                          tabs: const [
                            Tab(text: 'Pending'),
                            Tab(text: 'Confirmed'),
                            Tab(text: 'History'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildBookingList('pending'),
                              _buildBookingList('confirmed'),
                              _buildBookingList('completed', otherStatus: 'cancelled'),
                            ],
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
        bottomNavigationBar: const ProviderBottomNav(currentIndex: 1),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            Text(
              'My Bookings',
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5.w,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(String status, {String? otherStatus}) {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: user!.uid);

    if (otherStatus != null) {
      query = query.where('status', whereIn: [status, otherStatus]);
    } else {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('eventDate', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80.sp, color: Colors.grey[300]),
                SizedBox(height: 16.h),
                Text(
                  'No ${status.toLowerCase()} bookings', 
                  style: TextStyle(color: Colors.grey, fontSize: 16.sp, fontWeight: FontWeight.w500)
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildBookingCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(String id, Map<String, dynamic> data) {
    final DateTime eventDate = (data['eventDate'] as Timestamp).toDate();
    final String status = data['status'] ?? 'pending';
    
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Strip
            Container(
              height: 4.h,
              width: double.infinity,
              color: _getStatusColor(status),
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
                          data['eventName'] ?? 'Special Event',
                          style: TextStyle(
                            fontSize: 20.sp, 
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1F36),
                          ),
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoTile(Icons.person, 'Client', data['clientName'] ?? 'N/A', const Color(0xFF1565C0)),
                  _buildInfoTile(Icons.calendar_today, 'Date', _formatDate(eventDate), const Color(0xFF00897B)),
                  _buildInfoTile(Icons.location_on, 'Location', data['location'] ?? 'Not specified', Colors.orange),
                  _buildInfoTile(Icons.category, 'Event Type', data['eventType'] ?? 'N/A', Colors.purple),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: const Divider(height: 1),
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Revenue',
                        style: TextStyle(
                          color: const Color(0xFF4A5568),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${(data['amount'] ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00897B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (status == 'pending')
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _updateBookingStatus(id, 'cancelled'),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, size: 20.sp, color: Colors.red[700]),
                                SizedBox(width: 8.w),
                                Text(
                                  'Decline', 
                                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w700, fontSize: 14.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1.w, height: 30.h, color: Colors.grey[300]),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _updateBookingStatus(id, 'confirmed'),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 20.sp, color: const Color(0xFF00897B)),
                                SizedBox(width: 8.w),
                                Text(
                                  'Approve', 
                                  style: TextStyle(color: const Color(0xFF00897B), fontWeight: FontWeight.w700, fontSize: 14.sp),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF1A1F36), 
                    fontSize: 14.sp, 
                    fontWeight: FontWeight.w600,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return const Color(0xFF00897B);
      case 'cancelled': return Colors.red;
      case 'completed': return const Color(0xFF1565C0);
      default: return Colors.orange;
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5.w),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

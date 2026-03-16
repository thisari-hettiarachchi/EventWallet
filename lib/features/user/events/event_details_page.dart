import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'tasks_page.dart';
import 'guest_list.dart';
import '../budget/expenses_page.dart';
import '../../../core/constants/colors.dart';
import '../discovery/discovery.dart';
import 'edit_event.dart';
import '../../../services/events_service.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final String eventName;

  const EventDetailsPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _canManageEvent(Map<String, dynamic> event) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && event['userId'] == user.uid;
  }

  Future<bool> _confirmDeleteEvent(String eventName) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              'Delete Event',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete "$eventName"? This action cannot be undone.',
              style: TextStyle(fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteEvent(Map<String, dynamic> event) async {
    if (_isDeleting) return;

    final user = FirebaseAuth.instance.currentUser;
    final eventName = (event['eventName'] ?? event['name'] ?? 'this event').toString();

    if (user == null || event['userId'] != user.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own events.')),
      );
      return;
    }

    final shouldDelete = await _confirmDeleteEvent(eventName);
    if (!shouldDelete || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _firestoreService.deleteEvent(widget.eventId);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'Event Deleted',
        'message': 'Your event "$eventName" has been deleted.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'event',
      });

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete event. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        final eventData = snapshot.data!.data();
        if (eventData == null) {
          return const Scaffold(body: Center(child: Text('Event not found')));
        }
        final event = eventData as Map<String, dynamic>;
        final canManageEvent = _canManageEvent(event);

        final budget = (event['budget'] ?? 0).toDouble();
        final spent = (event['spent'] ?? 0).toDouble();
        final progress = budget > 0 ? spent / budget : 0.0;
        final status = event['status'] ?? 'Upcoming';
        final color = _getStatusColor(status);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Background gradient
              Container(
                height: 320.h,
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
              ),

              // Decorative circles
              Positioned(
                top: -50.h,
                right: -50.w,
                child: Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                top: 100.h,
                left: -30.w,
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Custom App Bar
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12.r),
                                child: Padding(
                                  padding: EdgeInsets.all(12.r),
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(12.r),
                                child: Padding(
                                  padding: EdgeInsets.all(12.r),
                                  child: Icon(
                                    Icons.share_outlined,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (canManageEvent) ...[
                            SizedBox(width: 8.w),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.w,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isDeleting
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditEventPage(
                                                eventId: widget.eventId,
                                                eventData: event,
                                              ),
                                            ),
                                          );
                                        },
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Padding(
                                    padding: EdgeInsets.all(12.r),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.w,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isDeleting ? null : () => _deleteEvent(event),
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Padding(
                                    padding: EdgeInsets.all(12.r),
                                    child: _isDeleting
                                        ? SizedBox(
                                            height: 20.sp,
                                            width: 20.sp,
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Icon(
                                            Icons.delete_outline,
                                            color: Colors.white,
                                            size: 20.sp,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Header Content
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2.w,
                              ),
                            ),
                            child: Icon(
                              _getCategoryIcon(event['category'] ?? 'Other'),
                              size: 50.sp,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            event['eventName'] ?? event['name'] ?? 'Event',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5.w,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Scrollable Content
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ListView(
                          padding: EdgeInsets.all(20.r),
                          children: [
                            // Main Management Section
                            Text(
                              'Event Management',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSmallActionCard(
                                    'Expenses',
                                    Icons.account_balance_wallet,
                                    AppColors.primaryGreen,
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpensesPage(eventId: widget.eventId, eventName: widget.eventName))),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: _buildSmallActionCard(
                                    'Tasks',
                                    Icons.task_alt,
                                    AppColors.primaryBlue,
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => TasksPage(eventId: widget.eventId))),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSmallActionCard(
                                    'Guest List',
                                    Icons.people_outline,
                                    Colors.purple,
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuestListPage(eventId: widget.eventId))),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: _buildSmallActionCard(
                                    'Add Services',
                                    Icons.add_business_outlined,
                                    Colors.orange,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DiscoveryPage(
                                          eventId: widget.eventId,
                                          isEventSaving: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),

                            // Budget Progress
                            _buildModernCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10.r),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.primaryGradient,
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Icon(
                                          Icons.trending_up,
                                          color: Colors.white,
                                          size: 20.sp,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'Budget Progress',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.h),
                                  Stack(
                                    children: [
                                      Container(
                                        height: 20.h,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: progress > 1 ? 1 : progress,
                                        child: Container(
                                          height: 20.h,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: progress > 0.8
                                                  ? [Colors.orange.shade400, Colors.red.shade400]
                                                  : [const Color(0xFF00897B), const Color(0xFF1565C0)],
                                            ),
                                            borderRadius: BorderRadius.circular(10.r),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (progress > 0.8
                                                    ? Colors.orange
                                                    : const Color(0xFF00897B))
                                                    .withOpacity(0.4),
                                                blurRadius: 8.r,
                                                offset: Offset(0, 2.h),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${spent.toStringAsFixed(2)} spent',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '\$${budget.toStringAsFixed(2)} budget',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Event Information
                            _buildModernCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10.r),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.primaryGradient,
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 20.sp,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'Event Information',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.h),
                                  _buildInfoRow(
                                    Icons.calendar_today,
                                    'Date',
                                    _formatTimestamp(event['date']),
                                    AppColors.primaryGreen,
                                  ),
                                  _buildInfoRow(
                                    Icons.location_on,
                                    'Venue',
                                    event['venue'] ?? 'Not specified',
                                    AppColors.primaryBlue,
                                  ),
                                  _buildInfoRow(
                                    Icons.category,
                                    'Category',
                                    event['category'] ?? 'Other',
                                    AppColors.primaryGreen,
                                  ),
                                  _buildInfoRow(
                                    Icons.people,
                                    'Attendees',
                                    event['attendees']?.toString() ?? 'Not specified',
                                    AppColors.primaryBlue,
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // Description
                            if (event['description'] != null &&
                                event['description'].toString().isNotEmpty)
                              _buildModernCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10.r),
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Icon(
                                            Icons.description,
                                            color: Colors.white,
                                            size: 20.sp,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          'Description',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      event['description'],
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: AppColors.textGrey,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 24.h),

                            // Saved Services Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Services for this Event',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DiscoveryPage(
                                        eventId: widget.eventId,
                                        isEventSaving: true,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(Icons.add, size: 18.sp),
                                  label: Text('Add', style: TextStyle(fontSize: 14.sp)),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            _buildSavedServicesSection(),

                            SizedBox(height: 100.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedServicesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('services')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 100.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiscoveryPage(
                  eventId: widget.eventId,
                  isEventSaving: true,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(32.r),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.business_center_outlined, size: 48.sp, color: Colors.grey.shade400),
                  SizedBox(height: 16.h),
                  Text(
                    'No services added yet',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Tap to discover and add services to your event',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final services = snapshot.data!.docs;
        return Column(
          children: List.generate(
            services.length,
            (index) {
              final data = services[index].data() as Map<String, dynamic>;
              final name = data['businessName'] ?? data['name'] ?? 'Unknown Service';
              final type = data['providerType'] ?? data['category'] ?? 'Service';
              final price = (data['price'] ?? 0.0).toDouble();
              final rating = (data['rating'] ?? 0.0).toDouble();

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.business, color: AppColors.primaryGreen, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Text(
                                type,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (rating > 0) ...[
                                SizedBox(width: 8.w),
                                Icon(Icons.star_rounded, size: 12.sp, color: Colors.amber),
                                SizedBox(width: 2.w),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (price > 0)
                          Text(
                            '\$${price.toInt()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        SizedBox(height: 4.h),
                        GestureDetector(
                          onTap: () {
                            FirebaseFirestore.instance
                                .collection('events')
                                .doc(widget.eventId)
                                .collection('services')
                                .doc(services[index].id)
                                .delete();
                          },
                          child: Icon(Icons.close, size: 18.sp, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSmallActionCard(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      Color color, {
        bool isLast = false,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
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
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
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
      case 'Upcoming':
        return AppColors.primaryBlue;
      case 'In Progress':
        return Colors.orange.shade600;
      case 'Completed':
        return AppColors.primaryGreen;
      default:
        return AppColors.textGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Wedding':
        return Icons.favorite;
      case 'Birthday':
        return Icons.cake;
      case 'Corporate':
        return Icons.business;
      case 'Conference':
        return Icons.event;
      case 'Party':
        return Icons.celebration;
      case 'Charity':
        return Icons.volunteer_activism;
      default:
        return Icons.event_note;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'No Date';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      return timestamp;
    } else {
      return 'Invalid Date';
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/constants/colors.dart';
import 'create_event.dart';
import 'event_details_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Determines event status based on date
  String _getEventStatus(dynamic timestamp) {
    if (timestamp == null) return 'Upcoming';
    DateTime eventDate;

    if (timestamp is Timestamp) {
      eventDate = timestamp.toDate();
    } else if (timestamp is DateTime) {
      eventDate = timestamp;
    } else {
      return 'Upcoming';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);

    if (eventDay.isAfter(today) || eventDay.isAtSameMomentAs(today)) {
      return 'Upcoming';
    } else {
      return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with Gradient
          Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'My Events',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5.w,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.w,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreateEventPage(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 10.h,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'New Event',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.sp,
                                      ),
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [AppColors.cardShadow()],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        style: TextStyle(fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.primaryGreen,
                            size: 24.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 55.h),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -25.h, 0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryGreen,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primaryGreen,
                    indicatorWeight: 3.h,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(fontSize: 14.sp),
                    tabs: const [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEventList('Upcoming'),
                        _buildEventList('Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildEventList(String statusFilter) {
    if (user == null) {
      return const Center(child: Text('Please login to view events'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('date', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No events found.',
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          );
        }

        final events = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['eventName'] ?? data['name'] ?? '')
              .toString()
              .toLowerCase();
          final status = _getEventStatus(data['date']);
          return title.contains(_searchQuery) && status == statusFilter;
        }).toList();

        if (events.isEmpty) {
          return Center(
            child: Text(
              'No $statusFilter events found.',
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          itemCount: events.length,
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final event = events[index];
            final data = event.data() as Map<String, dynamic>;
            final Color color;
            switch (statusFilter) {
              case 'Completed':
                color = AppColors.primaryGreen;
                break;
              default:
                color = AppColors.primaryBlue;
            }

            final double budgetValue = (data['budget'] ?? 0).toDouble();
            final double spentValue = (data['spent'] ?? 0).toDouble();
            final double progress = budgetValue > 0
                ? (spentValue / budgetValue).clamp(0.0, 1.0)
                : 0.0;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailsPage(
                      eventId: event.id,
                      eventName: data['eventName'] ?? data['name'] ?? 'Event',
                    ),
                  ),
                );
              },
              child: _buildEventCard(
                data['eventName'] ?? data['name'] ?? '',
                _formatTimestamp(data['date']),
                data['venue'] ?? '',
                '\$${budgetValue.toStringAsFixed(2)}',
                '\$${spentValue.toStringAsFixed(2)}',
                progress,
                color,
                _getCategoryIcon(data['category'] ?? 'Other'),
                statusFilter,
              ),
            );
          },
        );
      },
    );
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

  Widget _buildEventCard(
    String title,
    String date,
    String venue,
    String budget,
    String spent,
    double progress,
    Color color,
    IconData icon,
    String status,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(icon, color: color, size: 28.sp),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    venue,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          budget,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spent',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          spent,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'of budget',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8.h,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

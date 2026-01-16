import 'package:flutter/material.dart';
import 'bottom_nav.dart';
import 'create_event.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.teal.shade500],
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'My Events',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CreateEventPage()),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.add, color: Colors.blue.shade700),
                                    const SizedBox(width: 6),
                                    Text(
                                      'New Event',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue.shade700,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue.shade700,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Upcoming'),
                        Tab(text: 'In Progress'),
                        Tab(text: 'Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingEvents(),
                  _buildInProgressEvents(),
                  _buildCompletedEvents(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildUpcomingEvents() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEventCard(
          'Wedding Ceremony',
          'Dec 25, 2025',
          'St. Mary\'s Church',
          '\$10,000',
          '\$8,500',
          0.85,
          Colors.pink,
          Icons.favorite,
          '25 days left',
        ),
        const SizedBox(height: 16),
        _buildEventCard(
          'Birthday Party',
          'Jan 15, 2026',
          'Grand Hotel Ballroom',
          '\$3,000',
          '\$2,250',
          0.75,
          Colors.orange,
          Icons.cake,
          '46 days left',
        ),
        const SizedBox(height: 16),
        _buildEventCard(
          'Corporate Meeting',
          'Feb 5, 2026',
          'Conference Center',
          '\$7,000',
          '\$5,000',
          0.71,
          Colors.blue,
          Icons.business,
          '67 days left',
        ),
      ],
    );
  }

  Widget _buildInProgressEvents() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEventCard(
          'Product Launch',
          'Dec 20, 2025',
          'Tech Hub Auditorium',
          '\$15,000',
          '\$12,500',
          0.83,
          Colors.purple,
          Icons.rocket_launch,
          'In 20 days',
        ),
      ],
    );
  }

  Widget _buildCompletedEvents() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEventCard(
          'Team Building',
          'Nov 15, 2025',
          'Mountain Resort',
          '\$5,000',
          '\$4,800',
          0.96,
          Colors.green,
          Icons.groups,
          'Completed',
        ),
        const SizedBox(height: 16),
        _buildEventCard(
          'Charity Gala',
          'Oct 28, 2025',
          'City Convention Center',
          '\$20,000',
          '\$19,500',
          0.975,
          Colors.teal,
          Icons.volunteer_activism,
          'Completed',
        ),
      ],
    );
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      venue,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            budget,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
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
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            spent,
                            style: TextStyle(
                              fontSize: 17,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            'of budget',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
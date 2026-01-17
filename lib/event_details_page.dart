import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventDetailsPage extends StatelessWidget {
  final String eventId;
  final String eventName; // For the hero animation

  const EventDetailsPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data!.data() as Map<String, dynamic>;
        final budget = (event['budget'] ?? 0).toDouble();
        final spent = (event['spent'] ?? 0).toDouble();
        final progress = budget > 0 ? spent / budget : 0.0;
        final status = event['status'] ?? 'Upcoming';
        final color = _getStatusColor(status);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.teal.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            _getCategoryIcon(event['category'] ?? 'Other'),
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              event['name'] ?? 'Event',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                backgroundColor: Colors.blue.shade700,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      // Navigate to edit page
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Budget Overview Card
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Budget Overview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildBudgetItem(
                                    'Total Budget',
                                    '\$${budget.toStringAsFixed(2)}',
                                    Icons.account_balance_wallet,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                Expanded(
                                  child: _buildBudgetItem(
                                    'Spent',
                                    '\$${spent.toStringAsFixed(2)}',
                                    Icons.shopping_cart,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                Expanded(
                                  child: _buildBudgetItem(
                                    'Remaining',
                                    '\$${(budget - spent).toStringAsFixed(2)}',
                                    Icons.savings,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(progress * 100).toInt()}% of budget used',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Event Details Card
                      _buildSectionCard(
                        'Event Details',
                        Icons.info_outline,
                        color,
                        [
                          _buildDetailRow(
                            Icons.calendar_today,
                            'Date',
                            _formatTimestamp(event['date']),
                          ),
                          _buildDetailRow(
                            Icons.location_on,
                            'Venue',
                            event['venue'] ?? 'Not specified',
                          ),
                          _buildDetailRow(
                            Icons.category,
                            'Category',
                            event['category'] ?? 'Other',
                          ),
                          _buildDetailRow(
                            Icons.people,
                            'Expected Attendees',
                            event['attendees']?.toString() ?? 'Not specified',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description Card
                      if (event['description'] != null && event['description'].toString().isNotEmpty)
                        _buildSectionCard(
                          'Description',
                          Icons.description,
                          color,
                          [
                            Text(
                              event['description'],
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Quick Actions
                      _buildSectionCard(
                        'Quick Actions',
                        Icons.flash_on,
                        color,
                        [
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Add Expense',
                                  Icons.add_shopping_cart,
                                  color,
                                      () {
                                    // Navigate to add expense
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  'View Tasks',
                                  Icons.check_circle_outline,
                                  Colors.teal.shade600,
                                      () {
                                    // Navigate to tasks
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Vendors',
                                  Icons.business_center,
                                  Colors.orange.shade600,
                                      () {
                                    // Navigate to vendors
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  'Attendees',
                                  Icons.people,
                                  Colors.purple.shade600,
                                      () {
                                    // Navigate to attendees
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
      String title,
      IconData icon,
      Color color,
      List<Widget> children,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.blue.shade700;
      case 'In Progress':
        return Colors.orange.shade600;
      case 'Completed':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
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

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No Date';
    final date = timestamp.toDate();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
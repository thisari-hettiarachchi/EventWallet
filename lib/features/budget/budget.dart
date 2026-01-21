import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/bottom_nav.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  String _selectedEvent = 'All Events';
  List<String> _events = ['All Events'];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  void _fetchEvents() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('events').get();
    final eventNames =
    snapshot.docs.map((doc) => doc['name'] as String).toList();
    setState(() {
      _events = ['All Events', ...eventNames];
    });
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget Overview',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedEvent,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Colors.blue.shade700),
                              items: _events.map((event) {
                                return DropdownMenuItem(
                                  value: event,
                                  child: Text(
                                    event,
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedEvent = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('expenses')
                          .where(
                        'event',
                        isEqualTo: _selectedEvent == 'All Events'
                            ? null
                            : _selectedEvent,
                      )
                          .snapshots(),
                      builder: (context, snapshot) {
                        double totalBudget = 0;
                        double totalSpent = 0;

                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            totalBudget +=
                                (doc['budget'] ?? 0).toDouble();
                            totalSpent +=
                                (doc['spent'] ?? 0).toDouble();
                          }
                        }

                        double remaining = totalBudget - totalSpent;

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '\$${totalBudget.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    'Spent',
                                    '\$${totalSpent.toStringAsFixed(0)}',
                                    Colors.red.shade300,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color:
                                  Colors.white.withOpacity(0.3),
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    'Remaining',
                                    '\$${remaining.toStringAsFixed(0)}',
                                    Colors.green.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('expenses')
                    .where(
                  'event',
                  isEqualTo: _selectedEvent == 'All Events'
                      ? null
                      : _selectedEvent,
                )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final expenses = snapshot.data!.docs;

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Expenses by Category',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _showAddExpenseDialog(context);
                            },
                            icon: Icon(Icons.add_circle_outline,
                                color: Colors.blue.shade700),
                            label: Text(
                              'Add',
                              style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...expenses.map((doc) {
                        return Padding(
                          padding:
                          const EdgeInsets.only(bottom: 12),
                          child: _buildCategoryCard(
                            doc['category'] ?? 'Other',
                            '\$${(doc['budget'] ?? 0).toStringAsFixed(0)}',
                            '\$${(doc['spent'] ?? 0).toStringAsFixed(0)}',
                            ((doc['spent'] ?? 0) /
                                (doc['budget'] ?? 1))
                                .toDouble(),
                            Colors.blue,
                            Icons.category,
                          ),
                        );
                      }),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      bottomNavigationBar:
      const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildSummaryItem(
      String label, String amount, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.9))),
        const SizedBox(height: 6),
        Text(amount,
            style:
            TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoryCard(String category, String budget,
      String spent, double progress, Color color, IconData icon) {
    return Column();
  }

  void _showAddExpenseDialog(BuildContext context) {}
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage>
    with SingleTickerProviderStateMixin {
  String _selectedEvent = 'All Events';
  List<String> _events = ['All Events'];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  double _totalBudget = 0;
  double _totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _fetchEvents();

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchEvents() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('events').get();
    final eventNames =
    snapshot.docs.map((doc) => doc['eventName'] ?? doc['name'] as String).toList();
    setState(() {
      _events = ['All Events', ...eventNames];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.primaryBlue],
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
                          AppStrings.budgetOverview,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.textLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedEvent,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: AppColors.primaryBlue),
                              items: _events.map((event) {
                                return DropdownMenuItem(
                                  value: event,
                                  child: Text(
                                    event,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
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
                  StreamBuilder<QuerySnapshot>(
                    stream: _selectedEvent == 'All Events'
                        ? FirebaseFirestore.instance
                        .collection('expenses')
                        .snapshots()
                        : FirebaseFirestore.instance
                        .collection('expenses')
                        .where('event', isEqualTo: _selectedEvent)
                        .snapshots(),
                    builder: (context, snapshot) {
                      _totalBudget = 0;
                      _totalSpent = 0;

                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          _totalBudget +=
                              (data['budget'] ?? 0).toDouble();
                          _totalSpent +=
                              (data['spent'] ?? 0).toDouble();
                        }
                      }

                      double remaining = _totalBudget - _totalSpent;
                      double progress = _totalBudget == 0
                          ? 0
                          : (_totalSpent / _totalBudget).clamp(0, 1);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.textLight.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                AppColors.textLight.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      AppStrings.totalBudget,
                                      style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 16),
                                    ),
                                    Text(
                                      _selectedEvent,
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      '\$${_totalSpent.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textLight),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '/ \$${_totalBudget.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor:
                                  AppColors.textLight.withValues(alpha: 0.2),
                                  valueColor:
                                  const AlwaysStoppedAnimation(
                                      AppColors.textLight),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${AppStrings.spent}: \$${_totalSpent.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppColors.textLight),
                                    ),
                                    Text(
                                      '${AppStrings.remaining}: \$${remaining.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppColors.textLight),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _selectedEvent == 'All Events'
                    ? FirebaseFirestore.instance
                    .collection('expenses')
                    .snapshots()
                    : FirebaseFirestore.instance
                    .collection('expenses')
                    .where('event', isEqualTo: _selectedEvent)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final expenses = snapshot.data!.docs;

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: expenses.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildCategoryCard(
                        data['category'] ?? 'Other',
                        '\$${data['budget']}',
                        '\$${data['spent']}',
                        (data['spent'] ?? 0) /
                            ((data['budget'] ?? 1).toDouble()),
                        AppColors.secondary,
                        Icons.category,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addExpense),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildCategoryCard(String category, String budget, String spent,
      double progress, Color color, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(spent, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            Text('of $budget', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text(AppStrings.addExpense),
        content: Text(AppStrings.addExpenseHint),
      ),
    );
  }
}

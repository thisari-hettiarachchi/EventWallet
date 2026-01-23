import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/colors.dart';
import 'add_expense.dart';

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
    snapshot.docs.map((doc) => (doc['eventName'] ?? doc['name']).toString()).toList();
    setState(() {
      _events = ['All Events', ...eventNames];
    });
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
                    ? FirebaseFirestore.instance.collection('events').snapshots()
                    : FirebaseFirestore.instance
                        .collection('events')
                        .where('eventName', isEqualTo: _selectedEvent)
                        .snapshots(),
                builder: (context, snapshot) {
                  double totalBudget = 0;
                  double totalSpent = 0;

                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalBudget += (data['budget'] ?? 0).toDouble();
                      totalSpent += (data['spent'] ?? 0).toDouble();
                    }
                  }

                  double remaining = totalBudget - totalSpent;
                  double progress = totalBudget == 0
                      ? 0
                      : (totalSpent / totalBudget).clamp(0, 1);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
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
                                      color: Colors.white,
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
                                  '\$${totalSpent.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '/ \$${totalBudget.toStringAsFixed(0)}',
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
                              Colors.white.withValues(alpha: 0.2),
                              valueColor:
                              const AlwaysStoppedAnimation(
                                  Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${AppStrings.spent}: \$${totalSpent.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                                Text(
                                  '${AppStrings.remaining}: \$${remaining.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Colors.white),
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
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _selectedEvent == 'All Events'
                        ? FirebaseFirestore.instance
                        .collection('expenses')
                        .orderBy('timestamp', descending: true)
                        .snapshots()
                        : FirebaseFirestore.instance
                        .collection('expenses')
                        .where('event', isEqualTo: _selectedEvent)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final expenses = snapshot.data!.docs;

                      if (expenses.isEmpty) {
                        return const Center(child: Text('No expenses found', style: TextStyle(color: Colors.grey)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final doc = expenses[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildExpenseCard(data);
                        },
                      );
                    },
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
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpensePage()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(AppStrings.addExpense, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_long, color: AppColors.primaryBlue),
        ),
        title: Text(data['title'] ?? 'Expense', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        subtitle: Text(data['category'] ?? 'Other', style: const TextStyle(color: AppColors.textGrey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${(data['amount'] ?? 0).toStringAsFixed(2)}', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 16)),
            Text(data['event'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

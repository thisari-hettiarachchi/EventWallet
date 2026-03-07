import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'add_expense.dart';
import '../../../core/constants/colors.dart';

class ExpensesPage extends StatefulWidget {
  final String eventId;
  final String eventName;

  const ExpensesPage({super.key, required this.eventId, required this.eventName});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient header
          Container(
            height: 280.h,
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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddExpensePage(
                                  eventId: widget.eventId,
                                  eventName: widget.eventName,
                                ),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Padding(
                              padding: EdgeInsets.all(12.r),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Header hero section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 4.h),
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
                          Icons.account_balance_wallet_outlined,
                          size: 48.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        widget.eventName,
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5.w,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'Expenses',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Scrollable content
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('expenses')
                        .where('eventId', isEqualTo: widget.eventId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(fontSize: 14.sp)));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final docs = snapshot.data?.docs.toList() ?? [];
                      docs.sort((a, b) {
                        final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                        final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                        if (aTime == null) return -1;
                        if (bTime == null) return 1;
                        return bTime.compareTo(aTime);
                      });

                      final totalSpent = docs.fold<double>(0, (sum, doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return sum + (data['amount'] ?? 0.0).toDouble();
                      });

                      return ListView(
                        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
                        children: [
                          // Summary card
                          _buildModernCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCardHeader(Icons.trending_up, 'Summary'),
                                SizedBox(height: 20.h),
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('events')
                                      .doc(widget.eventId)
                                      .snapshots(),
                                  builder: (context, eventSnap) {
                                    final budget = eventSnap.hasData && eventSnap.data!.exists
                                        ? ((eventSnap.data!.data() as Map<String, dynamic>)['budget'] ?? 0).toDouble()
                                        : 0.0;
                                    final progress = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
                                    final isOver = totalSpent > budget && budget > 0;

                                    return Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildSummaryItem(
                                                'Total Spent',
                                                '\$${totalSpent.toStringAsFixed(2)}',
                                                Icons.payments_outlined,
                                                AppColors.primaryGreen,
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: _buildSummaryItem(
                                                'Transactions',
                                                '${docs.length}',
                                                Icons.receipt_long_outlined,
                                                AppColors.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (budget > 0) ...[
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
                                                widthFactor: progress,
                                                child: Container(
                                                  height: 20.h,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: isOver
                                                          ? [Colors.orange.shade400, Colors.red.shade400]
                                                          : [const Color(0xFF00897B), const Color(0xFF1565C0)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(10.r),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (isOver ? Colors.orange : const Color(0xFF00897B))
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
                                          SizedBox(height: 10.h),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '\$${totalSpent.toStringAsFixed(2)} spent',
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
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Expenses list header
                          Text(
                            'All Expenses',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          if (docs.isEmpty)
                            _buildEmptyState()
                          else
                            ...docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildExpenseCard(doc.id, data);
                            }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildCardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: Colors.white, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.money_off, size: 48.sp, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
          Text(
            'No expenses yet',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap + to add your first expense',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(String docId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Unnamed Expense';
    final amount = (data['amount'] ?? 0.0).toDouble();
    final category = data['category'] ?? 'Uncategorized';
    final timestamp = data['timestamp'] as Timestamp?;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.receipt, color: AppColors.primaryBlue, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (timestamp != null) ...[
                      SizedBox(width: 8.w),
                      Text(
                        _formatDate(timestamp),
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
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
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              SizedBox(height: 4.h),
              GestureDetector(
                onTap: () => _deleteExpense(docId, amount),
                child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(String docId, double amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Delete Expense', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this expense?', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(fontSize: 14.sp))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 14.sp)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('expenses').doc(docId).delete();
        final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.eventId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(eventRef);
          if (snapshot.exists) {
            final currentSpent = (snapshot.data()?['spent'] ?? 0).toDouble();
            transaction.update(eventRef, {'spent': (currentSpent - amount).clamp(0.0, double.infinity)});
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting expense: $e')),
          );
        }
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      return timestamp;
    } else {
      return 'Invalid Date';
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

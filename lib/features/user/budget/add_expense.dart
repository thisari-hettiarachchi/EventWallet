import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';

class AddExpensePage extends StatefulWidget {
  final String? eventId;
  final String? eventName;

  const AddExpensePage({super.key, this.eventId, this.eventName});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();

  String? _selectedEventId;
  String? _selectedEventName;
  List<DocumentSnapshot> _events = [];

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.eventId;
    _selectedEventName = widget.eventName;
    _fetchEvents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _fetchEvents() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    setState(() {
      _events = snapshot.docs;
      if (_selectedEventId == null && _events.isNotEmpty) {
        final data = _events.first.data() as Map<String, dynamic>;
        _selectedEventId = _events.first.id;
        _selectedEventName = data['eventName'] ?? data['name'];
      }
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('expenses').add({
        'title': _titleController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'category': _categoryController.text.trim(),
        'eventId': _selectedEventId,
        'event': _selectedEventName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (_selectedEventId != null) {
        final eventRef =
            FirebaseFirestore.instance.collection('events').doc(_selectedEventId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(eventRef);
          if (snapshot.exists) {
            final currentSpent = (snapshot.data()?['spent'] ?? 0).toDouble();
            final newAmount = double.parse(_amountController.text.trim());
            transaction.update(eventRef, {'spent': currentSpent + newAmount});
          }
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient header
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
            ),
          ),

          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Add Expense',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // Header hero section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.eventName != null
                            ? 'Expense for ${widget.eventName}'
                            : 'New Expense',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Scrollable form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Expense Details card
                        _buildModernCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCardHeader(Icons.receipt_long, 'Expense Details'),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _titleController,
                                label: 'Title',
                                hint: 'e.g., Catering Deposit',
                                icon: Icons.description,
                                validator: (v) =>
                                    v!.isEmpty ? 'Please enter a title' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _amountController,
                                label: 'Amount',
                                hint: '0.00',
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? 'Please enter an amount' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _categoryController,
                                label: 'Category',
                                hint: 'e.g., Food, Venue, Decor',
                                icon: Icons.category,
                                validator: (v) =>
                                    v!.isEmpty ? 'Please enter a category' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Event Picker card (only when no event passed in)
                        if (widget.eventId == null)
                          _buildModernCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCardHeader(Icons.event, 'Select Event'),
                                const SizedBox(height: 20),
                                _buildEventDropdown(),
                              ],
                            ),
                          ),

                        if (widget.eventId == null) const SizedBox(height: 16),

                        // Save button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _saveExpense,
                              borderRadius: BorderRadius.circular(16),
                              child: const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_circle_outline,
                                        color: Colors.white, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'Add Expense',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
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
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: child,
    );
  }

  Widget _buildCardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        labelStyle: TextStyle(color: AppColors.textGrey),
      ),
    );
  }

  Widget _buildEventDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEventId,
      decoration: InputDecoration(
        labelText: 'Event',
        prefixIcon: const Icon(Icons.event_note, color: AppColors.primaryGreen),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        labelStyle: TextStyle(color: AppColors.textGrey),
      ),
      items: _events.map((e) {
        final data = e.data() as Map<String, dynamic>;
        return DropdownMenuItem(
          value: e.id,
          child: Text(data['eventName'] ?? data['name'] ?? 'Unnamed Event'),
        );
      }).toList(),
      onChanged: (v) {
        setState(() {
          _selectedEventId = v;
          final event = _events.firstWhere((e) => e.id == v);
          final data = event.data() as Map<String, dynamic>;
          _selectedEventName = data['eventName'] ?? data['name'];
        });
      },
      validator: (v) => v == null ? 'Please select an event' : null,
    );
  }
}

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

      // Update event spent amount
      if (_selectedEventId != null) {
        final eventRef = FirebaseFirestore.instance.collection('events').doc(_selectedEventId);
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
          const SnackBar(content: Text('Expense added successfully'), backgroundColor: AppColors.success),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        const Text(
                          'Expense Details',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _titleController,
                          label: 'Title',
                          hint: 'e.g., Catering Deposit',
                          icon: Icons.description,
                          validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _amountController,
                          label: 'Amount',
                          hint: '0.00',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Please enter an amount' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _categoryController,
                          label: 'Category',
                          hint: 'e.g., Food, Venue, Decor',
                          icon: Icons.category,
                          validator: (v) => v!.isEmpty ? 'Please enter a category' : null,
                        ),
                        const SizedBox(height: 16),
                        if (widget.eventId == null) _buildEventPicker(),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _saveExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Add Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Add Expense',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
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
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildEventPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedEventId,
              isExpanded: true,
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
            ),
          ),
        ),
      ],
    );
  }
}

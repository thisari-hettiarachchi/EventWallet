import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';

class EditEventPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EditEventPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _venueController;
  late TextEditingController _budgetController;
  late TextEditingController _attendeesController;
  late TextEditingController _descriptionController;
  late String _selectedStatus;
  late String _selectedCategory;
  late DateTime _selectedDate;

  final List<String> _categories = [
    'Wedding',
    'Birthday',
    'Corporate',
    'Conference',
    'Party',
    'Charity',
    'Other'
  ];

  final List<String> _statuses = ['Upcoming', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.eventData['eventName'] ?? widget.eventData['name'] ?? '');
    _venueController = TextEditingController(text: widget.eventData['venue'] ?? '');
    _budgetController = TextEditingController(text: (widget.eventData['budget'] ?? 0).toString());
    _attendeesController = TextEditingController(text: (widget.eventData['attendees'] ?? widget.eventData['guestCount'] ?? 0).toString());
    _descriptionController = TextEditingController(text: widget.eventData['description'] ?? widget.eventData['notes'] ?? '');
    _selectedStatus = widget.eventData['status'] ?? 'Upcoming';
    _selectedCategory = widget.eventData['category'] ?? 'Other';

    if (widget.eventData['date'] is Timestamp) {
      _selectedDate = (widget.eventData['date'] as Timestamp).toDate();
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _budgetController.dispose();
    _attendeesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('events').doc(widget.eventId).update({
          'eventName': _nameController.text.trim(),
          'name': _nameController.text.trim(),
          'venue': _venueController.text.trim(),
          'budget': double.tryParse(_budgetController.text) ?? 0,
          'attendees': int.tryParse(_attendeesController.text) ?? 0,
          'guestCount': int.tryParse(_attendeesController.text) ?? 0,
          'description': _descriptionController.text.trim(),
          'notes': _descriptionController.text.trim(),
          'status': _selectedStatus,
          'category': _selectedCategory,
          'date': Timestamp.fromDate(_selectedDate),
        });

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .add({
            'title': 'Event Updated',
            'message': 'Your event "${_nameController.text.trim()}" has been updated.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'event',
          });
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating event: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Event Name', _nameController, Icons.event),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTextField('Venue', _venueController, Icons.location_on),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Budget', _budgetController, Icons.attach_money, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Attendees', _attendeesController, Icons.people, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusDropdown(),
              const SizedBox(height: 16),
              _buildTextField('Description', _descriptionController, Icons.description, maxLines: 3, isRequired: false),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _updateEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category, color: Color(0xFF00897B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: const Icon(Icons.info, color: Color(0xFF00897B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (val) => setState(() => _selectedStatus = val!),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF00897B)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
      ),
    );
  }
}
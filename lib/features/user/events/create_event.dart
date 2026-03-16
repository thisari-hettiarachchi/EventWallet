import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../result/result_page.dart';
import 'event.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _venueController = TextEditingController();
  final _budgetController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedCategory = 'Wedding';
  final List<String> _categories = [
    'Wedding',
    'Birthday',
    'Corporate',
    'Conference',
    'Party',
    'Charity',
    'Other'
  ];

  String _selectedStatus = 'Upcoming';
  final List<String> _statusOptions = ['Upcoming', 'In Progress', 'Completed'];

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isCreating = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _venueController.dispose();
    _budgetController.dispose();
    _guestCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00897B),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00897B),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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

  Future<void> _createEvent() async {
    if (_isCreating || !_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              isSuccess: false,
              message: "You must be logged in to create an event.",
              onButtonPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
      return;
    }

    if (_selectedDate == null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              isSuccess: false,
              message: "Please select an event date.",
              onButtonPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final data = {
      'eventName': _eventNameController.text.trim(),
      'name': _eventNameController.text.trim(),
      'venue': _venueController.text.trim(),
      'budget': double.tryParse(_budgetController.text) ?? 0,
      'spent': 0,
      'guestCount': int.tryParse(_guestCountController.text) ?? 0,
      'notes': _notesController.text.trim(),
      'category': _selectedCategory,
      'date': Timestamp.fromDate(_selectedDate!),
      'time': _selectedTime != null ? '${_selectedTime!.hour}:${_selectedTime!.minute}' : null,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'status': _selectedStatus,
    };


    try {
      await _db.collection('events').add(data);

      // Add notification
      await _db.collection('users').doc(user.uid).collection('notifications').add({
        'title': 'Event Created',
        'message': 'Your new event "${_eventNameController.text.trim()}" has been created successfully.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'event',
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EventsPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              isSuccess: false,
              message: "Failed to create event. Please try again.",
              onButtonPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF00897B),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: _isCreating ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Create New Event',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.event_available, color: Colors.white, size: 32.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      'Plan your perfect event with detailed budgeting',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Event Details',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1F36),
              ),
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _eventNameController,
              label: 'Event Name',
              hint: 'e.g., Sarah & John\'s Wedding',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter event name';
                return null;
              },
            ),
            SizedBox(height: 16.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Event Category',
                  labelStyle: TextStyle(fontSize: 14.sp),
                  prefixIcon: Icon(_getCategoryIcon(_selectedCategory), color: const Color(0xFF00897B), size: 24.sp),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(_getCategoryIcon(category), size: 20.sp, color: Colors.grey.shade600),
                        SizedBox(width: 12.w),
                        Text(category, style: TextStyle(fontSize: 14.sp)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'Event Date',
                    value: _selectedDate != null ? _formatDate(_selectedDate!) : 'Select Date',
                    icon: Icons.calendar_today,
                    onTap: () => _selectDate(context),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'Event Time',
                    value: _selectedTime != null ? _selectedTime!.format(context) : 'Select Time',
                    icon: Icons.access_time,
                    onTap: () => _selectTime(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _venueController,
              label: 'Venue',
              hint: 'e.g., Grand Hotel Ballroom',
              icon: Icons.location_on,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter venue';
                return null;
              },
            ),
            SizedBox(height: 24.h),
            Text(
              'Budget & Planning',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1F36),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _budgetController,
                    label: 'Total Budget',
                    hint: '0',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter budget';
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _guestCountController,
                    label: 'Guest Count',
                    hint: '0',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Event Status',
                  labelStyle: TextStyle(fontSize: 14.sp),
                  prefixIcon: Icon(Icons.info, color: const Color(0xFF00897B), size: 24.sp),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status, style: TextStyle(fontSize: 14.sp)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  labelText: 'Additional Notes',
                  labelStyle: TextStyle(fontSize: 14.sp),
                  hintText: 'Add any special requirements or notes...',
                  hintStyle: TextStyle(fontSize: 14.sp),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60.h),
                    child: Icon(Icons.notes, color: const Color(0xFF00897B), size: 24.sp),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.r),
                ),
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isCreating
                      ? [const Color(0xFF00897B).withOpacity(0.7), const Color(0xFF1565C0).withOpacity(0.7)]
                      : [const Color(0xFF00897B), const Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00897B).withOpacity(_isCreating ? 0.18 : 0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isCreating ? null : _createEvent,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isCreating) ...[
                            SizedBox(
                              height: 18.sp,
                              width: 18.sp,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          Text(
                            _isCreating ? 'Creating...' : 'Create Event',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14.sp),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14.sp),
          prefixIcon: Icon(icon, color: const Color(0xFF00897B), size: 24.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF00897B), size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1F36),
                        ),
                      ),
                    ],
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

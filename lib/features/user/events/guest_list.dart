import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/gradient_elevated_button.dart';

class GuestListPage extends StatefulWidget {
  final String eventId;

  const GuestListPage({super.key, required this.eventId});

  @override
  State<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends State<GuestListPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 20.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(35.r),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.eventId)
                        .collection('guests')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading guests: ${snapshot.error}',
                              style: TextStyle(color: Colors.red, fontSize: 14.sp)),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final guests = snapshot.data!.docs;

                      if (guests.isEmpty) {
                        return _buildEmptyState();
                      }

                      return Column(
                        children: [
                          _buildSummary(guests),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              itemCount: guests.length,
                              itemBuilder: (context, index) {
                                final guest = guests[index];
                                final data =
                                    guest.data() as Map<String, dynamic>;
                                return _buildGuestCard(guest.id, data);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGuestDialog(),
        backgroundColor: AppColors.primaryGreen,
        icon: Icon(Icons.person_add, color: Colors.white, size: 24.sp),
        label: Text(
          'Add Guest',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
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
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            'Guest List',
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.w,
            ),
          ),
          Text(
            'Manage your event invitations',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<QueryDocumentSnapshot> guests) {
    int confirmed = 0;
    int pending = 0;
    int declined = 0;

    for (var guest in guests) {
      final status = (guest.data() as Map<String, dynamic>)['status'];
      if (status == 'Confirmed') {
        confirmed++;
      } else if (status == 'Declined') {
        declined++;
      } else {
        pending++;
      }
    }

    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', guests.length.toString(), Colors.blue),
          _buildSummaryItem('Confirmed', confirmed.toString(), Colors.green),
          _buildSummaryItem('Pending', pending.toString(), Colors.orange),
          _buildSummaryItem('Declined', declined.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildGuestCard(String guestId, Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
          radius: 20.r,
          child: Text(
            (data['name'] ?? 'G').isNotEmpty
                ? data['name'][0].toUpperCase()
                : 'G',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ),
        title: Text(
          data['name'] ?? '',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Text(
          data['email'] ?? 'No email',
          style: TextStyle(fontSize: 14.sp),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(guestId);
            } else if (value == 'edit') {
              _showGuestDialog(guestId: guestId, currentData: data);
            } else {
              FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.eventId)
                  .collection('guests')
                  .doc(guestId)
                  .update({'status': value});
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'Pending',
              child: Text('Pending', style: TextStyle(fontSize: 14.sp)),
            ),
            PopupMenuItem(
              value: 'Confirmed',
              child: Text('Confirmed', style: TextStyle(fontSize: 14.sp)),
            ),
            PopupMenuItem(
              value: 'Declined',
              child: Text('Declined', style: TextStyle(fontSize: 14.sp)),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text('Edit', style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Remove',
                    style: TextStyle(color: Colors.red, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: _getStatusColor(data['status']).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              data['status'] ?? 'Pending',
              style: TextStyle(
                color: _getStatusColor(data['status']),
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80.sp,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'No guests added yet',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String guestId) {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Remove Guest',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove this guest?',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('events')
                    .doc(widget.eventId)
                    .collection('guests')
                    .doc(guestId)
                    .delete();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('Failed to remove guest: $e')),
                );
              }
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showGuestDialog({String? guestId, Map<String, dynamic>? currentData}) {
    final parentContext = context;
    final bool isEditing = guestId != null;
    String selectedStatus = currentData?['status'] ?? 'Pending';

    if (isEditing) {
      _nameController.text = currentData?['name'] ?? '';
      _emailController.text = currentData?['email'] ?? '';
    } else {
      _nameController.clear();
      _emailController.clear();
    }

    showDialog(
      context: parentContext,
      barrierDismissible: !_isSaving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            isEditing ? 'Edit Guest' : 'Add Guest',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  style: TextStyle(fontSize: 15.sp),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(fontSize: 14.sp),
                    hintText: 'Enter guest name',
                    hintStyle: TextStyle(fontSize: 14.sp),
                    errorText: _nameController.text.isEmpty && _isSaving ? 'Name is required' : null,
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setDialogState(() {}),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _emailController,
                  style: TextStyle(fontSize: 15.sp),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(fontSize: 14.sp),
                    hintText: 'Enter guest email (optional)',
                    hintStyle: TextStyle(fontSize: 14.sp),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(fontSize: 14.sp),
                  ),
                  items: ['Pending', 'Confirmed', 'Declined'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontSize: 14.sp)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setDialogState(() {
                      selectedStatus = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
            ),
            GradientElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                if (_nameController.text.trim().isNotEmpty) {
                  setDialogState(() => _isSaving = true);
                  final Map<String, dynamic> guestData = {
                    'name': _nameController.text.trim(),
                    'email': _emailController.text.trim(),
                    'status': selectedStatus,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  try {
                    if (isEditing) {
                      await FirebaseFirestore.instance
                          .collection('events')
                          .doc(widget.eventId)
                          .collection('guests')
                          .doc(guestId)
                          .update(guestData);
                    } else {
                      guestData['createdAt'] = FieldValue.serverTimestamp();
                      await FirebaseFirestore.instance
                          .collection('events')
                          .doc(widget.eventId)
                          .collection('guests')
                          .add(guestData);
                    }
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Failed to save guest: $e')),
                    );
                  } finally {
                    if (mounted) setDialogState(() => _isSaving = false);
                  }
                }
              },
              borderRadius: 12.r,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: _isSaving
                  ? SizedBox(
                      height: 18.sp,
                      width: 18.sp,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Update' : 'Add',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

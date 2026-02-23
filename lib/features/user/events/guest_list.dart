import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';

class GuestListPage extends StatefulWidget {
  final String eventId;
  const GuestListPage({super.key, required this.eventId});

  @override
  State<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends State<GuestListPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

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
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.eventId)
                        .collection('guests')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
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
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: guests.length,
                              itemBuilder: (context, index) {
                                final guest = guests[index];
                                final data = guest.data() as Map<String, dynamic>;
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
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Guest',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              'Guest List',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
      if (status == 'Confirmed') confirmed++;
      else if (status == 'Declined') declined++;
      else pending++;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestCard(String guestId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
          child: Text(
            (data['name'] ?? 'G').isNotEmpty ? data['name'][0].toUpperCase() : 'G',
            style: const TextStyle(
                color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(data['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['email'] ?? 'No email'),
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
            const PopupMenuItem(value: 'Pending', child: Text('Pending')),
            const PopupMenuItem(value: 'Confirmed', child: Text('Confirmed')),
            const PopupMenuItem(value: 'Declined', child: Text('Declined')),
            const PopupMenuDivider(),
            const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                )),
            const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.red)),
                  ],
                )),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getStatusColor(data['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data['status'] ?? 'Pending',
              style: TextStyle(
                color: _getStatusColor(data['status']),
                fontSize: 12,
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
          Icon(Icons.people_outline,
              size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No guests added yet',
            style: TextStyle(
                fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String guestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Guest'),
        content: const Text('Are you sure you want to remove this guest?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.eventId)
                  .collection('guests')
                  .doc(guestId)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showGuestDialog({String? guestId, Map<String, dynamic>? currentData}) {
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
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Guest' : 'Add Guest'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter guest name',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter guest email (optional)',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Pending', 'Confirmed', 'Declined'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  final Map<String, dynamic> guestData = {
                    'name': _nameController.text.trim(),
                    'email': _emailController.text.trim(),
                    'status': selectedStatus,
                  };

                  if (isEditing) {
                    FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.eventId)
                        .collection('guests')
                        .doc(guestId)
                        .update(guestData);
                  } else {
                    guestData['createdAt'] = FieldValue.serverTimestamp();
                    FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.eventId)
                        .collection('guests')
                        .add(guestData);
                  }
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen),
              child: Text(isEditing ? 'Update' : 'Add',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
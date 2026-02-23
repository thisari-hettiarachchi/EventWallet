import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';

class ProviderProfilePage extends StatelessWidget {
  final String providerId;
  final Map<String, dynamic> providerData;

  const ProviderProfilePage({
    super.key,
    required this.providerId,
    required this.providerData,
  });

  @override
  Widget build(BuildContext context) {
    final name = providerData['businessName'] ?? providerData['name'] ?? 'Unknown Provider';
    final type = providerData['providerType'] ?? providerData['category'] ?? 'Service';
    final rating = (providerData['rating'] ?? 0.0).toDouble();
    final price = (providerData['price'] ?? 0.0).toDouble();
    final imageUrl = providerData['imageUrl'] ?? '';
    final availability = providerData['availability'] ?? 'Available';
    final description = providerData['description'] ?? 'No description provided.';
    final location = providerData['location'] ?? 'Location not specified';
    final phone = providerData['phone'] ?? 'Not provided';
    final email = providerData['email'] ?? 'Not provided';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, imageUrl, name),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(name, type, rating, price),
                  const SizedBox(height: 25),
                  _buildQuickStats(availability, location),
                  const SizedBox(height: 30),
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 15),
                  _buildContactTile(Icons.phone, phone),
                  _buildContactTile(Icons.email, email),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(context, name),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String imageUrl, String name) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      leading: CircleAvatar(
        backgroundColor: Colors.black26,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl.isNotEmpty
            ? Image.network(imageUrl, fit: BoxFit.cover)
            : Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: const Icon(Icons.business, size: 100, color: Colors.white54),
              ),
      ),
    );
  }

  Widget _buildHeaderInfo(String name, String type, double rating, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  Text(
                    type,
                    style: const TextStyle(fontSize: 16, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (price > 0)
              Text(
                '\$${price.toInt()}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
            const SizedBox(width: 4),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : 'New',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Text('(24 Reviews)', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(String availability, String location) {
    return Row(
      children: [
        _statItem(Icons.calendar_today_rounded, 'Availability', availability),
        const SizedBox(width: 15),
        _statItem(Icons.location_on_rounded, 'Location', location),
      ],
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 20),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 15),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, String providerName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => _handleBooking(context, providerName),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Book Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _handleBooking(BuildContext context, String providerName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book services')),
      );
      return;
    }

    // Show a simple confirmation dialog or date picker
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text('Do you want to request a booking from $providerName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('bookings').add({
          'userId': user.uid,
          'providerId': providerId,
          'providerName': providerName,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'providerData': providerData,
        });

        // Add notification for the user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'title': 'Booking Requested',
          'message': 'Your booking request for $providerName has been sent.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'service',
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request sent successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

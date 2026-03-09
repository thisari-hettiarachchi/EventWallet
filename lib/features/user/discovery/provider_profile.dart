import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../services/booking_service.dart';

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

    // Social Links
    final website = providerData['website'] ?? '';
    final facebook = providerData['facebook'] ?? '';
    final instagram = providerData['instagram'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, imageUrl, name),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(name, type, rating, price),
                  SizedBox(height: 25.h),
                  _buildQuickStats(availability, location),
                  SizedBox(height: 30.h),

                  if (website.isNotEmpty || facebook.isNotEmpty || instagram.isNotEmpty) ...[
                    Text(
                      'Social Media & Links',
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    SizedBox(height: 15.h),
                    _buildSocialLinks(website, facebook, instagram),
                    SizedBox(height: 30.h),
                  ],

                  Text(
                    'About',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700, height: 1.5),
                  ),
                  SizedBox(height: 24.h),
                  _buildServiceOptionsSection(type, price),
                  SizedBox(height: 30.h),
                  Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 15.h),
                  _buildContactTile(Icons.phone, phone, 'tel:$phone'),
                  _buildContactTile(Icons.email, email, 'mailto:$email'),
                  SizedBox(height: 100.h),
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
      expandedHeight: 300.h,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      leading: Padding(
        padding: EdgeInsets.all(8.r),
        child: CircleAvatar(
          backgroundColor: Colors.black26,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(gradient: AppColors.headerGradient),
                  child: Icon(Icons.broken_image, size: 100.sp, color: Colors.white54),
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: Icon(Icons.business, size: 100.sp, color: Colors.white54),
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
                    style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(fontSize: 14.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.w700, letterSpacing: 1.w),
                  ),
                ],
              ),
            ),
            if (price > 0)
              Text(
                '\$${price.toInt()}',
                style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 24.sp),
            SizedBox(width: 4.w),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : 'New',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10.w),
            Text('(24 Reviews)', style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(String availability, String location) {
    return Row(
      children: [
        _statItem(Icons.calendar_today_rounded, 'Availability', availability),
        SizedBox(width: 15.w),
        _statItem(Icons.location_on_rounded, 'Location', location),
      ],
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(15.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10.r, offset: Offset(0, 4.h)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 20.sp),
            SizedBox(height: 8.h),
            Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
            SizedBox(height: 2.h),
            Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks(String website, String facebook, String instagram) {
    return Row(
      children: [
        if (website.isNotEmpty)
          _socialIcon(Icons.language, website, Colors.blue),
        if (facebook.isNotEmpty)
          _socialIcon(Icons.facebook, facebook, const Color(0xFF1877F2)),
        if (instagram.isNotEmpty)
          _socialIcon(Icons.camera_alt, instagram, const Color(0xFFE4405F)),
      ],
    );
  }

  Widget _socialIcon(IconData icon, String url, Color color) {
    return Padding(
      padding: EdgeInsets.only(right: 15.w),
      child: InkWell(
        onTap: () async {
          String finalUrl = url;
          if (!url.startsWith('http')) {
            finalUrl = 'https://$url';
          }
          final Uri uri = Uri.parse(finalUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
      ),
    );
  }

  Widget _buildServiceOptionsSection(String type, double fallbackPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Packages',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        SizedBox(height: 12.h),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('service_providers')
              .doc(providerId)
              .collection('services')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
            }

            final packages = snapshot.data?.docs ?? const [];
            if (packages.isEmpty) {
              return _buildPackageCard(
                title: firstNonEmpty([providerData['businessName'], providerData['name']], fallback: type),
                subtitle: providerData['description']?.toString().trim().isNotEmpty == true
                    ? providerData['description']
                    : 'Standard $type package',
                amount: fallbackPrice,
              );
            }

            return Column(
              children: packages.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildPackageCard(
                    title: firstNonEmpty([data['name']], fallback: 'Service Package'),
                    subtitle: firstNonEmpty([data['description']], fallback: 'Custom package details available on booking'),
                    amount: bookingAmountFrom(data['price']),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPackageCard({
    required String title,
    required String subtitle,
    required double amount,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
          if (amount > 0)
            Text(
              '\$${amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
            ),
        ],
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String value, String url) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () async {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 20.sp),
            ),
            SizedBox(width: 15.w),
            Text(value, style: TextStyle(fontSize: 16.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, String providerName) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20.r, offset: Offset(0, -5.h)),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => _handleBooking(context, providerName),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          child: Text('Book Now', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
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

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        FirebaseFirestore.instance
            .collection('events')
            .where('userId', isEqualTo: user.uid)
            .get(),
        FirebaseFirestore.instance
            .collection('service_providers')
            .doc(providerId)
            .collection('services')
            .get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final eventsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final servicesSnapshot = results[2] as QuerySnapshot<Map<String, dynamic>>;

      final clientData = userDoc.data() ?? <String, dynamic>{};
      final clientName = firstNonEmpty([
        clientData['name'],
        user.displayName,
        user.email?.split('@').first,
      ], fallback: 'Client');
      final clientEmail = firstNonEmpty([clientData['email'], user.email]);
      final clientPhone = firstNonEmpty([clientData['phone']]);

      final eventOptions = eventsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            final eventDate = bookingDateFrom(data['date']);
            if (eventDate == null) return null;
            return _BookingEventOption(
              id: doc.id,
              name: firstNonEmpty([data['eventName'], data['name']], fallback: 'Untitled Event'),
              type: firstNonEmpty([data['category']], fallback: 'Event'),
              location: firstNonEmpty([
                data['venue'],
                data['location'],
              ], fallback: 'Location not specified'),
              date: eventDate,
            );
          })
          .whereType<_BookingEventOption>()
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (eventOptions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create an event first so we can attach the booking details.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final packageOptions = servicesSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return _BookingPackageOption(
              id: doc.id,
              name: firstNonEmpty([data['name']], fallback: 'Service Package'),
              amount: bookingAmountFrom(data['price']),
              description: firstNonEmpty([data['description']]),
            );
          })
          .toList();

      if (packageOptions.isEmpty) {
        packageOptions.add(
          _BookingPackageOption(
            id: 'default',
            name: firstNonEmpty([
              providerData['businessName'],
              providerData['name'],
              providerData['providerType'],
              providerData['category'],
            ], fallback: 'Standard Package'),
            amount: bookingAmountFrom(providerData['price']),
            description: firstNonEmpty([providerData['description']]),
          ),
        );
      }

      if (!context.mounted) return;

      final selection = await _showBookingBottomSheet(
        context,
        providerName: providerName,
        clientName: clientName,
        eventOptions: eventOptions,
        packageOptions: packageOptions,
      );

      if (selection == null) return;

      final providerSummary = {
        'businessName': providerName,
        'providerType': firstNonEmpty([providerData['providerType'], providerData['category']]),
        'location': firstNonEmpty([providerData['location']]),
        'price': bookingAmountFrom(providerData['price']),
      };

      await FirebaseFirestore.instance.collection('bookings').add(
            buildBookingPayload(
              userId: user.uid,
              providerId: providerId,
              providerName: providerName,
              clientName: clientName,
              clientEmail: clientEmail.isEmpty ? null : clientEmail,
              clientPhone: clientPhone.isEmpty ? null : clientPhone,
              eventId: selection.event.id,
              eventName: selection.event.name,
              eventType: selection.event.type,
              eventDate: selection.event.date,
              location: selection.event.location,
              selectedPackage: selection.package.name,
              amount: selection.package.amount,
              providerType: providerSummary['providerType']?.toString(),
              providerLocation: providerSummary['location']?.toString(),
              providerData: providerSummary,
            ),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'Booking Requested',
        'message': 'Your booking request for ${selection.package.name} at $providerName for ${selection.event.name} has been sent.',
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

  Future<_BookingSelection?> _showBookingBottomSheet(
    BuildContext context, {
    required String providerName,
    required String clientName,
    required List<_BookingEventOption> eventOptions,
    required List<_BookingPackageOption> packageOptions,
  }) {
    return showModalBottomSheet<_BookingSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var selectedEvent = eventOptions.first;
        var selectedPackage = packageOptions.first;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: 20.h,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                ),
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book $providerName',
                          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Choose the event and package so both you and the provider see the same booking details.',
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, height: 1.4),
                        ),
                        SizedBox(height: 20.h),
                        _buildSheetLabel('Client'),
                        _buildSummaryChip(clientName),
                        SizedBox(height: 16.h),
                        _buildSheetLabel('Event'),
                        DropdownButtonFormField<String>(
                          initialValue: selectedEvent.id,
                          decoration: _dropdownDecoration(),
                          items: eventOptions
                              .map(
                                (event) => DropdownMenuItem<String>(
                                  value: event.id,
                                  child: Text(
                                    '${event.name} • ${_formatDate(event.date)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() {
                              selectedEvent = eventOptions.firstWhere((event) => event.id == value);
                            });
                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildBookingSummaryTile(Icons.location_on_outlined, 'Location', selectedEvent.location),
                        _buildBookingSummaryTile(Icons.event_outlined, 'Event Type', selectedEvent.type),
                        SizedBox(height: 16.h),
                        _buildSheetLabel('Package'),
                        DropdownButtonFormField<String>(
                          initialValue: selectedPackage.id,
                          decoration: _dropdownDecoration(),
                          items: packageOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option.id,
                                  child: Text(
                                    option.amount > 0
                                        ? '${option.name} • \$${option.amount.toStringAsFixed(0)}'
                                        : option.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() {
                              selectedPackage = packageOptions.firstWhere((option) => option.id == value);
                            });
                          },
                        ),
                        if (selectedPackage.description.isNotEmpty) ...[
                          SizedBox(height: 12.h),
                          _buildBookingSummaryTile(Icons.notes_outlined, 'Package Details', selectedPackage.description),
                        ],
                        SizedBox(height: 12.h),
                        _buildBookingSummaryTile(
                          Icons.payments_outlined,
                          'Amount',
                          selectedPackage.amount > 0
                              ? '\$${selectedPackage.amount.toStringAsFixed(2)}'
                              : 'To be confirmed',
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(
                                  context,
                                  _BookingSelection(event: selectedEvent, package: selectedPackage),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                ),
                                child: const Text('Send Request'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildSummaryChip(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildBookingSummaryTile(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.primaryGreen),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _BookingEventOption {
  final String id;
  final String name;
  final String type;
  final String location;
  final DateTime date;

  const _BookingEventOption({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.date,
  });
}

class _BookingPackageOption {
  final String id;
  final String name;
  final double amount;
  final String description;

  const _BookingPackageOption({
    required this.id,
    required this.name,
    required this.amount,
    required this.description,
  });
}

class _BookingSelection {
  final _BookingEventOption event;
  final _BookingPackageOption package;

  const _BookingSelection({
    required this.event,
    required this.package,
  });
}

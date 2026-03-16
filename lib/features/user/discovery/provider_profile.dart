import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/chat_service.dart';
import '../../chat/booking_chat_thread_page.dart';
import 'event_selection_bottom_sheet.dart';

class ProviderProfilePage extends StatelessWidget {
  const ProviderProfilePage({
    super.key,
    required this.providerId,
    required this.category,
  });

  final String providerId;
  final String category;

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0)}';
  }

  Future<void> _handleBooking(BuildContext context, String providerName, Map<String, dynamic> providerData) async {
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
      final clientPhone = firstNonEmpty([clientData['phone'], '']);

      final List<BookingEventOption> eventOptions = eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        return BookingEventOption(
          id: doc.id,
          name: data['eventName'] ?? data['name'] ?? 'Unnamed Event',
          type: data['category'] ?? 'Event',
          date: bookingDateFrom(data['date']) ?? DateTime.now(),
          location: data['venue'] ?? data['location'] ?? 'Not specified',
        );
      }).toList();

      if (eventOptions.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create an event first to book a service.')),
        );
        return;
      }

      final List<BookingPackageOption> packageOptions = servicesSnapshot.docs.map((doc) {
        final data = doc.data();
        return BookingPackageOption(
          id: doc.id,
          name: data['name'] ?? data['title'] ?? 'Standard Package',
          amount: bookingAmountFrom(data['price']),
          description: data['description'] ?? '',
        );
      }).toList();

      if (packageOptions.isEmpty) {
        packageOptions.add(
          BookingPackageOption(
            id: 'custom',
            name: firstNonEmpty([
              providerData['providerType'],
              providerData['category'],
            ], fallback: 'Standard Package'),
            amount: bookingAmountFrom(providerData['price']),
            description: firstNonEmpty([providerData['description']]),
          ),
        );
      }

      if (!context.mounted) return;

      final selection = await showModalBottomSheet<BookingSelection>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EventSelectionBottomSheet(
          providerName: providerName,
          clientName: clientName,
          eventOptions: eventOptions,
          packageOptions: packageOptions,
        ),
      );

      if (selection == null) return;

      final providerSummary = {
        'businessName': providerName,
        'providerType': firstNonEmpty([
          providerData['providerType'],
          providerData['category'],
        ]),
        'location': firstNonEmpty([providerData['location']]),
        'price': bookingAmountFrom(providerData['price']),
      };

      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
      final bookingPayload = buildBookingPayload(
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
        status: BookingStatuses.pending,
        providerType: providerSummary['providerType']?.toString(),
        providerLocation: providerSummary['location']?.toString(),
        providerData: providerSummary,
      );

      final batch = FirebaseFirestore.instance.batch();
      batch.set(bookingRef, bookingPayload);

      final notificationRef = FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .collection('notifications')
          .doc();

      batch.set(notificationRef, {
        'title': 'New Booking Request',
        'message': '$clientName has requested a booking for ${selection.event.name}.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'booking',
        'relatedId': bookingRef.id,
      });

      await batch.commit();

      await ChatService().ensureThreadExistsForBooking(
        bookingId: bookingRef.id,
        bookingData: bookingPayload,
      );

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

  Future<void> _handleMessage(BuildContext context, String providerName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to message the provider')),
      );
      return;
    }

    try {
      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('providerId', isEqualTo: providerId)
          .limit(1)
          .get();

      if (!context.mounted) return;

      if (bookingSnapshot.docs.isNotEmpty) {
        final bookingId = bookingSnapshot.docs.first.id;
        final bookingData = bookingSnapshot.docs.first.data();
        
        await ChatService().ensureThreadExistsForBooking(
          bookingId: bookingId,
          bookingData: bookingData,
        );

        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingChatThreadPage(
              bookingId: bookingId,
              initialThreadData: bookingData,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please start a booking to message the provider')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final name = data['businessName'] ?? 'Service Provider';
        final type = data['providerType'] ?? category;
        final rating = (data['rating'] ?? 0.0).toDouble();
        final reviews = (data['reviewCount'] ?? 0).toInt();
        final price = (data['price'] ?? 0.0).toDouble();
        final description = data['description'] ?? 'No description available.';
        final location = data['location'] ?? 'Location not specified';
        final imageUrl = data['imageUrl'] ?? '';
        final phone = data['phone'] ?? '';
        final email = data['email'] ?? '';

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(price),
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              Text(
                                'Starting at',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          _buildStatItem(Icons.star, rating.toString(), 'Rating'),
                          _buildDivider(),
                          _buildStatItem(Icons.reviews, reviews.toString(), 'Reviews'),
                          _buildDivider(),
                          _buildStatItem(Icons.location_on, 'Location', location),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: AppColors.textGrey,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildServiceOptionsSection(type, price),
                      SizedBox(height: 30.h),
                      _buildReviewsSection(context, name),
                      SizedBox(height: 30.h),
                      Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
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
          bottomSheet: user != null
              ? StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: user.uid)
                      .where('providerId', isEqualTo: providerId)
                      .snapshots(),
                  builder: (context, bookingSnapshot) {
                    final bookings = bookingSnapshot.data?.docs ?? [];
                    String buttonText = 'Book Now';
                    bool isActionable = true;

                    if (bookings.isNotEmpty) {
                      final pending = bookings.where((b) {
                        final status = b['status']?.toString() ?? '';
                        return BookingStatuses.normalize(status) == BookingStatuses.pending;
                      }).toList();
                      
                      final accepted = bookings.where((b) {
                        final status = b['status']?.toString() ?? '';
                        return BookingStatuses.normalize(status) == BookingStatuses.accepted;
                      }).toList();

                      final completed = bookings.where((b) {
                        final status = b['status']?.toString() ?? '';
                        return BookingStatuses.normalize(status) == BookingStatuses.completed;
                      }).toList();
                      
                      if (completed.isNotEmpty) {
                        buttonText = 'Completed';
                        isActionable = false;
                      } else if (accepted.isNotEmpty) {
                        buttonText = 'Booked';
                        isActionable = false;
                      } else if (pending.isNotEmpty) {
                        buttonText = 'Request Sent';
                        isActionable = false;
                      }
                    }

                    return _buildBottomAction(context, name, buttonText, isActionable, data);
                  },
                )
              : _buildBottomAction(context, name, 'Book Now', true, data),
        );
      },
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
            ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => _placeholderImage())
            : _placeholderImage(),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Icon(Icons.broken_image, size: 100.sp, color: Colors.white54),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 20.sp),
              SizedBox(width: 4.w),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30.h, width: 1.w, color: Colors.grey.shade300);
  }

  Widget _buildContactTile(IconData icon, String value, String url) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(value, style: TextStyle(fontSize: 15.sp)),
        trailing: Icon(Icons.open_in_new, size: 18.sp, color: AppColors.textGrey),
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
    );
  }

  Widget _buildServiceOptionsSection(String type, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Packages & Services',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        SizedBox(height: 15.h),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('service_providers')
              .doc(providerId)
              .collection('services')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _packageCard(type, price, 'Standard service offering');
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final s = doc.data() as Map<String, dynamic>;
                return _packageCard(
                  s['name'] ?? s['title'] ?? 'Package',
                  (s['price'] ?? 0.0).toDouble(),
                  s['description'] ?? '',
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _packageCard(String title, double p, String desc) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
                if (desc.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(desc, style: TextStyle(fontSize: 13.sp, color: AppColors.textGrey), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Text(_formatCurrency(p), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context, String providerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('service_providers')
              .doc(providerId)
              .collection('reviews')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.h), child: Text('No reviews yet.', style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp))));
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final r = doc.data() as Map<String, dynamic>;
                return _reviewTile(r['userName'] ?? 'User', r['rating']?.toDouble() ?? 5.0, r['comment'] ?? '', r['createdAt']);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _reviewTile(String user, double r, String comment, dynamic ts) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(user, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              Row(children: [Icon(Icons.star, color: Colors.amber, size: 14.sp), SizedBox(width: 4.w), Text(r.toString(), style: TextStyle(fontSize: 12.sp))]),
            ],
          ),
          SizedBox(height: 6.h),
          Text(comment, style: TextStyle(fontSize: 13.sp, color: AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, String providerName, String buttonText, bool isActionable, Map<String, dynamic> providerData) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 30.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
            child: IconButton(icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen), onPressed: () => _handleMessage(context, providerName)),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: ElevatedButton(
              onPressed: isActionable ? () => _handleBooking(context, providerName, providerData) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActionable ? AppColors.primaryGreen : Colors.grey.shade400,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(buttonText, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/gradient_elevated_button.dart';
import '../../../services/booking_service.dart';
import '../discovery/discovery.dart';

class EventServicesPage extends StatefulWidget {
  final String eventId;
  final String eventName;

  const EventServicesPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<EventServicesPage> createState() => _EventServicesPageState();
}

class _EventServicesPageState extends State<EventServicesPage> {
  String? _sendingServiceId;

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
                        .collection('selected_services')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.r),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _friendlyLoadError(snapshot.error),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  'Event ID: ${widget.eventId}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final services = (snapshot.data?.docs ?? []).toList()
                        ..sort((a, b) {
                          final aMap = a.data() as Map<String, dynamic>;
                          final bMap = b.data() as Map<String, dynamic>;
                          final aDate = bookingDateFrom(aMap['createdAt']) ??
                              bookingDateFrom(aMap['updatedAt']) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          final bDate = bookingDateFrom(bMap['createdAt']) ??
                              bookingDateFrom(bMap['updatedAt']) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return bDate.compareTo(aDate);
                        });

                      if (services.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(20.r),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final doc = services[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildServiceCard(doc.id, data);
                        },
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
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => DiscoveryPage(
                isEventSaving: true,
                eventId: widget.eventId,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        icon: Icon(Icons.add, color: Colors.white, size: 24.sp),
        label: Text(
          'Add Service',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  String _friendlyLoadError(Object? error) {
    final raw = error?.toString() ?? 'Unknown error';
    if (raw.contains('permission-denied')) {
      return 'Cannot load saved services due to Firestore permission rules.';
    }
    if (raw.contains('failed-precondition')) {
      return 'Cannot load saved services due to missing Firestore query configuration.';
    }
    return 'Cannot load saved services. $raw';
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
            'Event Services',
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.w,
            ),
          ),
          Text(
            widget.eventName,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_business_outlined,
              size: 72.sp,
              color: Colors.grey.withValues(alpha: 0.35),
            ),
            SizedBox(height: 14.h),
            Text(
              'No services added yet',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Add services first, then send booking requests when you are ready.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String serviceId, Map<String, dynamic> data) {
    final providerName = bookingProviderNameFrom(data);
    final packageName = bookingPackageNameFrom(data);
    final providerType = (data['providerType'] ?? 'Service').toString();
    final amount = bookingAmountFrom(data['amount']);
    final bookingId = data['bookingId']?.toString();
    final requestSent = bookingId != null && bookingId.isNotEmpty;
    final isSending = _sendingServiceId == serviceId;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.business_center_outlined,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '$providerType - $packageName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: requestSent
                      ? AppColors.primaryGreen.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  requestSent ? 'Requested' : 'Saved',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color:
                        requestSent ? AppColors.primaryGreen : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text(
                'Rs. ${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
              ),
              const Spacer(),
              if (!requestSent)
                TextButton(
                  onPressed: isSending ? null : () => _removeService(serviceId),
                  child: Text(
                    'Remove',
                    style: TextStyle(fontSize: 13.sp, color: Colors.red),
                  ),
                ),
              SizedBox(width: 8.w),
              GradientElevatedButton(
                onPressed: (requestSent || isSending)
                    ? null
                    : () => _sendBookingRequest(serviceId, data),
                borderRadius: 12.r,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: isSending
                    ? SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        requestSent ? 'Request Sent' : 'Send Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _removeService(String serviceId) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('selected_services')
        .doc(serviceId)
        .delete();
  }

  Future<void> _sendBookingRequest(
    String serviceId,
    Map<String, dynamic> serviceData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send booking requests')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Booking Request'),
        content: Text(
          'Send a booking request for ${serviceData['packageName'] ?? 'this service'} to ${serviceData['providerName'] ?? 'this provider'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _sendingServiceId = serviceId;
    });

    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data() ?? {};
      final providerId = serviceData['providerId']?.toString() ?? '';
      if (providerId.isEmpty) {
        throw Exception('Missing provider information');
      }

      final providerDoc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .get();
      final providerData = providerDoc.data() ?? {};

      final eventDate = bookingDateFrom(
            eventData['date'] ?? eventData['eventDate'] ?? eventData['createdAt'],
          ) ??
          DateTime.now();

      final payload = buildBookingPayload(
        userId: user.uid,
        providerId: providerId,
        providerName: bookingProviderNameFrom(serviceData),
        clientName: user.displayName ?? user.email?.split('@').first ?? 'Client',
        clientEmail: user.email,
        eventId: widget.eventId,
        eventName: (eventData['eventName'] ?? eventData['name'] ?? widget.eventName)
            .toString(),
        eventType: (eventData['category'] ?? eventData['eventType'] ?? 'Event')
            .toString(),
        eventDate: eventDate,
        location: (eventData['venue'] ?? eventData['location'] ?? 'Not specified')
            .toString(),
        selectedPackage: bookingPackageNameFrom(serviceData),
        amount: bookingAmountFrom(serviceData['amount']),
        status: BookingStatuses.pending,
        providerType: (serviceData['providerType'] ?? '').toString(),
        providerLocation: (serviceData['providerLocation'] ?? '').toString(),
        providerData: {
          'businessName':
              providerData['businessName'] ?? bookingProviderNameFrom(serviceData),
          'imageUrl': providerData['imageUrl'] ?? '',
          'category': serviceData['providerType'] ?? providerData['category'] ?? '',
        },
      );

      final bookingRef =
          await FirebaseFirestore.instance.collection('bookings').add(payload);

      await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .collection('notifications')
          .add({
        'title': 'New Booking Request',
        'message':
            'You received a new booking request from ${user.displayName ?? user.email?.split('@').first ?? 'a client'} for ${(eventData['eventName'] ?? eventData['name'] ?? widget.eventName).toString()}',
        'type': 'booking',
        'bookingId': bookingRef.id,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('selected_services')
          .doc(serviceId)
          .update({
        'bookingId': bookingRef.id,
        'requestSentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': BookingStatuses.pending,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingServiceId = null;
        });
      }
    }
  }
}

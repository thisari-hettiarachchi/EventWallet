import 'package:cloud_firestore/cloud_firestore.dart';

class BookingStatuses {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String completed = 'completed';

  static const List<String> acceptedAliases = [accepted, 'confirmed'];
  static const List<String> rejectedAliases = [rejected, 'cancelled'];

  static List<String> aliasesFor(String status) {
    switch (normalize(status)) {
      case accepted:
        return acceptedAliases;
      case rejected:
        return rejectedAliases;
      case completed:
        return [completed];
      case pending:
      default:
        return [pending];
    }
  }

  static String normalize(dynamic status) {
    final value = (status ?? pending).toString().trim().toLowerCase();

    if (acceptedAliases.contains(value)) return accepted;
    if (rejectedAliases.contains(value)) return rejected;
    if (value == completed) return completed;
    return pending;
  }

  static String label(dynamic status) {
    switch (normalize(status)) {
      case accepted:
        return 'Accepted';
      case rejected:
        return 'Rejected';
      case completed:
        return 'Completed';
      case pending:
      default:
        return 'Pending';
    }
  }
}

String firstNonEmpty(Iterable<dynamic> values, {String fallback = ''}) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

double bookingAmountFrom(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(sanitized) ?? 0;
  }
  return 0;
}

DateTime? bookingDateFrom(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

DateTime? bookingEventDateFromMap(Map<String, dynamic> data) {
  return bookingDateFrom(
    data['eventDate'] ?? data['date'] ?? data['timestamp'] ?? data['createdAt'],
  );
}

String bookingEventNameFrom(Map<String, dynamic> data) {
  return firstNonEmpty([
    data['eventName'],
    data['name'],
    data['providerName'],
  ], fallback: 'Event Booking');
}

String bookingClientNameFrom(Map<String, dynamic> data) {
  return firstNonEmpty([
    data['clientName'],
    data['userName'],
  ], fallback: 'Client');
}

String bookingLocationFrom(Map<String, dynamic> data) {
  return firstNonEmpty([
    data['location'],
    data['venue'],
    data['providerLocation'],
  ], fallback: 'Not specified');
}

String bookingPackageNameFrom(Map<String, dynamic> data) {
  return firstNonEmpty([
    data['selectedPackage'],
    data['serviceName'],
    data['packageName'],
    data['providerType'],
  ], fallback: 'Custom Package');
}

Map<String, dynamic> buildBookingPayload({
  required String userId,
  required String providerId,
  required String providerName,
  required String clientName,
  required String eventId,
  required String eventName,
  required String eventType,
  required DateTime eventDate,
  required String location,
  required String selectedPackage,
  required double amount,
  String? clientEmail,
  String? clientPhone,
  String? providerType,
  String? providerLocation,
  Map<String, dynamic>? providerData,
}) {
  return {
    'userId': userId,
    'providerId': providerId,
    'providerName': providerName,
    'clientName': clientName,
    'clientEmail': clientEmail,
    'clientPhone': clientPhone,
    'eventId': eventId,
    'eventName': eventName,
    'eventType': eventType,
    'eventDate': Timestamp.fromDate(eventDate),
    'location': location,
    'selectedPackage': selectedPackage,
    'serviceName': selectedPackage,
    'amount': amount,
    'status': BookingStatuses.pending,
    'providerType': providerType,
    'providerLocation': providerLocation,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'timestamp': FieldValue.serverTimestamp(),
    if (providerData != null) 'providerData': providerData,
  };
}


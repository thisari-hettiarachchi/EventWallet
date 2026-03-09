import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventwallet/services/booking_service.dart';

void main() {
  group('BookingStatuses', () {
    test('normalizes legacy and canonical status aliases', () {
      expect(BookingStatuses.normalize('pending'), BookingStatuses.pending);
      expect(BookingStatuses.normalize('confirmed'), BookingStatuses.accepted);
      expect(BookingStatuses.normalize('accepted'), BookingStatuses.accepted);
      expect(BookingStatuses.normalize('cancelled'), BookingStatuses.rejected);
      expect(BookingStatuses.normalize('rejected'), BookingStatuses.rejected);
      expect(BookingStatuses.normalize('completed'), BookingStatuses.completed);
    });

    test('returns pending for null or unknown statuses', () {
      expect(BookingStatuses.normalize(null), BookingStatuses.pending);
      expect(
        BookingStatuses.normalize('something-else'),
        BookingStatuses.pending,
      );
    });

    test('returns stable display labels', () {
      expect(BookingStatuses.label('confirmed'), 'Accepted');
      expect(BookingStatuses.label('cancelled'), 'Rejected');
    });
  });

  group('booking helpers', () {
    test('parses booking amount from multiple input shapes', () {
      expect(bookingAmountFrom(120), 120);
      expect(bookingAmountFrom(89.5), 89.5);
      expect(bookingAmountFrom(r'$1,250.75'), 1250.75);
      expect(bookingAmountFrom(null), 0);
    });

    test('reads provider name from top-level and nested booking data', () {
      expect(
        bookingProviderNameFrom({'providerName': 'Dream Events'}),
        'Dream Events',
      );
      expect(
        bookingProviderNameFrom({
          'providerData': {'businessName': 'Golden Moments'},
        }),
        'Golden Moments',
      );
      expect(bookingProviderNameFrom({}), 'Service Provider');
    });

    test('detects cancelled bookings and maps display labels', () {
      expect(
        bookingWasCancelled({
          'status': BookingStatuses.rejected,
          'cancelledBy': 'user',
        }),
        isTrue,
      );
      expect(bookingWasCancelled({'status': 'cancelled'}), isTrue);
      expect(
        bookingWasCancelled({
          'status': BookingStatuses.accepted,
          'cancelledBy': 'user',
        }),
        isFalse,
      );
      expect(
        bookingStatusLabelFrom({
          'status': BookingStatuses.rejected,
          'cancelledBy': 'user',
        }),
        'Cancelled',
      );
      expect(
        bookingStatusLabelFrom({
          'status': BookingStatuses.accepted,
          'cancelledBy': 'user',
        }),
        'Accepted',
      );
      expect(
        bookingStatusLabelFrom({'status': BookingStatuses.rejected}),
        'Rejected',
      );
    });

    test('allows users to cancel only active bookings', () {
      expect(
        bookingCanBeCancelledByUser({'status': BookingStatuses.pending}),
        isTrue,
      );
      expect(bookingCanBeCancelledByUser({'status': 'confirmed'}), isTrue);
      expect(
        bookingCanBeCancelledByUser({'status': BookingStatuses.rejected}),
        isFalse,
      );
      expect(
        bookingCanBeCancelledByUser({'status': BookingStatuses.completed}),
        isFalse,
      );
    });

    test('builds a normalized booking payload with required fields', () {
      final eventDate = DateTime(2026, 6, 12);
      final payload = buildBookingPayload(
        userId: 'user-1',
        providerId: 'provider-1',
        providerName: 'Dream Events',
        clientName: 'Jordan Client',
        clientEmail: 'jordan@example.com',
        clientPhone: '123456789',
        eventId: 'event-1',
        eventName: 'Summer Gala',
        eventType: 'Corporate',
        eventDate: eventDate,
        location: 'Accra Conference Center',
        selectedPackage: 'Premium Coverage',
        amount: 450,
        providerType: 'Photography',
        providerLocation: 'Accra',
        providerData: const {'businessName': 'Dream Events'},
      );

      expect(payload['status'], BookingStatuses.pending);
      expect(payload['clientName'], 'Jordan Client');
      expect(payload['eventName'], 'Summer Gala');
      expect(payload['location'], 'Accra Conference Center');
      expect(payload['selectedPackage'], 'Premium Coverage');
      expect(payload['serviceName'], 'Premium Coverage');
      expect(payload['amount'], 450);
      expect(payload['eventDate'], isA<Timestamp>());
      expect((payload['eventDate'] as Timestamp).toDate(), eventDate);
      expect(payload['createdAt'], isA<FieldValue>());
      expect(payload['updatedAt'], isA<FieldValue>());
    });
  });
}

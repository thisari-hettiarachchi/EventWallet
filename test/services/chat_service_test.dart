import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventwallet/services/booking_service.dart';
import 'package:eventwallet/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('booking chat helpers', () {
    test('builds chat thread metadata from booking data', () {
      final metadata = buildBookingChatThreadMetadata(
        bookingId: 'booking-42',
        bookingData: {
          'userId': 'user-1',
          'providerId': 'provider-2',
          'clientName': 'Jordan Client',
          'providerName': 'Dream Events',
          'eventName': 'Sunset Wedding',
          'eventType': 'Wedding',
          'eventDate': Timestamp.fromDate(DateTime(2026, 11, 14)),
          'location': 'Accra',
          'selectedPackage': 'Premium Coverage',
          'status': 'confirmed',
        },
      );

      expect(metadata['bookingId'], 'booking-42');
      expect(metadata['userId'], 'user-1');
      expect(metadata['providerId'], 'provider-2');
      expect(metadata['clientName'], 'Jordan Client');
      expect(metadata['providerName'], 'Dream Events');
      expect(metadata['eventName'], 'Sunset Wedding');
      expect(metadata['selectedPackage'], 'Premium Coverage');
      expect(metadata['bookingStatus'], BookingStatuses.accepted);
      expect(metadata['eventDate'], isA<Timestamp>());
    });

    test('reads unread counts from typed and legacy maps', () {
      expect(
        bookingChatUnreadCountFrom({
          'unreadCounts': {'user-1': 3},
        }, 'user-1'),
        3,
      );
      expect(
        bookingChatUnreadCountFrom({
          'unreadCounts': {'user-1': '5'},
        }, 'user-1'),
        5,
      );
      expect(bookingChatUnreadCountFrom({}, 'user-1'), 0);
    });

    test('returns fallback preview when no last message exists', () {
      expect(
        bookingChatLastMessagePreviewFrom({'lastMessage': '  See you soon  '}),
        'See you soon',
      );
      expect(
        bookingChatLastMessagePreviewFrom({'lastMessage': '   '}),
        'No messages yet. Start the conversation.',
      );
      expect(
        bookingChatLastMessagePreviewFrom({}),
        'No messages yet. Start the conversation.',
      );
    });

    test(
      'resolves message visibility from hasMessages and legacy lastMessage',
      () {
        expect(
          bookingChatHasMessagesFrom({'hasMessages': true, 'lastMessage': ''}),
          isTrue,
        );
        expect(
          bookingChatHasMessagesFrom({
            'hasMessages': false,
            'lastMessage': 'Hi',
          }),
          isFalse,
        );
        expect(
          bookingChatHasMessagesFrom({'lastMessage': '  hello there  '}),
          isTrue,
        );
        expect(bookingChatHasMessagesFrom({}), isFalse);
      },
    );

    test('picks the latest available timestamp for thread sorting', () {
      final createdAt = Timestamp.fromDate(DateTime(2026, 1, 1, 8));
      final updatedAt = Timestamp.fromDate(DateTime(2026, 1, 2, 8));
      final lastMessageAt = Timestamp.fromDate(DateTime(2026, 1, 3, 8));

      expect(
        bookingChatSortDateFrom({
          'createdAt': createdAt,
          'updatedAt': updatedAt,
          'lastMessageAt': lastMessageAt,
        }),
        DateTime(2026, 1, 3, 8),
      );
      expect(
        bookingChatSortDateFrom({
          'createdAt': createdAt,
          'updatedAt': updatedAt,
        }),
        DateTime(2026, 1, 2, 8),
      );
    });

    test('builds a normalized text message payload', () {
      final payload = buildBookingChatMessagePayload(
        bookingId: 'booking-42',
        senderId: 'provider-2',
        recipientId: 'user-1',
        senderName: 'Dream Events',
        text: '  We are all set for tomorrow.  ',
        createdAt: Timestamp.fromDate(DateTime(2026, 3, 9, 12, 30)),
      );

      expect(payload['bookingId'], 'booking-42');
      expect(payload['senderId'], 'provider-2');
      expect(payload['recipientId'], 'user-1');
      expect(payload['senderName'], 'Dream Events');
      expect(payload['text'], 'We are all set for tomorrow.');
      expect(payload['type'], 'text');
      expect(payload['createdAt'], isA<Timestamp>());
    });
  });
}

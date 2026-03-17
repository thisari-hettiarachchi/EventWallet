import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'booking_service.dart';

const String bookingChatsCollection = 'booking_chats';

Map<String, String>? parseInquiryBookingId(String bookingId) {
  if (!bookingId.startsWith('inquiry_')) return null;
  final raw = bookingId.substring('inquiry_'.length);
  final separatorIndex = raw.lastIndexOf('_');
  if (separatorIndex <= 0 || separatorIndex >= raw.length - 1) return null;
  return {
    'userId': raw.substring(0, separatorIndex),
    'providerId': raw.substring(separatorIndex + 1),
  };
}

DateTime? bookingChatDateFrom(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

DateTime bookingChatSortDateFrom(Map<String, dynamic> data) {
  return bookingChatDateFrom(data['lastMessageAt']) ??
      bookingChatDateFrom(data['updatedAt']) ??
      bookingChatDateFrom(data['createdAt']) ??
      bookingEventDateFromMap(data) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

int bookingChatUnreadCountFrom(Map<String, dynamic> data, String userId) {
  final unreadCounts = data['unreadCounts'];
  if (unreadCounts is Map<String, dynamic>) {
    final value = unreadCounts[userId];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
  if (unreadCounts is Map) {
    final value = unreadCounts[userId];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
  return 0;
}

String bookingChatLastMessagePreviewFrom(Map<String, dynamic> data) {
  final lastMessage = data['lastMessage']?.toString().trim() ?? '';
  if (lastMessage.isNotEmpty) return lastMessage;
  return 'No messages yet. Start the conversation.';
}

bool bookingChatHasMessagesFrom(Map<String, dynamic> data) {
  final hasMessages = data['hasMessages'];
  if (hasMessages is bool) return hasMessages;
  final lastMessage = data['lastMessage']?.toString().trim() ?? '';
  return lastMessage.isNotEmpty;
}

String bookingChatCounterpartNameFrom(
  Map<String, dynamic> data,
  String currentUserId,
) {
  if (data['userId'] == currentUserId) {
    return firstNonEmpty([data['providerName']], fallback: 'Service Provider');
  }
  return firstNonEmpty([data['clientName']], fallback: 'Client');
}

String bookingChatCounterpartLabelFrom(
  Map<String, dynamic> data,
  String currentUserId,
) {
  return data['userId'] == currentUserId ? 'Provider' : 'Client';
}

Map<String, dynamic> buildBookingChatThreadMetadata({
  required String bookingId,
  required Map<String, dynamic> bookingData,
}) {
  return {
    'bookingId': bookingId,
    'userId': bookingData['userId']?.toString() ?? '',
    'providerId': bookingData['providerId']?.toString() ?? '',
    'clientName': bookingClientNameFrom(bookingData),
    'providerName': bookingProviderNameFrom(bookingData),
    'eventName': bookingEventNameFrom(bookingData),
    'eventType': firstNonEmpty([bookingData['eventType']], fallback: 'Event'),
    'eventDate': bookingData['eventDate'] ?? bookingData['date'],
    'location': bookingLocationFrom(bookingData),
    'selectedPackage': bookingPackageNameFrom(bookingData),
    'bookingStatus': BookingStatuses.normalize(
      bookingData['status'] ?? bookingData['bookingStatus'],
    ),
  };
}

Map<String, dynamic> buildBookingChatMessagePayload({
  required String bookingId,
  required String senderId,
  required String recipientId,
  required String senderName,
  required String text,
  dynamic createdAt,
}) {
  return {
    'bookingId': bookingId,
    'senderId': senderId,
    'recipientId': recipientId,
    'senderName': senderName,
    'text': text.trim(),
    'type': 'text',
    'createdAt': createdAt,
  };
}

class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _threads =>
      _firestore.collection(bookingChatsCollection);

  DocumentReference<Map<String, dynamic>> threadRef(String bookingId) =>
      _threads.doc(bookingId);

  CollectionReference<Map<String, dynamic>> messagesRef(String bookingId) =>
      threadRef(bookingId).collection('messages');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchThreadsForUser(
    String userId, {
    bool messagedOnly = false,
  }) {
    Query<Map<String, dynamic>> query = _threads.where(
      'userId',
      isEqualTo: userId,
    );
    if (messagedOnly) {
      query = query.where('hasMessages', isEqualTo: true);
    }
    return query.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchThreadsForProvider(
    String providerId, {
    bool messagedOnly = false,
  }) {
    Query<Map<String, dynamic>> query = _threads.where(
      'providerId',
      isEqualTo: providerId,
    );
    if (messagedOnly) {
      query = query.where('hasMessages', isEqualTo: true);
    }
    return query.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchThread(String bookingId) {
    return threadRef(bookingId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String bookingId) {
    return messagesRef(
      bookingId,
    ).orderBy('createdAt', descending: true).snapshots();
  }

  bool _looksLikeThreadMetadata(Map<String, dynamic>? data) {
    if (data == null) return false;
    final userId = data['userId']?.toString().trim() ?? '';
    final providerId = data['providerId']?.toString().trim() ?? '';
    return userId.isNotEmpty && providerId.isNotEmpty;
  }

  Future<Map<String, dynamic>?> _resolveThreadMetadata(
    String bookingId, {
    Map<String, dynamic>? bookingData,
  }) async {
    if (_looksLikeThreadMetadata(bookingData)) {
      return buildBookingChatThreadMetadata(
        bookingId: bookingId,
        bookingData: bookingData!,
      );
    }

    Map<String, dynamic>? resolvedBooking = bookingData;
    if (!_looksLikeThreadMetadata(resolvedBooking)) {
      final bookingSnapshot = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      resolvedBooking = bookingSnapshot.data();
    }

    if (_looksLikeThreadMetadata(resolvedBooking)) {
      return buildBookingChatThreadMetadata(
        bookingId: bookingId,
        bookingData: resolvedBooking!,
      );
    }

    final inquiryData = parseInquiryBookingId(bookingId);
    if (inquiryData == null) return null;

    return {
      'bookingId': bookingId,
      'userId': inquiryData['userId']!,
      'providerId': inquiryData['providerId']!,
      'clientName': bookingData?['clientName']?.toString() ?? '',
      'providerName': bookingData?['providerName']?.toString() ?? '',
      'eventName': bookingData?['eventName']?.toString() ?? 'Inquiry',
      'eventType': bookingData?['eventType']?.toString() ?? 'Inquiry',
      'eventDate': bookingData?['eventDate'],
      'location': bookingData?['location']?.toString() ?? '',
      'selectedPackage': bookingData?['selectedPackage']?.toString() ?? '',
      'bookingStatus': BookingStatuses.inquiry,
    };
  }

  Future<void> ensureThreadExistsForBooking({
    required String bookingId,
    Map<String, dynamic>? bookingData,
  }) async {
    try {
      final metadata = await _resolveThreadMetadata(
        bookingId,
        bookingData: bookingData,
      );
      if (metadata == null) return;

      final userId = metadata['userId']?.toString().trim() ?? '';
      final providerId = metadata['providerId']?.toString().trim() ?? '';

      if (userId.isEmpty || providerId.isEmpty) return;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(threadRef(bookingId));

        if (!snapshot.exists) {
          transaction.set(threadRef(bookingId), {
            ...metadata,
            'hasMessages': false,
            'lastMessage': '',
            'lastMessageSenderId': '',
            'lastMessageSenderName': '',
            'unreadCounts': {userId: 0, providerId: 0},
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
        }

        final existingData = snapshot.data() ?? <String, dynamic>{};
        final unreadCounts = <String, dynamic>{
          userId: bookingChatUnreadCountFrom(existingData, userId),
          providerId: bookingChatUnreadCountFrom(existingData, providerId),
        };

        transaction.set(threadRef(bookingId), {
          ...metadata,
          'hasMessages': bookingChatHasMessagesFrom(existingData),
          'unreadCounts': unreadCounts,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('ChatService: ensureThreadExistsForBooking error: $e');
    }
  }

  Future<void> syncThreadMetadataForBooking(String bookingId) async {
    await ensureThreadExistsForBooking(bookingId: bookingId);
  }

  Future<void> ensureThreadsForRole({
    required String currentUserId,
    required bool isProviderView,
  }) async {
    try {
      final bookingSnapshot = await _firestore
          .collection('bookings')
          .where(
            isProviderView ? 'providerId' : 'userId',
            isEqualTo: currentUserId,
          )
          .get();

      for (final doc in bookingSnapshot.docs) {
        await ensureThreadExistsForBooking(
          bookingId: doc.id,
          bookingData: doc.data(),
        );
      }
    } catch (e) {
      debugPrint('ChatService: ensureThreadsForRole error: $e');
    }
  }

  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String recipientId,
    required String senderName,
    required String text,
    Map<String, dynamic>? bookingData,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Ensure thread exists before updating it
    await ensureThreadExistsForBooking(
      bookingId: bookingId,
      bookingData: bookingData,
    );

    final messageRef = messagesRef(bookingId).doc();
    final messagePayload = buildBookingChatMessagePayload(
      bookingId: bookingId,
      senderId: senderId,
      recipientId: recipientId,
      senderName: senderName,
      text: trimmed,
      createdAt: FieldValue.serverTimestamp(),
    );

    try {
      final batch = _firestore.batch();
      batch.set(messageRef, messagePayload);
      batch.update(threadRef(bookingId), {
        'hasMessages': true,
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'lastMessageSenderName': senderName,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts.$recipientId': FieldValue.increment(1),
        'unreadCounts.$senderId': 0,
      });
      await batch.commit();
    } catch (e) {
      debugPrint('ChatService: sendMessage fallback triggered: $e');

      final metadata =
          await _resolveThreadMetadata(bookingId, bookingData: bookingData) ??
          <String, dynamic>{};

      final batch = _firestore.batch();
      batch.set(messageRef, messagePayload);
      batch.set(threadRef(bookingId), {
        ...metadata,
        'hasMessages': true,
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'lastMessageSenderName': senderName,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': {recipientId: FieldValue.increment(1), senderId: 0},
      }, SetOptions(merge: true));
      await batch.commit();
    }
  }

  Future<void> markThreadRead({
    required String bookingId,
    required String currentUserId,
  }) async {
    try {
      await threadRef(bookingId).update({
        'unreadCounts.$currentUserId': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Doc might not exist yet
    }
  }
}

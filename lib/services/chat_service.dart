import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_service.dart';

const String bookingChatsCollection = 'booking_chats';

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
    'bookingStatus': BookingStatuses.normalize(bookingData['status']),
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
    String userId,
  ) {
    return _threads.where('userId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchThreadsForProvider(
    String providerId,
  ) {
    return _threads.where('providerId', isEqualTo: providerId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchThread(String bookingId) {
    return threadRef(bookingId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String bookingId) {
    // Ordering by createdAt helps maintain message sequence
    return messagesRef(bookingId).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> ensureThreadExistsForBooking({
    required String bookingId,
    Map<String, dynamic>? bookingData,
  }) async {
    try {
      final resolvedBooking =
          bookingData ??
          (await _firestore.collection('bookings').doc(bookingId).get()).data();

      if (resolvedBooking == null) {
        return;
      }

      final metadata = buildBookingChatThreadMetadata(
        bookingId: bookingId,
        bookingData: resolvedBooking,
      );
      final userId = metadata['userId']?.toString() ?? '';
      final providerId = metadata['providerId']?.toString() ?? '';

      if (userId.isEmpty || providerId.isEmpty) return;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(threadRef(bookingId));

        if (!snapshot.exists) {
          transaction.set(threadRef(bookingId), {
            ...metadata,
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
        final existingUnread = existingData['unreadCounts'];
        final unreadCounts = <String, dynamic>{
          userId: bookingChatUnreadCountFrom(existingData, userId),
          providerId: bookingChatUnreadCountFrom(existingData, providerId),
        };

        if (existingUnread is Map) {
          for (final entry in existingUnread.entries) {
            unreadCounts.putIfAbsent(entry.key.toString(), () => entry.value);
          }
        }

        transaction.set(threadRef(bookingId), {
          ...metadata,
          'unreadCounts': unreadCounts,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      print('ChatService: ensureThreadExistsForBooking error: $e');
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
      print('ChatService: ensureThreadsForRole error: $e');
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
      print('ChatService: sendMessage error (retrying with set): $e');
      // If update fails, fallback to set merge
      final batch = _firestore.batch();
      batch.set(messageRef, messagePayload);
      batch.set(threadRef(bookingId), {
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'lastMessageSenderName': senderName,
        'updatedAt': FieldValue.serverTimestamp(),
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
      // If update fails, document might not exist, but we don't want to crash
    }
  }
}

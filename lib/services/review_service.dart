import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  ReviewService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _reviewsRef(String providerId) {
    return _firestore
        .collection('service_providers')
        .doc(providerId)
        .collection('reviews');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderReviews(
    String providerId,
  ) {
    return _reviewsRef(providerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> submitReview({
    required String bookingId,
    required String providerId,
    required String providerName,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be logged in to submit a review.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final userName = [
      userData['name'],
      user.displayName,
      user.email?.split('@').first,
    ].whereType<String>().map((e) => e.trim()).firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => 'User',
        );

    final reviewsSnapshot = await _reviewsRef(providerId).get();
    final existingRatings = reviewsSnapshot.docs
        .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0)
        .where((value) => value > 0)
        .toList();

    final updatedCount = existingRatings.length + 1;
    final updatedAverage =
        ((existingRatings.fold<double>(0, (sum, value) => sum + value) + rating) /
                updatedCount)
            .clamp(0, 5)
            .toDouble();

    final reviewRef = _reviewsRef(providerId).doc();
    final providerRef = _firestore.collection('service_providers').doc(providerId);
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final notificationRef = providerRef.collection('notifications').doc();

    final batch = _firestore.batch();
    batch.set(reviewRef, {
      'bookingId': bookingId,
      'providerId': providerId,
      'providerName': providerName,
      'userId': user.uid,
      'userName': userName,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(providerRef, {
      'rating': updatedAverage,
      'reviewCount': updatedCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(bookingRef, {
      'isReviewed': true,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Notify provider
    batch.set(notificationRef, {
      'title': 'New Review Received',
      'message': '$userName gave you a $rating star review: "${comment.length > 50 ? comment.substring(0, 47) + '...' : comment}"',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'review',
      'relatedId': bookingId,
    });

    await batch.commit();
  }
}

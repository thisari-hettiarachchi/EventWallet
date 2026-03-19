import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add a new event
  Future<void> addEvent(Map<String, dynamic> data) async {
    await _db.collection('events').add(data);
  }

  /// Get stream of all events, ordered by date
  Stream<QuerySnapshot> getEventsStream() {
    return _db.collection('events').orderBy('date').snapshots();
  }

  /// Optional: Get a single event by ID
  Future<DocumentSnapshot> getEventById(String id) async {
    return await _db.collection('events').doc(id).get();
  }

  /// Optional: Update an event
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _db.collection('events').doc(id).update(data);
  }

  /// Optional: Delete an event
  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }
}


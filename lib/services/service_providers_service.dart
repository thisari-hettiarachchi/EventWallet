import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProvidersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _serviceProviders =>
      _firestore.collection('service_providers');

  // 🔹 Add new service provider
  Future<void> addServiceProvider({
    required String name,
    required String category,
    required String description,
    required double price,
    required String location,
    String? imageUrl,
  }) async {
    await _serviceProviders.add({
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'location': location,
      'imageUrl': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔹 Get ALL service providers
  Stream<QuerySnapshot> getAllServiceProviders() {
    return _serviceProviders.snapshots();
  }

  // 🔹 Get service providers by CATEGORY
  Stream<QuerySnapshot> getServicesByCategory(String category) {
    return _serviceProviders.where('category', isEqualTo: category).snapshots();
  }

  // 🔹 Update service provider
  Future<void> updateServiceProvider(
    String docId, {
    required Map<String, dynamic> data,
  }) async {
    await _serviceProviders.doc(docId).update(data);
  }

  // 🔹 Delete service provider
  Future<void> deleteServiceProvider(String docId) async {
    await _serviceProviders.doc(docId).delete();
  }
}

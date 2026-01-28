import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProviderAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SERVICE PROVIDER SIGN UP
  Future<User?> signUpServiceProvider(
      String email,
      String password,
      String businessName,
      String providerType,
      ) async {
    UserCredential userCredential =
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    if (user != null) {
      await user.updateDisplayName(businessName);

      await _firestore
          .collection('service_providers')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'businessName': businessName,
        'email': email,
        'providerType': providerType,
        'role': 'service_provider',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  // SERVICE PROVIDER LOGIN
  Future<User?> loginServiceProvider(
      String email, String password) async {
    UserCredential userCredential =
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return userCredential.user;
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
<<<<<<< Updated upstream
}
=======
}
>>>>>>> Stashed changes

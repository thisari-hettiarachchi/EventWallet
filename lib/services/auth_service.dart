import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SIGN UP
  Future<User?> signUp(String email, String password, String name) async {
    UserCredential userCredential =
    await _auth.createUserWithEmailAndPassword(email: email, password: password);

    User? user = userCredential.user;

    if (user != null) {
      await user.updateDisplayName(name);

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  // LOGIN
  Future<User?> login(String email, String password) async {
    UserCredential userCredential =
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}

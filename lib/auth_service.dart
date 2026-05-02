import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  bool isValid13(DateTime dob) {
    final now = DateTime.now();
    return now.year - dob.year >= 13;
  }

  Future<void> signup({
    required String firstName,
    required String lastName,
    required DateTime dob,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection("users").doc(cred.user!.uid).set({
      "firstName": firstName,
      "lastName": lastName,
      "dob": dob.toString().split(" ")[0],
      "email": email,
    });
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<Map<String, dynamic>> getProfile(String uid) async {
    try {
      final doc = await _db.collection("users").doc(uid).get();
      if (!doc.exists || doc.data() == null) return {};
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String> getFullName(String uid) async {
    try {
      final doc = await _db.collection("users").doc(uid).get();
      if (!doc.exists || doc.data() == null) return '';
      final data = doc.data() as Map<String, dynamic>;
      return "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
    } catch (e) {
      return '';
    }
  }
}
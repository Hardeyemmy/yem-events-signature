import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  // ban user
  Future<void> banUser(String userId, String reason) {
    return _firestore.collection('users').doc(userId).update({
      'isBanned': true,
      'banReason': reason,
      'banAt': FieldValue.serverTimestamp(),
    });
  }

  //unban user
  Future<void> unbanUser(String userId) {
    return _firestore.collection('users').doc(userId).update({
      'isBanned': false,
      'banReason': null,
      'banAt': null,
    });
  }

  //send announcements to all users via notification announcement

  Future<void> sendAnnoucement(String title, String message) {
    return _firestore.collection('announcements').add({
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'sentBy': FirebaseAuth.instance.currentUser?.uid,
    });
  }
}

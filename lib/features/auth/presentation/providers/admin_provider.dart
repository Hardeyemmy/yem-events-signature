import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

// check if the current user is an admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  print('🔵 isAdminProvider — user uid: ${user?.uid}');
  if (user == null) {
    print('🔴 isAdminProvider — no user');
    return false;
  }

  final doc = await FirebaseFirestore.instance
      .collection('admins')
      .doc(user.uid)
      .get();
  print('🔵 isAdminProvider — doc exists: ${doc.exists}');
  return doc.exists;
});

//Stream all users
final allUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      );
});

//stream all events for admin view
final allEventsAdminProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('events')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      );
});

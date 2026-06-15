import 'package:cloud_firestore/cloud_firestore.dart';

class Attendee {
  final String userId;
  final String userEmail;
  final DateTime joinedAt;

  Attendee({
    required this.userId,
    required this.userEmail,
    required this.joinedAt,
  });

  factory Attendee.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Attendee(
      userId: doc.id,
      userEmail: data['userEmail'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String creatorId;
  final String creatorEmail;
  final String creatorName;
  final DateTime createdAt;
  final String? imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.creatorId,
    required this.creatorEmail,
    required this.creatorName,
    required this.createdAt,
    this.imageUrl,
  });

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      creatorId: data['creatorId'] ?? '',
      creatorEmail: data['creatorEmail'] ?? '',
      creatorName: data['creatorName'] ?? data['creatorEmail'] ?? 'Anonymous',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'creatorId': creatorId,
      'creatorEmail': creatorEmail,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
    };
  }
}

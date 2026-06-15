import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../events/domains/models/events.dart';
import '../../../events/domains/models/atendee.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(FirebaseFirestore.instance);
});

class EventRepository {
  EventRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventRef =>
      _firestore.collection('events');

  Future<void> createEvent(Event event) {
    return _eventRef.add(event.toFirestore());
  }

  Stream<List<Event>> watchAllEvents() {
    return _eventRef
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Event.fromFirestore).toList());
  }

  Stream<Event> watchEvent(String eventId) {
    return _eventRef.doc(eventId).snapshots().map(Event.fromFirestore);
  }

  Stream<bool> isAttending(String eventId, String userId) {
    return _eventRef
        .doc(eventId)
        .collection('attendees')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> rsvpToEvent(String eventId, String userId, String email) {
    return _eventRef.doc(eventId).collection('attendees').doc(userId).set({
      'userId': userId,
      'email': email,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelRsvp(String eventId, String userId) {
    return _eventRef.doc(eventId).collection('attendees').doc(userId).delete();
  }

  Stream<int> attendeesCount(String eventId) {
    return _eventRef
        .doc(eventId)
        .collection('attendees')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Attendee>> watchAttendees(String eventId) {
    return _eventRef
        .doc(eventId)
        .collection('attendees')
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Attendee.fromFirestore).toList());
  }
}

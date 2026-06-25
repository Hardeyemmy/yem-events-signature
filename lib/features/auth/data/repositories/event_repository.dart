import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../events/domains/models/events.dart';
import '../../../events/domains/models/atendee.dart';
import '../../../events/domains/models/event_filter.dart';

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

  Future<void> toggleRsvp(
    String eventId,
    String userId,
    String email,
    String? displayName, // <-- Add this param
  ) async {
    final attendeeRef = _eventRef
        .doc(eventId)
        .collection('attendees')
        .doc(userId);
    final attendeeDoc = await attendeeRef.get();

    if (attendeeDoc.exists) {
      await attendeeRef.delete();
    } else {
      await attendeeRef.set({
        'userEmail': email,
        'displayName': displayName?.isNotEmpty == true
            ? displayName
            : email.split('@')[0],
        'joinedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Also update rsvpToEvent to match
  Future<void> rsvpToEvent(
    String eventId,
    String userId,
    String email,
    String? displayName,
  ) {
    return _eventRef.doc(eventId).collection('attendees').doc(userId).set({
      'userId': userId,
      'userEmail': email,
      'displayName': displayName?.isNotEmpty == true
          ? displayName
          : email.split('@')[0],
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

  Future<void> updateEvent(String eventId, Event event) {
    return _eventRef.doc(eventId).update(event.toFirestore());
  }

  Future<void> deleteEvent(String eventId) async {
    final batch = _firestore.batch();
    final attendees = await _eventRef
        .doc(eventId)
        .collection('attendees')
        .get();
    for (var doc in attendees.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_eventRef.doc(eventId));
    return batch.commit();
  }

  Stream<List<Event>> watchfilteredEvents(EventFilter filter) {
    Query<Map<String, dynamic>> query = _firestore.collection('events');

    if (filter.location != null && filter.location!.isNotEmpty) {
      query = query.where(
        'location',
        isGreaterThanOrEqualTo: filter.location,
        isLessThan: '${filter.location}z',
      );
    }

    if (filter.startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!),
      );
    }

    if (filter.endDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!),
      );
    }

    query = query.orderBy('date', descending: false);

    return query.snapshots().map((snapshot) {
      var events = snapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .toList();

      if (filter.keyword != null && filter.keyword!.isNotEmpty) {
        final keywordLower = filter.keyword!.toLowerCase();
        events = events
            .where(
              (e) =>
                  e.title.toLowerCase().contains(keywordLower) ||
                  e.description.toLowerCase().contains(keywordLower),
            )
            .toList();
      }
      return events;
    });
  }
}

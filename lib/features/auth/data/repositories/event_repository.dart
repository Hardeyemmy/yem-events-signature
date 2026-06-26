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
    String? displayName,
  ) async {
    final attendeeRef = _eventRef
        .doc(eventId)
        .collection('attendees')
        .doc(userId);
    final attendeeDoc = await attendeeRef.get();

    if (attendeeDoc.exists) {
      // ✅ Cancel RSVP — just delete attendee, no notification needed
      await attendeeRef.delete();
    } else {
      // ✅ New RSVP — use batch to write attendee + notification atomically
      final batch = _firestore.batch();

      // Step 1 — Add attendee
      batch.set(attendeeRef, {
        'userId': userId,
        'userEmail': email,
        'displayName': displayName?.isNotEmpty == true
            ? displayName
            : email.split('@')[0],
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Step 2 — Fetch event to get creatorId and title
      final eventDoc = await _eventRef.doc(eventId).get();
      final eventData = eventDoc.data();

      if (eventData != null) {
        final creatorId = eventData['creatorId'] as String?;
        final eventTitle = eventData['title'] as String?;

        // Step 3 — Write notification only if RSVP user is not the creator
        if (creatorId != null && creatorId != userId) {
          final notifRef = _firestore.collection('notifications').doc();
          batch.set(notifRef, {
            'type': 'rsvp',
            'creatorId': creatorId,
            'eventId': eventId,
            'eventTitle': eventTitle ?? 'an event',
            'rsvpUserName': displayName?.isNotEmpty == true
                ? displayName
                : email.split('@')[0],
            'rsvpUserId': userId,
            'sent': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Step 4 — Commit both writes atomically
      await batch.commit();
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

  Stream<List<Event>> watchFilteredEvents(EventFilter filter) {
    Query<Map<String, dynamic>> query = _firestore.collection('events');

    // Only apply date filters at Firestore level
    // (keyword/location filtered client-side for flexibility)
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

      // ✅ Keyword searches title, description AND location
      if (filter.keyword != null && filter.keyword!.isNotEmpty) {
        final keywordLower = filter.keyword!.toLowerCase();
        events = events
            .where(
              (e) =>
                  e.title.toLowerCase().contains(keywordLower) ||
                  e.description.toLowerCase().contains(keywordLower) ||
                  e.location.toLowerCase().contains(keywordLower),
            )
            .toList();
      }

      return events;
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../events/domains/models/events.dart';

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
}

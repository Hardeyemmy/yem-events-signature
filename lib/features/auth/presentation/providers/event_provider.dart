import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/event_repository.dart';
import '../../../events/domains/models/events.dart';
import '../../../events/domains/models/atendee.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(FirebaseFirestore.instance);
});

final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAllEvents();
});

final createEventControllerProvider =
    AsyncNotifierProvider.autoDispose<CreateEventController, void>(
      CreateEventController.new,
    );

class CreateEventController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}
  Future<void> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime date,
    String? imageUrl,
  }) async {
    state = const AsyncValue<void>.loading();
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError('Not logged in', StackTrace.current);
      return;
    }

    final event = Event(
      id: '', // Firestore generates
      title: title,
      description: description,
      location: location,
      date: date,
      creatorId: user.uid,
      creatorEmail: user.email ?? '',
      creatorName:
          user.displayName ??
          user.email?.split('@')[0] ??
          'Anonymous', // <-- Add this
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
    );

    state = await AsyncValue.guard(
      () => ref.read(eventRepositoryProvider).createEvent(event),
    );
  }
}

final eventDetailsProvider = StreamProvider.family<Event, String>((
  ref,
  eventId,
) {
  return ref.watch(eventRepositoryProvider).watchEvent(eventId);
});

final isAttendingProvider = StreamProvider.family<bool, String>((ref, eventId) {
  final user = ref.watch(
    currentUserProvider,
  ); // use watch so it rebuilds on login/logout
  if (user == null) return Stream.value(false);
  return ref.watch(eventRepositoryProvider).isAttending(eventId, user.uid);
});

final attendeeCountProvider = StreamProvider.family<int, String>((
  ref,
  eventId,
) {
  return ref.watch(eventRepositoryProvider).attendeesCount(eventId);
});

final attendeesProvider = StreamProvider.family<List<Attendee>, String>((
  ref,
  eventId,
) {
  return ref.watch(eventRepositoryProvider).watchAttendees(eventId);
});

final rsvpControllerProvider =
    AsyncNotifierProvider.autoDispose<RsvpController, void>(RsvpController.new);

class RsvpController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> toggleRsvp(String eventId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue<void>.loading();
    final repo = ref.read(eventRepositoryProvider);
    final isCurrentlyAttending = await ref.read(
      isAttendingProvider(eventId).future,
    );

    state = await AsyncValue.guard(() async {
      if (isCurrentlyAttending) {
        await repo.cancelRsvp(eventId, user.uid);
      } else {
        // Pass displayName here
        await repo.rsvpToEvent(
          eventId,
          user.uid,
          user.email ?? 'Unknown',
          user.displayName, // <-- Add this
        ); // Fixed missing semicolon
      }
    });
  }
}

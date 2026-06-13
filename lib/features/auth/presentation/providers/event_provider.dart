import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/event_repository.dart';
import '../../../events/domains/models/events.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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
      createdAt: DateTime.now(),
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
  final user = ref.read(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(eventRepositoryProvider).isAttending(eventId, user.uid);
});

final attendeeCountProvider = StreamProvider.family<int, String>((
  ref,
  eventId,
) {
  return ref.watch(eventRepositoryProvider).attendeesCount(eventId);
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
        await repo.rsvpToEvent(eventId, user.uid, user.email ?? '');
      }
    });
  }
}

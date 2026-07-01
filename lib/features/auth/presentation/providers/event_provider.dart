import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/event_repository.dart';
import '../../../events/domains/models/events.dart';
import '../../../events/domains/models/atendee.dart';
import '../../../events/domains/models/event_filter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/email_service.dart';

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
      id: '',
      title: title,
      description: description,
      location: location,
      date: date,
      creatorId: user.uid,
      creatorEmail: user.email ?? '',
      creatorName: user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous',
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
  final user = ref.watch(currentUserProvider);
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

final rsvpControllerProvider = AsyncNotifierProvider<RsvpController, void>(
  RsvpController.new,
);

class RsvpController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}

  Future<void> toggleRsvp(String eventId) async {
    print('🔄 toggleRsvp called for eventId: $eventId');
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue<void>.loading();
    final repo = ref.read(eventRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repo.toggleRsvp(
        eventId,
        user.uid,
        user.email ?? 'Unknown',
        user.displayName,
      );

      // ✅ Send emails after successful RSVP
      final event = await ref.read(eventDetailsProvider(eventId).future);
      final dateFormat = DateFormat('MMMM d, y - h:mm a');

      // Email to attendee
      await EmailService().sendRsvpConfirmationEmail(
        attendeeEmail: user.email ?? '',
        attendeeName: user.displayName ?? user.email?.split('@')[0] ?? 'there',
        eventTitle: event.title,
        eventDate: dateFormat.format(event.date),
        eventLocation: event.location,
      );

      // Email to creator
      final attendeeCount = await ref.read(
        attendeeCountProvider(eventId).future,
      );
      await EmailService().sendCreatorNotificationEmail(
        creatorEmail: event.creatorEmail,
        creatorName: event.creatorName,
        attendeeName:
            user.displayName ?? user.email?.split('@')[0] ?? 'Someone',
        eventTitle: event.title,
        attendeeCount: attendeeCount,
      );

      // Push notification (existing logic)
      await NotificationService().sendRsvpNotification(
        creatorId: event.creatorId,
        eventTitle: event.title,
        rsvpUserName: user.displayName ?? user.email ?? 'Someone',
        eventId: eventId,
      );
    });
  }
}

final editEventControllerProvider = AsyncNotifierProvider.autoDispose
    .family<EditEventController, void, String>(EditEventController.new);

class EditEventController extends AsyncNotifier<void> {
  EditEventController(this._eventId);
  final String _eventId;

  @override
  FutureOr<void> build() async {}

  Future<void> updateEvent({
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

    final existingEvent = await ref.read(eventDetailsProvider(_eventId).future);

    if (existingEvent.creatorId != user.uid) {
      state = AsyncError(
        'Only the event creator can edit this event',
        StackTrace.current,
      );
      return;
    }

    final updatedEvent = Event(
      id: _eventId,
      title: title,
      description: description,
      location: location,
      date: date,
      creatorId: existingEvent.creatorId,
      creatorEmail: existingEvent.creatorEmail,
      creatorName: existingEvent.creatorName,
      createdAt: existingEvent.createdAt,
      imageUrl: imageUrl == null
          ? existingEvent.imageUrl
          : imageUrl.isEmpty
          ? null
          : imageUrl,
    );

    state = await AsyncValue.guard(
      () =>
          ref.read(eventRepositoryProvider).updateEvent(_eventId, updatedEvent),
    );
  }

  Future<void> deleteEvent() async {
    state = const AsyncValue<void>.loading();

    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError('Not logged in', StackTrace.current);
      return;
    }

    final existingEvent = await ref.read(eventDetailsProvider(_eventId).future);
    if (existingEvent.creatorId != user.uid) {
      state = AsyncError(
        'Only the event creator can delete this event',
        StackTrace.current,
      );
      return;
    }

    state = await AsyncValue.guard(
      () => ref.read(eventRepositoryProvider).deleteEvent(_eventId),
    );
  }
}

final filteredEventsProvider = StreamProvider<List<Event>>((ref) {
  final filter = ref.watch(eventFilterControllerProvider);
  final repo = ref.watch(eventRepositoryProvider);

  // 🔍 Debug — check if filter is being received

  if (filter.isEmpty) {
    return repo.watchAllEvents();
  }

  return repo.watchFilteredEvents(filter);
});

final eventFilterControllerProvider =
    NotifierProvider<EventFilterController, EventFilter>(
      EventFilterController.new,
    );

class EventFilterController extends Notifier<EventFilter> {
  @override
  EventFilter build() => const EventFilter();

  void setKeyword(String? keyword) {
    state = state.copyWith(keyword: keyword?.isEmpty == true ? null : keyword);
  }

  void setLocation(String? location) {
    state = state.copyWith(
      location: location?.isEmpty == true ? null : location,
    );
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  // ✅ Full reset
  void clearFilters() => state = const EventFilter();
}

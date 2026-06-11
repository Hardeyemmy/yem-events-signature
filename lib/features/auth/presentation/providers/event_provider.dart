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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/auth_providers.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailsProvider(eventId));
    final currentUser = ref.watch(currentUserProvider);
    final isAttendingAsync = ref.watch(isAttendingProvider(eventId));
    final attendeeCountAsync = ref.watch(attendeeCountProvider(eventId));
    final rsvpState = ref.watch(rsvpControllerProvider);

    return Scaffold(
      body: eventAsync.when(
        data: (event) {
          final dateFormat = DateFormat('MMMM d, y - h:mm a');
          final timeFormat = DateFormat('h:mm a');

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(event.title),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.deepPurple, Colors.purple.shade300],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.event,
                        size: 100,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.description,
                        title: dateFormat.format(event.date),
                        subtitle: timeFormat.format(event.date),
                      ),
                      const SizedBox(height: 16),

                      _InfoRow(
                        icon: Icons.location_on,
                        title: 'Location',
                        subtitle: event.location,
                      ),
                      const SizedBox(height: 16),

                      _InfoRow(
                        icon: Icons.person,
                        title: 'Hosted by',
                        subtitle: event.creatorEmail,
                      ),
                      const SizedBox(height: 16),

                      attendeeCountAsync.when(
                        data: (attendanceCount) => _InfoRow(
                          icon: Icons.people,
                          title: '$attendanceCount attending',
                          subtitle: 'Tap RSVP to join',
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      const Divider(),
                      const SizedBox(height: 24),
                      Text(
                        'About this event',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.description,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error: $err')),
        ),
      ),
      floatingActionButton:
          eventAsync.value != null &&
              eventAsync.value!.creatorId != currentUser?.uid
          ? isAttendingAsync.when(
              data: (isAttending) => FloatingActionButton.extended(
                onPressed: rsvpState.isLoading
                    ? null
                    : () => ref
                          .read(rsvpControllerProvider.notifier)
                          .toggleRsvp(eventId),
                icon: rsvpState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isAttending ? Icons.check : Icons.add),
                label: Text(isAttending ? 'Going' : 'RSVP'),
                backgroundColor: isAttending ? Colors.green : null,
              ),
              loading: () => const FloatingActionButton.extended(
                onPressed: null,
                label: Text('Loading...'),
                icon: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            )
          : null,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.deepPurple),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

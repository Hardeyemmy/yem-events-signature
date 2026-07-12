import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../Pages/edit_event_page.dart';
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
                expandedHeight: 220,
                pinned: true,
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple,
                actions: [
                  Consumer(
                    builder: (context, ref, _) {
                      final user = ref.watch(currentUserProvider);

                      if (user != null && event.creatorId == user.uid) {
                        return IconButton(
                          icon: const Icon(Icons.edit),
                          color: Colors.white,
                          tooltip: 'Edit Event',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditEventPage(eventId: eventId),
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: Text(
                    event.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  background:
                      event.imageUrl != null && event.imageUrl!.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.deepPurple,
                                          Colors.purple.shade300,
                                        ],
                                      ),
                                    ),
                                  ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withAlpha(77),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.deepPurple,
                                Colors.purple.shade300,
                              ],
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
                        subtitle: event.creatorName,
                      ),

                      const SizedBox(height: 16),
                      attendeeCountAsync.when(
                        data: (attendanceCount) => _InfoRow(
                          icon: Icons.people,
                          title: '$attendanceCount attending',
                          subtitle: 'Tap RSVP to join',
                        ),
                        error: (error, _) => const SizedBox.shrink(),
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
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Attendees',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          attendeeCountAsync.when(
                            data: (count) => Chip(
                              label: Text('$count going'),
                              avatar: const Icon(Icons.people, size: 20),
                            ),
                            error: (error, _) => const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, _) {
                          final attendeesAsync = ref.watch(
                            attendeesProvider(eventId),
                          );
                          return attendeesAsync.when(
                            data: (attendees) {
                              if (attendees.isEmpty) {
                                return Text(
                                  'Be the first to RSVP!',
                                  style: TextStyle(color: Colors.grey[600]),
                                );
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final attendee = attendees[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        attendee.displayName.isNotEmpty
                                            ? attendee.displayName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      attendee.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Joined ${DateFormat('MMM d').format(attendee.joinedAt)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  );
                                },
                                separatorBuilder: (context, _) =>
                                    const Divider(height: 1),
                                itemCount: attendees.length,
                              );
                            },
                            error: (err, _) => Text('Error: $err'),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
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
              currentUser != null &&
              eventAsync.value!.creatorId != currentUser.uid
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
              error: (error, _) => const SizedBox.shrink(),
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

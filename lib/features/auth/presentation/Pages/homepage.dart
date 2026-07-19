import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../presentation/widgets/search_bar.dart';
import '../../../events/domains/models/events.dart';
import '../providers/event_provider.dart';
import '../providers/auth_providers.dart';
import 'event_details_page.dart';
import '../../../../core/utils/responsive.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(filteredEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        titleSpacing: 16,
        title: Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(currentUserProvider);
            final name =
                user?.displayName?.split(' ').first ??
                user?.email?.split('@')[0] ??
                'there';

            return Row(
              children: [
                // ✅ App logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/logo/yemevent_logo.png',
                    height: 32,
                    width: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                // ✅ App name + welcome message
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'YEM Events',
                      style: TextStyle(
                        color: Color(0xFFF0EFFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Welcome, $name 👋',
                      style: const TextStyle(
                        color: Color(0xFF8B8AA8),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Events',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find something happening near you',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  EventSearchBar(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Event list ──────────────────────────────────
            Expanded(
              child: eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) return const _EmptyState();
                  final isWide =
                      Responsive.isTablet(context) ||
                      Responsive.isDesktop(context);
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(eventsStreamProvider),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Responsive.maxContentWidth(context),
                        ),
                        child: isWide
                            ? GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  100,
                                ),

                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          Responsive.isDesktop(context) ? 3 : 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.75,
                                    ),
                                itemBuilder: (context, index) =>
                                    _EventCard(event: events[index]),
                                itemCount: events.length,
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  100,
                                ),
                                itemCount: events.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) =>
                                    _EventCard(event: events[index]),
                              ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _ErrorState(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(eventsStreamProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Event Card ─────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailPage(eventId: event.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or color banner
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: hasImage
                  ? Image.network(
                      event.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _ColorBanner(event: event),
                    )
                  : _ColorBanner(event: event),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Date row
                  _MetaRow(
                    icon: Icons.access_time_rounded,
                    label: dateFormat.format(event.date),
                  ),
                  const SizedBox(height: 6),

                  // Location row
                  _MetaRow(
                    icon: Icons.location_on_outlined,
                    label: event.location,
                  ),
                  const SizedBox(height: 12),

                  // Footer — host + arrow
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.deepPurple.shade50,
                        child: Text(
                          event.creatorName.isNotEmpty
                              ? event.creatorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'by ${event.creatorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Color banner fallback when no image ────────────────────
class _ColorBanner extends StatelessWidget {
  const _ColorBanner({required this.event});
  final Event event;

  // Generate a consistent color from the event title
  Color _bannerColor() {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF3ECFCF),
      const Color(0xFFFF6584),
      const Color(0xFFFFBE0B),
      const Color(0xFF06D6A0),
      const Color(0xFFEF476F),
    ];
    return colors[event.title.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      color: _bannerColor(),
      child: Center(
        child: Icon(Icons.event_rounded, size: 48, color: Colors.white),
      ),
    );
  }
}

// ── Meta row (icon + label) ────────────────────────────────
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 56,
                color: Colors.deepPurple.shade200,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No events yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the Create tab to add your first event',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

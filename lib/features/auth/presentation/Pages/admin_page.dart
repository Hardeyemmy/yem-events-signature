// lib/features/admin/presentation/pages/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _bg = Color(0xFF0F0F1A);
  static const _surface = Color(0xFF1A1A2E);
  static const _accent = Color(0xFF7C6FFF);
  static const _textPrimary = Color(0xFFF0EFFF);
  static const _textMuted = Color(0xFF8B8AA8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF7C6FFF)),
            SizedBox(width: 8),
            Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Color(0xFFF0EFFF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          labelColor: _textPrimary,
          unselectedLabelColor: _textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.event), text: 'Events'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.campaign), text: 'Announcements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_EventsTab(), _UsersTab(), _AnnouncementsTab()],
      ),
    );
  }
}

// ── Events Tab ─────────────────────────────────────────────
class _EventsTab extends ConsumerWidget {
  static const _surface = Color(0xFF1A1A2E);
  static const _textPrimary = Color(0xFFF0EFFF);
  static const _textMuted = Color(0xFF8B8AA8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(allEventsAdminProvider);

    return eventsAsync.when(
      data: (events) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final status = event['status'] ?? 'approved';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event['title'] ?? 'Untitled',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'approved'
                            ? const Color(0xFF065F46)
                            : status == 'rejected'
                            ? const Color(0xFF7F1D1D)
                            : const Color(0xFF78350F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'By: ${event['creatorEmail'] ?? ''}',
                  style: const TextStyle(color: _textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Approve
                    if (status != 'approved')
                      _AdminActionButton(
                        label: 'Approve',
                        color: const Color(0xFF059669),
                        icon: Icons.check_circle_outline,
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('events')
                              .doc(event['id'])
                              .update({'status': 'approved'});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event approved')),
                            );
                          }
                        },
                      ),
                    if (status != 'approved') const SizedBox(width: 8),
                    // Reject
                    if (status != 'rejected')
                      _AdminActionButton(
                        label: 'Reject',
                        color: const Color(0xFFDC2626),
                        icon: Icons.cancel_outlined,
                        onTap: () => _showRejectDialog(context, event['id']),
                      ),
                    const Spacer(),
                    // Delete
                    _AdminActionButton(
                      label: 'Delete',
                      color: Colors.red.shade900,
                      icon: Icons.delete_outline,
                      onTap: () => _confirmDelete(context, event['id']),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showRejectDialog(BuildContext context, String eventId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Reject Event',
          style: TextStyle(color: Color(0xFFF0EFFF)),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFFF0EFFF)),
          decoration: const InputDecoration(
            hintText: 'Reason for rejection',
            hintStyle: TextStyle(color: Color(0xFF8B8AA8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8B8AA8)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('events')
                  .doc(eventId)
                  .update({
                    'status': 'rejected',
                    'rejectionReason': controller.text,
                  });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Event?',
          style: TextStyle(color: Color(0xFFF0EFFF)),
        ),
        content: const Text(
          'This will permanently delete the event and all RSVPs.',
          style: TextStyle(color: Color(0xFF8B8AA8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8B8AA8)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              final attendees = await FirebaseFirestore.instance
                  .collection('events')
                  .doc(eventId)
                  .collection('attendees')
                  .get();
              for (var doc in attendees.docs) {
                batch.delete(doc.reference);
              }
              batch.delete(
                FirebaseFirestore.instance.collection('events').doc(eventId),
              );
              await batch.commit();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Users Tab ──────────────────────────────────────────────
class _UsersTab extends ConsumerWidget {
  static const _surface = Color(0xFF1A1A2E);
  static const _textPrimary = Color(0xFFF0EFFF);
  static const _textMuted = Color(0xFF8B8AA8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (users) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isBanned = user['isBanned'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: isBanned
                  ? Border.all(color: Colors.red.shade900, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFF2F0FF).withValues(),
                  child: Text(
                    (user['displayName'] ?? user['email'] ?? '?')[0]
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF7C6FFF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['displayName'] ?? 'No name',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user['email'] ?? user['id'],
                        style: const TextStyle(color: _textMuted, fontSize: 12),
                      ),
                      if (isBanned)
                        Text(
                          'BANNED: ${user['banReason'] ?? ''}',
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                // Ban/Unban toggle
                TextButton(
                  onPressed: () => isBanned
                      ? _unbanUser(context, user['id'])
                      : _showBanDialog(context, user['id']),
                  child: Text(
                    isBanned ? 'Unban' : 'Ban',
                    style: TextStyle(
                      color: isBanned ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showBanDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Ban User?',
          style: TextStyle(color: Color(0xFFF0EFFF)),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFFF0EFFF)),
          decoration: const InputDecoration(
            hintText: 'Reason for ban',
            hintStyle: TextStyle(color: Color(0xFF8B8AA8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8B8AA8)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({
                    'isBanned': true,
                    'banReason': controller.text,
                    'bannedAt': FieldValue.serverTimestamp(),
                  });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Ban', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _unbanUser(BuildContext context, String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBanned': false,
      'banReason': null,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User unbanned')));
    }
  }
}

// ── Announcements Tab ──────────────────────────────────────
class _AnnouncementsTab extends StatefulWidget {
  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  static const _surface = Color(0xFF1A1A2E);
  static const _accent = Color(0xFF7C6FFF);
  static const _textPrimary = Color(0xFFF0EFFF);
  static const _textMuted = Color(0xFF8B8AA8);
  static const _inputBorder = Color(0xFF2E2E4A);

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty)
      return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _titleController.clear();
      _messageController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Announcement sent!')));
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send Announcement',
            style: TextStyle(
              color: Color(0xFFF0EFFF),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This will be saved to Firestore and can be shown to all users in-app.',
            style: TextStyle(color: Color(0xFF8B8AA8), fontSize: 13),
          ),
          const SizedBox(height: 24),
          _field(_titleController, 'Announcement Title', 1),
          const SizedBox(height: 16),
          _field(_messageController, 'Message', 5),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Sending...' : 'Send to All Users'),
            ),
          ),
          const SizedBox(height: 32),
          // Past announcements
          const Text(
            'Past Announcements',
            style: TextStyle(
              color: Color(0xFFF0EFFF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Text(
                  'No announcements yet.',
                  style: TextStyle(color: Color(0xFF8B8AA8)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? '',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['message'] ?? '',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, int maxLines) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFFF0EFFF)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8B8AA8)),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E4A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E4A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C6FFF), width: 1.5),
        ),
      ),
    );
  }
}

// ── Reusable admin action button ───────────────────────────
class _AdminActionButton extends StatelessWidget {
  const _AdminActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

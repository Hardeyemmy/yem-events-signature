import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isSavingName = false;

  // ── Design tokens (matching login page) ───────────
  static const _bg = Color(0xFF0F0F1A);
  static const _surface = Color(0xFF1A1A2E);
  static const _accent = Color(0xFF7C6FFF);
  static const _accentSoft = Color(0x337C6FFF);
  static const _textPrimary = Color(0xFFF0EFFF);
  static const _textMuted = Color(0xFF8B8AA8);
  static const _inputBorder = Color(0xFF2E2E4A);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSavingName = true);
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      await FirebaseAuth.instance.currentUser?.reload();
      setState(() => _isEditingName = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated'),
            backgroundColor: Color(0xFF7C6FFF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update name: $e')));
      }
    } finally {
      setState(() => _isSavingName = false);
    }
  }

  void _startEditing(String currentName) {
    _nameController.text = currentName;
    setState(() => _isEditingName = true);
  }

  String _getInitials(User? user) {
    final name = user?.displayName;
    final email = user?.email ?? '';
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  String _getDisplayName(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user?.email?.split('@')[0] ?? 'Anonymous';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authControllerProvider);
    final displayName = _getDisplayName(user);
    final initials = _getInitials(user);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header ──────────────────────────────
              const Text(
                'Your Profile',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),

              // ── Avatar ──────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentSoft,
                  border: Border.all(color: _accent, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Display name + edit ──────────────────
              if (_isEditingName) ...[
                // Edit mode
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent, width: 1.5),
                  ),
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(color: _textMuted),
                    ),
                    onSubmitted: (_) => _saveDisplayName(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isEditingName = false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: _textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isSavingName ? null : _saveDisplayName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: _isSavingName
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save name'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Display mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _startEditing(displayName),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: _accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 6),
              Text(
                user?.email ?? '',
                style: const TextStyle(color: _textMuted, fontSize: 14),
              ),

              const SizedBox(height: 40),

              // ── Stats row ────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _inputBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Member since',
                        value: user?.metadata.creationTime != null
                            ? _formatDate(user!.metadata.creationTime!)
                            : '—',
                      ),
                    ),
                    Container(width: 1, height: 40, color: _inputBorder),
                    _StatItem(
                      label: 'Account',
                      value: user?.emailVerified == true
                          ? 'Verified'
                          : 'Unverified',
                      valueColor: user?.emailVerified == true
                          ? const Color(0xFF06D6A0)
                          : const Color(0xFFFFBE0B),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Settings list ────────────────────────
              _SettingsSection(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit display name',
                    onTap: () => _startEditing(displayName),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & support',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Danger zone ──────────────────────────
              _SettingsSection(
                children: [
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    labelColor: Colors.red.shade400,
                    iconColor: Colors.red.shade400,
                    showChevron: false,
                    isLoading: authState.isLoading,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: _surface,
                          title: const Text(
                            'Log out?',
                            style: TextStyle(color: _textPrimary),
                          ),
                          content: const Text(
                            'You can always log back in.',
                            style: TextStyle(color: _textMuted),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: _textMuted),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Log out',
                                style: TextStyle(color: Colors.red.shade400),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── App version ──────────────────────────
              Text(
                'YEM Events v1.0.0',
                style: TextStyle(
                  color: _textMuted.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ── Stat item ──────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor ?? const Color(0xFFF0EFFF),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF8B8AA8), fontSize: 12),
        ),
      ],
    );
  }
}

// ── Settings section container ─────────────────────────────
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E4A)),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(
                      height: 1,
                      color: Color(0xFF2E2E4A),
                      indent: 56,
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Settings tile ──────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.showChevron = true,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;
  final bool showChevron;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF7C6FFF)).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? const Color(0xFF7C6FFF),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? const Color(0xFFF0EFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF8B8AA8),
                ),
              )
            else if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8B8AA8),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

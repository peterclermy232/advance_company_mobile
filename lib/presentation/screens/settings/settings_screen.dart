import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return ListView(
            children: [
              // ── Profile Header ──────────────────────────────────────────
              GestureDetector(
                onTap: () => context.push('/profile/edit'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white30,
                        backgroundImage: user.profilePhotoUrl != null
                            ? NetworkImage(user.profilePhotoUrl!)
                            : null,
                        child: user.profilePhotoUrl == null
                            ? Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            if (user.isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, color: Colors.white70),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Account Section ─────────────────────────────────────────
              _buildSection(context, 'Account', [
                _SettingsTile(
                  icon: Icons.person,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () => context.push('/profile/edit'),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your login credentials',
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                _SettingsTile(
                  icon: Icons.security,
                  title: 'Two-Factor Authentication',
                  subtitle: user.twoFactorEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: user.twoFactorEnabled,
                    onChanged: (value) {
                      // TODO: hook up 2FA toggle
                    },
                  ),
                ),
                _SettingsTile(
                  icon: Icons.fingerprint,
                  title: 'Biometric Login',
                  subtitle: user.biometricEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: user.biometricEnabled,
                    onChanged: (value) {
                      // TODO: hook up biometric toggle
                    },
                  ),
                ),
              ]),

              // ── Admin Section ─────────────────────────────────────────
              if (user.isAdmin)
                _buildSection(context, 'Admin', [
                  _SettingsTile(
                    icon: Icons.pending_actions,
                    title: 'Deposit Approvals',
                    onTap: () => context.push('/admin/deposit-approvals'),
                  ),
                  _SettingsTile(
                    icon: Icons.assignment_outlined,
                    title: 'Application Reviews',
                    onTap: () => context.push('/admin/applications'),
                  ),
                  _SettingsTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Beneficiary Verification',
                    onTap: () =>
                        context.push('/admin/beneficiary-verification'),
                  ),
                  _SettingsTile(
                    icon: Icons.people_outline,
                    title: 'Member Management',
                    onTap: () => context.push('/admin/members'),
                  ),
                  _SettingsTile(
                    icon: Icons.bar_chart,
                    title: 'Analytics',
                    onTap: () => context.push('/admin/analytics'),
                  ),
                ]),

              // ── Preferences ───────────────────────────────────────────
              _buildSection(context, 'Preferences', [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => context.push('/notifications'),
                ),
                _SettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
              ]),

              // ── About ─────────────────────────────────────────────────
              _buildSection(context, 'About', [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.support_agent,
                  title: 'Contact Support',
                  subtitle: 'support@advancecompany.com',
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 8),

              // ── Logout ────────────────────────────────────────────────
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CustomButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content:
                        const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref
                          .read(currentUserProvider.notifier)
                          .logout();
                      context.go('/login');
                    }
                  },
                  backgroundColor: Colors.red,
                  child: const Text('Logout'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context,
      String title,
      List<_SettingsTile> tiles,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: tiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final tile = entry.value;
              return Column(
                children: [
                  if (idx != 0) const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(tile.icon,
                          color: Colors.blue.shade700, size: 20),
                    ),
                    title: Text(tile.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    subtitle: tile.subtitle != null
                        ? Text(tile.subtitle!,
                        style: const TextStyle(fontSize: 12))
                        : null,
                    trailing: tile.trailing ??
                        (tile.onTap != null
                            ? const Icon(Icons.chevron_right,
                            color: Colors.grey)
                            : null),
                    onTap: tile.onTap,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _showChangePasswordDialog(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordCtrl,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password (min 12 chars)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordCtrl.text.length < 12) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password must be at least 12 characters')),
                  );
                  return;
                }
                if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Passwords do not match')),
                  );
                  return;
                }
                try {
                  final repo =
                  await ref.read(authRepositoryProvider.future);
                  await repo.changePassword({
                    'old_password': oldPasswordCtrl.text,
                    'new_password': newPasswordCtrl.text,
                    'new_password_confirm': confirmPasswordCtrl.text,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e
                            .toString()
                            .replaceAll('Exception: ', '')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}
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
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox();

          return ListView(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: user.profilePhotoUrl != null
                              ? NetworkImage(user.profilePhotoUrl!)
                              : null,
                          child: user.profilePhotoUrl == null
                              ? Text(
                            user.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => context.push('/profile/edit'),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    if (user.role != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role!.toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Account Section
              const SizedBox(height: 16),
              _buildSettingsSection(
                context,
                'Account',
                [
                  _SettingsTile(
                    icon: Icons.person,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _SettingsTile(
                    icon: Icons.lock,
                    title: 'Change Password',
                    onTap: () => _showChangePasswordDialog(context, ref),
                  ),
                  _SettingsTile(
                    icon: Icons.security,
                    title: 'Two-Factor Authentication',
                    subtitle: user.twoFactorEnabled ? 'Enabled' : 'Disabled',
                    trailing: Switch(
                      value: user.twoFactorEnabled,
                      onChanged: (value) {
                        // TODO: Handle 2FA toggle via API
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '2FA can be managed from account security settings'),
                          ),
                        );
                      },
                    ),
                  ),
                  if (!user.emailVerified)
                    _SettingsTile(
                      icon: Icons.email,
                      title: 'Verify Email',
                      subtitle: 'Your email is not verified',
                      iconColor: Colors.orange,
                      onTap: () => context.push(
                          '/verify-email?email=${Uri.encodeComponent(user.email)}'),
                    ),
                ],
              ),

              // Admin Section (only for staff/admin)
              if (user.isAdmin) ...[
                _buildSettingsSection(
                  context,
                  'Administration',
                  [
                    _SettingsTile(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Dashboard',
                      subtitle: 'Manage members, deposits & more',
                      iconColor: Colors.red,
                      onTap: () => context.push('/admin'),
                    ),
                    _SettingsTile(
                      icon: Icons.pending_actions,
                      title: 'Pending Approvals',
                      subtitle: 'Review deposit requests',
                      iconColor: Colors.orange,
                      onTap: () => context.push('/admin/deposit-approvals'),
                    ),
                    _SettingsTile(
                      icon: Icons.bar_chart,
                      title: 'Analytics',
                      subtitle: 'View financial reports',
                      iconColor: Colors.purple,
                      onTap: () => context.push('/admin/analytics'),
                    ),
                  ],
                ),
              ],

              // App Section
              _buildSettingsSection(
                context,
                'Preferences',
                [
                  _SettingsTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                  _SettingsTile(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                  ),
                ],
              ),

              _buildSettingsSection(
                context,
                'About',
                [
                  _SettingsTile(
                    icon: Icons.info,
                    title: 'App Version',
                    subtitle: '1.0.0',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.description,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                ],
              ),

              // Logout
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      await ref.read(currentUserProvider.notifier).logout();
                      context.go('/login');
                    }
                  },
                  backgroundColor: Colors.red,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context,
      String title,
      List<_SettingsTile> tiles,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: tiles.asMap().entries.map((entry) {
              final index = entry.key;
              final tile = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(tile.icon, color: tile.iconColor),
                    title: Text(tile.title),
                    subtitle: tile.subtitle != null
                        ? Text(tile.subtitle!, style: const TextStyle(fontSize: 12))
                        : null,
                    trailing: tile.trailing ??
                        (tile.onTap != null
                            ? const Icon(Icons.chevron_right, color: Colors.grey)
                            : null),
                    onTap: tile.onTap,
                  ),
                  if (index < tiles.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: Colors.grey.shade200,
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
      BuildContext context, WidgetRef ref) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                  labelText: 'Current Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                  labelText: 'New Password (min 12 chars)',
                  border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text.length < 12) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password must be at least 12 characters')),
                );
                return;
              }
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                final authRepository =
                await ref.read(authRepositoryProvider.future);
                await authRepository.changePassword({
                  'old_password': oldPasswordController.text,
                  'new_password': newPasswordController.text,
                  'new_password_confirm': confirmPasswordController.text,
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
                      content: Text(
                          e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Change Password'),
          ),
        ],
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
  final Color? iconColor;

  _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });
}
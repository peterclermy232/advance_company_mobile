
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  Future<void> _toggleBiometric(bool value) async {
    final success = await ref.read(authProvider.notifier).updateProfile({
      'is_biometric_enabled': value,
    });
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).error ?? 'Update failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggle2FA(bool value) async {
    if (value) {
      // Navigate to 2FA setup screen
      context.push('/settings/two-factor');
    } else {
      // Show confirmation + disable
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Disable 2FA'),
          content: const Text(
            'Are you sure you want to disable two-factor authentication? '
                'This will make your account less secure.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        context.push('/settings/two-factor-disable');
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Uses currentUserProvider defined in auth_provider.dart
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          if (user != null) ...[
            _buildProfileCard(user),
            const SizedBox(height: 20),
          ],

          // Account Section
          _sectionLabel('Account'),
          _buildCard([
            _tile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () => context.push('/profile/edit'),
            ),
            _divider(),
            _tile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => context.push('/settings/change-password'),
            ),
            _divider(),
            _tile(
              icon: Icons.email_outlined,
              title: 'Email Address',
              subtitle: user?.email,
            ),
          ]),

          const SizedBox(height: 16),

          // Security Section
          _sectionLabel('Security'),
          _buildCard([
            _switchTile(
              icon: Icons.fingerprint,
              title: 'Biometric Login',
              subtitle: 'Use fingerprint or Face ID to sign in',
              value: user?.biometricEnabled ?? false,
              onChanged: _toggleBiometric,
            ),
            _divider(),
            _switchTile(
              icon: Icons.security_outlined,
              title: 'Two-Factor Authentication',
              subtitle: user?.twoFactorEnabled == true
                  ? 'Enabled — your account is extra secure'
                  : 'Add an extra layer of security',
              value: user?.twoFactorEnabled ?? false,
              onChanged: _toggle2FA,
            ),
          ]),

          const SizedBox(height: 16),

          // Notifications Section
          _sectionLabel('Notifications'),
          _buildCard([
            _switchTile(
              icon: Icons.notifications_outlined,
              title: 'All Notifications',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            if (_notificationsEnabled) ...[
              _divider(),
              _switchTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                value: _emailNotifications,
                onChanged: (v) => setState(() => _emailNotifications = v),
              ),
              _divider(),
              _switchTile(
                icon: Icons.phone_android,
                title: 'Push Notifications',
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
            ],
          ]),

          const SizedBox(height: 16),

          // App Section
          _sectionLabel('App'),
          _buildCard([
            _tile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => context.push('/support'),
            ),
            _divider(),
            _tile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => context.push('/privacy'),
            ),
            _divider(),
            _tile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => context.push('/terms'),
            ),
            _divider(),
            _tile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
            ),
          ]),

          const SizedBox(height: 16),

          // Danger zone
          _buildCard([
            _tile(
              icon: Icons.logout,
              title: 'Sign Out',
              iconColor: AppColors.error,
              titleColor: AppColors.error,
              onTap: _logout,
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileCard(user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            backgroundImage: user.profilePhotoUrl != null
                ? NetworkImage(user.profilePhotoUrl!)
                : null,
            child: user.profilePhotoUrl == null
                ? Text(
              user.firstName.isNotEmpty
                  ? user.firstName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: AppColors.cardShadow,
    ),
    child: Column(children: children),
  );

  Widget _divider() =>
      const Divider(height: 1, indent: 56, color: AppColors.divider);

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: titleColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12))
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right,
          color: AppColors.textSecondary, size: 20)
          : null,
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12))
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
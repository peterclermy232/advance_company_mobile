import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import 'loading_indicator.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Drawer(
      child: Column(
        children: [
          userAsync.when(
            data: (user) => UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: user?.profilePhotoUrl != null
                    ? NetworkImage(user!.profilePhotoUrl!)
                    : null,
                child: user?.profilePhotoUrl == null
                    ? Text(
                  user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              accountName: Text(
                user?.fullName ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? ''),
              otherAccountsPictures: user?.isAdmin == true
                  ? [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
                )
              ]
                  : null,
            ),
            loading: () => const DrawerHeader(child: LoadingIndicator()),
            error: (_, __) =>
            const DrawerHeader(child: Text('Error loading user')),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Main navigation
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/dashboard');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Financial',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/financial');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'Deposit History',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/deposit-history');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people,
                  title: 'Beneficiaries',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/beneficiaries');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.file_copy,
                  title: 'Documents',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/documents');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assignment,
                  title: 'Applications',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/applications');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/notifications');
                  },
                ),

                // Admin section
                userAsync.when(
                  data: (user) => user?.isAdmin == true
                      ? Column(
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'ADMINISTRATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Dashboard',
                        textColor: Colors.red.shade700,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.pending_actions,
                        title: 'Deposit Approvals',
                        textColor: Colors.orange.shade700,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin/deposit-approvals');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.how_to_reg,
                        title: 'Beneficiary Verification',
                        textColor: Colors.blue.shade700,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin/beneficiary-verification');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.bar_chart,
                        title: 'Analytics',
                        textColor: Colors.purple.shade700,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin/analytics');
                        },
                      ),
                    ],
                  )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(currentUserProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color? textColor,
      }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }
}
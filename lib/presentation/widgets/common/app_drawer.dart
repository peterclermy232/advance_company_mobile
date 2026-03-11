// lib/presentation/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Uses currentUserProvider now correctly defined in auth_provider.dart
    final user = ref.watch(currentUserProvider);

    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              user?.fullName ?? 'Guest',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 12),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              backgroundImage: user?.profilePhotoUrl != null
                  ? NetworkImage(user!.profilePhotoUrl!)
                  : null,
              child: user?.profilePhotoUrl == null
                  ? Text(
                user?.firstName.isNotEmpty == true
                    ? user!.firstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            otherAccountsPictures: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (user?.role ?? 'member').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _navItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: '/dashboard',
                ),
                _navItem(
                  context,
                  icon: Icons.savings_outlined,
                  title: 'My Deposits',
                  route: '/deposits',
                ),
                _navItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Beneficiaries',
                  route: '/beneficiaries',
                ),
                _navItem(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Documents',
                  route: '/documents',
                ),
                _navItem(
                  context,
                  icon: Icons.assignment_outlined,
                  title: 'Applications',
                  route: '/applications',
                ),
                _navItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  route: '/notifications',
                ),
                if (user?.isAdmin == true) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _navItem(
                    context,
                    icon: Icons.pending_actions_outlined,
                    title: 'Pending Approvals',
                    route: '/admin/pending',
                  ),
                  _navItem(
                    context,
                    icon: Icons.analytics_outlined,
                    title: 'Analytics',
                    route: '/admin/analytics',
                  ),
                ],
                const Divider(),
                _navItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile',
                  route: '/profile',
                ),
                _navItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  route: '/settings',
                ),
              ],
            ),
          ),

          // Logout button
          const Divider(height: 1),
          ListTile(
            leading:
            const Icon(Icons.logout, color: AppColors.error, size: 22),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              Navigator.pop(context); // close drawer
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
      }) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isActive = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: isActive ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? AppColors.primary.withOpacity(0.08) : null,
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
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
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Logo Header ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'AC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Advance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Company',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── User Profile ───────────────────────────────────────
          userAsync.when(
            data: (user) => user != null
                ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFEFF6FF),
                    backgroundImage: user.profilePhotoUrl != null
                        ? NetworkImage(user.profilePhotoUrl!)
                        : null,
                    child: user.profilePhotoUrl == null
                        ? Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (user.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF2563EB), width: 1),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            )
                : const SizedBox.shrink(),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Navigation Items ───────────────────────────────────
          Expanded(
            child: userAsync.when(
              data: (user) => ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    route: '/dashboard',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/dashboard');
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    label: 'Financial',
                    route: '/financial',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/financial');
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: 'Reports',
                    route: '/reports',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/deposit-history');
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'Beneficiary',
                    route: '/beneficiaries',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/beneficiaries');
                    },
                  ),
                  if (user != null && user.isAdmin) ...[
                    _buildNavItem(
                      context,
                      icon: Icons.how_to_reg_outlined,
                      activeIcon: Icons.how_to_reg,
                      label: 'Verify Beneficiaries',
                      route: '/admin/beneficiary-verification',
                      currentLocation: currentLocation,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/beneficiary-verification');
                      },
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.pending_actions_outlined,
                      activeIcon: Icons.pending_actions,
                      label: 'Deposit Approvals',
                      route: '/admin/deposit-approvals',
                      currentLocation: currentLocation,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/deposit-approvals');
                      },
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.people_outline,
                      activeIcon: Icons.people,
                      label: 'Members',
                      route: '/admin/members',
                      currentLocation: currentLocation,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/members');
                      },
                    ),
                  ],
                  _buildNavItem(
                    context,
                    icon: Icons.description_outlined,
                    activeIcon: Icons.description,
                    label: 'Documents',
                    route: '/documents',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/documents');
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'Applications',
                    route: '/applications',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/applications');
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Settings',
                    route: '/settings',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.help_outline,
                    activeIcon: Icons.help,
                    label: 'Support',
                    route: '/support',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Push to /support when implemented
                    },
                  ),
                  if (user != null && user.isAdmin)
                    _buildNavItem(
                      context,
                      icon: Icons.analytics_outlined,
                      activeIcon: Icons.analytics,
                      label: 'Analytics',
                      route: '/admin/analytics',
                      currentLocation: currentLocation,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/analytics');
                      },
                    ),
                ],
              ),
              loading: () => const LoadingIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Logout Button ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: InkWell(
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
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
                  await ref.read(currentUserProvider.notifier).logout();
                  context.go('/login');
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required IconData activeIcon,
        required String label,
        required String route,
        required String currentLocation,
        required VoidCallback onTap,
      }) {
    final isActive = currentLocation.startsWith(route);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? Colors.white : const Color(0xFF4B5563),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
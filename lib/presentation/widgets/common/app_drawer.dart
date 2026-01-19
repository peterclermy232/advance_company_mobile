// ============================================
// lib/presentation/widgets/common/app_drawer.dart
// ============================================
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
                child: Text(
                  user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              accountName: Text(user?.fullName ?? 'User'),
              accountEmail: Text(user?.email ?? ''),
            ),
            loading: () => const DrawerHeader(
              child: LoadingIndicator(),
            ),
            error: (_, __) => const DrawerHeader(
              child: Text('Error loading user'),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }
}
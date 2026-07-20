// lib/presentation/navigation/main_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../widgets/common/app_drawer.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAdmin   = authState.user?.isAdmin ?? false;
    final location  = GoRouterState.of(context).matchedLocation;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Financial',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    final routes = ['/dashboard', '/financial', '/profile'];

    int selectedIndex = 0;
    for (int i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) {
        selectedIndex = i;
        break;
      }
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(routes[i]),
        destinations: destinations,
      ),
      // Admin FAB for quick access to approvals
      floatingActionButton: isAdmin ? FloatingActionButton.small(
        onPressed: () => context.push('/admin/deposits'),
        tooltip: 'Pending Approvals',
        child: const Icon(Icons.approval),
      ) : null,
    );
  }
}
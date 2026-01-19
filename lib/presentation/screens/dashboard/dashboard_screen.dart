// ============================================
// lib/presentation/screens/dashboard/dashboard_screen.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/cards/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final accountAsync = ref.watch(financialAccountProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Notifications Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              unreadCountAsync.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const LoadingIndicator();
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(financialAccountProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(context, user.fullName),
                  const SizedBox(height: 24),

                  // Stats Cards
                  accountAsync.when(
                    data: (account) => _buildStatsGrid(account),
                    loading: () => const LoadingIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(context),
                  const SizedBox(height: 24),

                  // Recent Activity
                  _buildRecentActivity(context),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $userName!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic account) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        StatCard(
          label: 'Total Contributions',
          value: currencyFormat.format(
            double.tryParse(account.totalContributions) ?? 0,
          ),
          icon: Icons.account_balance_wallet,
          color: Colors.blue,
          trend: '+12%',
        ),
        StatCard(
          label: 'Interest Earned',
          value: currencyFormat.format(
            double.tryParse(account.interestEarned) ?? 0,
          ),
          icon: Icons.trending_up,
          color: Colors.green,
          trend: '+8%',
        ),
        StatCard(
          label: 'Monthly Deposits',
          value: 'KES 20,000',
          icon: Icons.calendar_today,
          color: Colors.orange,
        ),
        StatCard(
          label: 'Active Beneficiaries',
          value: '3',
          icon: Icons.people,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Make Deposit',
        icon: Icons.add_card,
        color: Colors.blue,
        onTap: () => context.push('/deposit-form'),
      ),
      _QuickAction(
        title: 'Beneficiaries',
        icon: Icons.people,
        color: Colors.green,
        onTap: () => context.push('/beneficiaries'),
      ),
      _QuickAction(
        title: 'Documents',
        icon: Icons.file_copy,
        color: Colors.orange,
        onTap: () => context.push('/documents'),
      ),
      _QuickAction(
        title: 'Applications',
        icon: Icons.assignment,
        color: Colors.purple,
        onTap: () => context.push('/applications'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => _buildActionCard(actions[index]),
        ),
      ],
    );
  }

  Widget _buildActionCard(_QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 32),
            const SizedBox(height: 8),
            Text(
              action.title,
              style: TextStyle(
                color: action.color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  icon: Icons.check_circle,
                  title: 'Deposit Approved',
                  subtitle: 'KES 20,000 - 2 days ago',
                  color: Colors.green,
                ),
                const Divider(),
                _buildActivityItem(
                  icon: Icons.people,
                  title: 'Beneficiary Added',
                  subtitle: 'John Doe - 5 days ago',
                  color: Colors.blue,
                ),
                const Divider(),
                _buildActivityItem(
                  icon: Icons.file_copy,
                  title: 'Document Verified',
                  subtitle: 'ID Document - 1 week ago',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

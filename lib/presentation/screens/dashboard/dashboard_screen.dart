import '../../widgets/common/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/models/deposit_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/cards/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final accountAsync = ref.watch(financialAccountProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final depositsAsync = ref.watch(depositsProvider);

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
              ref.invalidate(depositsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(context, user.fullName, user.isAdmin),
                  const SizedBox(height: 24),

                  // Stats Cards
                  accountAsync.when(
                    data: (account) => _buildStatsGrid(account),
                    loading: () => const LoadingIndicator(),
                    error: (e, _) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Could not load account data: $e'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Admin Quick Access
                  if (user.isAdmin) ...[
                    _buildAdminQuickAccess(context),
                    const SizedBox(height: 24),
                  ],

                  // Quick Actions
                  _buildQuickActions(context),
                  const SizedBox(height: 24),

                  // Recent Deposits
                  depositsAsync.when(
                    data: (deposits) => _buildRecentDeposits(context, deposits),
                    loading: () => const LoadingIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentUserProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, String userName, bool isAdmin) {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isAdmin)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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
        ),
        StatCard(
          label: 'Interest Earned',
          value: currencyFormat.format(
            double.tryParse(account.interestEarned) ?? 0,
          ),
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        StatCard(
          label: 'Interest Rate',
          value: '${account.interestRate}%',
          icon: Icons.percent,
          color: Colors.orange,
        ),
        StatCard(
          label: 'Member Since',
          value: DateFormat('MMM yyyy').format(account.createdAt),
          icon: Icons.calendar_today,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAdminQuickAccess(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Admin Quick Access',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAdminChip(
                    context,
                    'Approvals',
                    Icons.pending_actions,
                    '/admin/deposit-approvals',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAdminChip(
                    context,
                    'Analytics',
                    Icons.bar_chart,
                    '/admin/analytics',
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAdminChip(
                    context,
                    'Members',
                    Icons.people,
                    '/admin/members',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminChip(
      BuildContext context,
      String label,
      IconData icon,
      String route,
      Color color,
      ) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
          style: TextStyle(
            fontSize: 18,
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

  Widget _buildRecentDeposits(
      BuildContext context, List<DepositModel> deposits) {
    if (deposits.isEmpty) return const SizedBox.shrink();

    final recentDeposits = deposits.take(3).toList();
    final dateFormat = DateFormat('MMM dd');
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Deposits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/deposit-history'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: recentDeposits.asMap().entries.map((entry) {
                final index = entry.key;
                final deposit = entry.value;

                Color statusColor;
                IconData statusIcon;
                switch (deposit.status) {
                  case 'APPROVED':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'PENDING':
                    statusColor = Colors.orange;
                    statusIcon = Icons.schedule;
                    break;
                  case 'REJECTED':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusIcon = Icons.help;
                }

                return Column(
                  children: [
                    if (index > 0) const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child:
                        Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      title: Text(
                        currencyFormat.format(
                            double.tryParse(deposit.amount) ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${deposit.paymentMethod.replaceAll('_', ' ')} • ${dateFormat.format(deposit.createdAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        deposit.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
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
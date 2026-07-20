import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme_config.dart';
import '../../../data/models/financial_account_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/financial_provider.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/cards/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final accountAsync = ref.watch(financialAccountProvider);
    final depositsState = ref.watch(depositsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user?.firstName ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(financialAccountProvider.notifier).refresh();
          ref.read(depositsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero welcome banner
              _HeroBanner(
                firstName: user?.firstName ?? '',
                role: user?.isAdmin == true ? 'Admin' : 'Member',
                accountAsync: accountAsync,
                onDeposit: () => context.push('/deposit/new'),
                onRetry: () =>
                    ref.read(financialAccountProvider.notifier).refresh(),
              ),

              const SizedBox(height: 24),

              // Stat grid
              accountAsync.maybeWhen(
                data: (account) => _StatGrid(
                  account: account,
                  depositCount: depositsState.deposits.length,
                  pendingCount:
                      depositsState.deposits.where((d) => d.isPending).length,
                ),
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Quick actions
              const _SectionTitle('Quick Actions'),
              _QuickActionsGrid(
                isAdmin: user?.isAdmin == true,
                onDeposit: () => context.push('/deposit/new'),
                onApplications: () => context.push('/applications'),
                onDocuments: () => context.push('/documents'),
                onApprovals: () => context.push('/admin/deposits'),
              ),

              const SizedBox(height: 24),

              const _SectionTitle('Recent Deposits'),

              if (depositsState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (depositsState.error != null)
                Text('Error: ${depositsState.error}')
              else if (depositsState.deposits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No deposits yet.')),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: depositsState.deposits.take(5).map((d) {
                      final isLast = d == depositsState.deposits.take(5).last;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                IconChip(
                                  icon: d.isApproved
                                      ? Icons.check
                                      : d.isRejected
                                          ? Icons.close
                                          : Icons.hourglass_empty,
                                  color: d.isApproved
                                      ? AppColors.success
                                      : d.isRejected
                                          ? AppColors.error
                                          : AppColors.warning,
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'KES ${d.amount.toStringAsFixed(0)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${d.createdAt.day}/${d.createdAt.month}/${d.createdAt.year}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge.fromStatus(d.statusLabel),
                              ],
                            ),
                          ),
                          if (!isLast)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String firstName;
  final String role;
  final AsyncValue<FinancialAccountModel> accountAsync;
  final VoidCallback onDeposit;
  final VoidCallback onRetry;

  const _HeroBanner({
    required this.firstName,
    required this.role,
    required this.accountAsync,
    required this.onDeposit,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName.isEmpty ? 'there' : firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          accountAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load balance',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (account) {
              final monthlyLimit = account.monthlyDepositLimit;
              final monthlyRemaining = account.remainingMonthlyLimit;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KES ${account.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Monthly Remaining: KES ${monthlyRemaining.toStringAsFixed(0)} / ${monthlyLimit.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: monthlyLimit > 0
                          ? ((monthlyLimit - monthlyRemaining) / monthlyLimit)
                              .clamp(0.0, 1.0)
                          : 0,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onDeposit,
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      label: const Text('Make Deposit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final FinancialAccountModel account;
  final int depositCount;
  final int pendingCount;

  const _StatGrid({
    required this.account,
    required this.depositCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        label: 'Monthly Deposited',
        value: 'KES ${account.monthlyDepositTotal.toStringAsFixed(0)}',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
      ),
      StatCard(
        label: 'Monthly Remaining',
        value: 'KES ${account.remainingMonthlyLimit.toStringAsFixed(0)}',
        icon: Icons.savings_rounded,
        color: AppColors.info,
      ),
      StatCard(
        label: 'Total Deposits',
        value: '$depositCount',
        icon: Icons.receipt_long_rounded,
        color: AppColors.secondary,
      ),
      StatCard(
        label: 'Pending',
        value: '$pendingCount',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 148,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onDeposit;
  final VoidCallback onApplications;
  final VoidCallback onDocuments;
  final VoidCallback onApprovals;

  const _QuickActionsGrid({
    required this.isAdmin,
    required this.onDeposit,
    required this.onApplications,
    required this.onDocuments,
    required this.onApprovals,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _QuickActionTile(
        icon: Icons.add_circle_outline,
        label: 'Deposit',
        color: AppColors.primary,
        onTap: onDeposit,
      ),
      _QuickActionTile(
        icon: Icons.description_outlined,
        label: 'Applications',
        color: AppColors.success,
        onTap: onApplications,
      ),
      _QuickActionTile(
        icon: Icons.folder_outlined,
        label: 'Documents',
        color: AppColors.secondary,
        onTap: onDocuments,
      ),
      if (isAdmin)
        _QuickActionTile(
          icon: Icons.approval_outlined,
          label: 'Approvals',
          color: AppColors.warning,
          onTap: onApprovals,
        ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: tiles,
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

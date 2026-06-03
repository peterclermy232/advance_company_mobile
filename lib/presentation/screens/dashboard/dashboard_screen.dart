
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/financial_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user          = ref.watch(currentUserProvider);
    final accountAsync  = ref.watch(financialAccountProvider);
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
              // Balance Card
              accountAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(financialAccountProvider.notifier).refresh(),
                ),
                data: (account) => _BalanceCard(
                  balance: account.balance,
                  monthlyRemaining: account.remainingMonthlyLimit,
                  monthlyLimit: account.monthlyDepositLimit,
                  onDeposit: () => context.push('/deposit/new'),
                ),
              ),

              const SizedBox(height: 24),

              // Quick actions
              if (user?.isAdmin == true) ...[
                _SectionTitle('Admin'),
                Row(children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.approval,
                      label: 'Approvals',
                      color: Colors.orange,
                      onTap: () => context.push('/admin/deposits'),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
              ],

              _SectionTitle('Recent Deposits'),

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
                  Column(
                    children: depositsState.deposits.take(5).map((d) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: d.isApproved
                              ? Colors.green.shade100
                              : d.isRejected
                              ? Colors.red.shade100
                              : Colors.orange.shade100,
                          child: Icon(
                            d.isApproved
                                ? Icons.check
                                : d.isRejected
                                ? Icons.close
                                : Icons.hourglass_empty,
                            color: d.isApproved
                                ? Colors.green
                                : d.isRejected
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                        title: Text('KES ${d.amount.toStringAsFixed(0)}'),
                        subtitle: Text(d.statusLabel),
                        trailing: Text(
                          '${d.createdAt.day}/${d.createdAt.month}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }).toList(),
                  ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double monthlyRemaining;
  final double monthlyLimit;
  final VoidCallback onDeposit;

  const _BalanceCard({
    required this.balance,
    required this.monthlyRemaining,
    required this.monthlyLimit,
    required this.onDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Balance', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              'KES ${balance.toStringAsFixed(2)}',
              style: theme.textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Monthly Remaining: KES ${monthlyRemaining.toStringAsFixed(0)} / ${monthlyLimit.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: monthlyLimit > 0
                  ? ((monthlyLimit - monthlyRemaining) / monthlyLimit)
                  .clamp(0.0, 1.0)
                  : 0,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onDeposit,
              icon: const Icon(Icons.add),
              label: const Text('Make Deposit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(message),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
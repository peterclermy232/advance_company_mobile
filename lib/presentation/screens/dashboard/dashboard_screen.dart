import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/financial_account_model.dart';
import '../../../data/providers/financial_provider.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/loading_indicator.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final accountAsync = ref.watch(financialAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financialAccountProvider);
          ref.invalidate(currentUserProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Greeting ──────────────────────────────────────────────
            userAsync.when(
              data: (user) => user != null
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user.fullName.split(' ').first} 👋',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here\'s your financial summary',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // ── Summary Banner Card ────────────────────────────────────
            accountAsync.when(
              data: (account) => account != null
                  ? _SummaryCard(account: account)
                  : const SizedBox.shrink(),
              loading: () => const LoadingIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 20),

            // ── Stat Cards (equal-size grid using GridView.count) ──────
            accountAsync.when(
              data: (account) {
                if (account == null) return const SizedBox.shrink();

                final contributions =
                    double.tryParse(account.totalContributions) ?? 0.0;
                final interest =
                    double.tryParse(account.interestEarned) ?? 0.0;
                final rate =
                    double.tryParse(account.interestRate) ?? 0.0;
                final total = contributions + interest;

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  // childAspectRatio forces every card to be the same size
                  childAspectRatio: 1.35,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      label: 'Total Contributions',
                      value: 'KES ${_fmt(contributions)}',
                      icon: Icons.savings_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                    StatCard(
                      label: 'Interest Earned',
                      value: 'KES ${_fmt(interest)}',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF16A34A),
                      trend: '${rate.toStringAsFixed(1)}% p.a.',
                    ),
                    StatCard(
                      label: 'Interest Rate',
                      value: '${rate.toStringAsFixed(2)}%',
                      icon: Icons.percent_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                    StatCard(
                      label: 'Total Balance',
                      value: 'KES ${_fmt(total)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFFD97706),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: LoadingIndicator()),
              ),
              error: (e, _) => Text('Error loading stats: $e'),
            ),

            const SizedBox(height: 24),

            // ── Quick Actions ──────────────────────────────────────────
            Text(
              'QUICK ACTIONS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Deposit',
                    color: Colors.green,
                    onTap: () => context.push('/deposit-form'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.history,
                    label: 'History',
                    color: Colors.blue,
                    onTap: () => context.push('/deposit-history'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.assignment_outlined,
                    label: 'Apply',
                    color: Colors.purple,
                    onTap: () => context.push('/applications/new'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.people_outline,
                    label: 'Beneficiaries',
                    color: Colors.teal,
                    onTap: () => context.push('/beneficiaries'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _fmt(double val) {
    return val.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
  }
}

// ── Summary Banner ────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final FinancialAccountModel account;
  const _SummaryCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final contributions = double.tryParse(account.totalContributions) ?? 0.0;
    final interest = double.tryParse(account.interestEarned) ?? 0.0;
    final total = contributions + interest;

    final formatted = total
        .toStringAsFixed(2)
        .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Portfolio Value',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'KES $formatted',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Pill(label: 'ID #${account.id}', icon: Icons.badge_outlined),
              const SizedBox(width: 8),
              if (account.userName != null)
                _Pill(
                    label: account.userName!,
                    icon: Icons.person_outline),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Pill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Quick Action Button ────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================
// lib/presentation/screens/financial/financial_screen.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/financial_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/cards/deposit_card.dart';

class FinancialScreen extends ConsumerWidget {
  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(financialAccountProvider);
    final depositsAsync = ref.watch(depositsProvider);
    final canDepositAsync = ref.watch(canDepositProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Overview'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financialAccountProvider);
          ref.invalidate(depositsProvider);
          ref.invalidate(canDepositProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Summary Card
              accountAsync.when(
                data: (account) => _buildAccountSummary(context, account),
                loading: () => const LoadingIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),

              // Can Deposit Status
              canDepositAsync.when(
                data: (data) => _buildDepositStatus(context, data),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Deposit History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Deposit History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/deposit-form'),
                    icon: const Icon(Icons.add),
                    label: const Text('New Deposit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              depositsAsync.when(
                data: (deposits) {
                  if (deposits.isEmpty) {
                    return EmptyState(
                      icon: Icons.account_balance_wallet,
                      title: 'No Deposits Yet',
                      message: 'Start making deposits to build your savings',
                      action: ElevatedButton.icon(
                        onPressed: () => context.push('/deposit-form'),
                        icon: const Icon(Icons.add),
                        label: const Text('Make First Deposit'),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: deposits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return DepositCard(deposit: deposits[index]);
                    },
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSummary(BuildContext context, dynamic account) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _buildSummaryRow(
              'Total Contributions',
              currencyFormat.format(
                double.tryParse(account.totalContributions) ?? 0,
              ),
              Icons.account_balance_wallet,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Interest Earned',
              currencyFormat.format(
                double.tryParse(account.interestEarned) ?? 0,
              ),
              Icons.trending_up,
              Colors.green,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Interest Rate',
              '${account.interestRate}%',
              Icons.percent,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepositStatus(BuildContext context, Map<String, dynamic> data) {
    final canDeposit = data['can_deposit'] as bool;
    final message = data['message'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canDeposit ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canDeposit ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            canDeposit ? Icons.check_circle : Icons.info,
            color: canDeposit ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: canDeposit ? Colors.green.shade900 : Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

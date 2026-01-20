// ============================================
// lib/presentation/screens/financial/deposit_history_screen.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/models/deposit_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/cards/deposit_card.dart';

// Filter state provider
final depositFilterProvider = StateProvider<String>((ref) => 'ALL');

// Filtered deposits provider
final filteredDepositsProvider = Provider<AsyncValue<List<DepositModel>>>((ref) {
  final depositsAsync = ref.watch(depositsProvider);
  final filter = ref.watch(depositFilterProvider);

  return depositsAsync.when(
    data: (deposits) {
      if (filter == 'ALL') {
        return AsyncValue.data(deposits);
      }
      final filtered = deposits.where((d) => d.status == filter).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class DepositHistoryScreen extends ConsumerWidget {
  const DepositHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredDepositsAsync = ref.watch(filteredDepositsProvider);
    final currentFilter = ref.watch(depositFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(context, ref, currentFilter),
          
          // Deposits List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(depositsProvider);
                await ref.read(depositsProvider.future);
              },
              child: filteredDepositsAsync.when(
                data: (deposits) {
                  if (deposits.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long,
                      title: currentFilter == 'ALL'
                          ? 'No Deposits Yet'
                          : 'No ${_getFilterLabel(currentFilter)} Deposits',
                      message: currentFilter == 'ALL'
                          ? 'Your deposit history will appear here'
                          : 'Try changing the filter',
                    );
                  }

                  return Column(
                    children: [
                      // Summary Card
                      _buildSummaryCard(context, deposits),
                      
                      // Deposits List
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: deposits.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return DepositCard(deposit: deposits[index]);
                          },
                        ),
                      ),
                    ],
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
                        onPressed: () => ref.invalidate(depositsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, String currentFilter) {
    final filters = [
      {'value': 'ALL', 'label': 'All', 'icon': Icons.list},
      {'value': 'PENDING', 'label': 'Pending', 'icon': Icons.schedule},
      {'value': 'APPROVED', 'label': 'Approved', 'icon': Icons.check_circle},
      {'value': 'REJECTED', 'label': 'Rejected', 'icon': Icons.cancel},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = currentFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(filter['label'] as String),
                  ],
                ),
                onSelected: (_) {
                  ref.read(depositFilterProvider.notifier).state =
                      filter['value'] as String;
                },
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<DepositModel> deposits) {
    final totalAmount = deposits.fold<double>(
      0,
      (sum, deposit) => sum + (double.tryParse(deposit.amount) ?? 0),
    );

    final approvedCount = deposits.where((d) => d.status == 'APPROVED').length;
    final pendingCount = deposits.where((d) => d.status == 'PENDING').length;
    final rejectedCount = deposits.where((d) => d.status == 'REJECTED').length;

    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Total Amount',
                  currencyFormat.format(totalAmount),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Total Deposits',
                  deposits.length.toString(),
                  Icons.receipt,
                  Colors.purple,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCount('Approved', approvedCount, Colors.green),
                _buildStatusCount('Pending', pendingCount, Colors.orange),
                _buildStatusCount('Rejected', rejectedCount, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Deposits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption(context, ref, 'ALL', 'All Deposits'),
            _buildFilterOption(context, ref, 'PENDING', 'Pending'),
            _buildFilterOption(context, ref, 'APPROVED', 'Approved'),
            _buildFilterOption(context, ref, 'REJECTED', 'Rejected'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    WidgetRef ref,
    String value,
    String label,
  ) {
    final currentFilter = ref.watch(depositFilterProvider);
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: currentFilter,
      onChanged: (newValue) {
        ref.read(depositFilterProvider.notifier).state = newValue!;
        Navigator.pop(context);
      },
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'All';
    }
  }
}
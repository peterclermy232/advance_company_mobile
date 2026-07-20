import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme_config.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/models/deposit_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/status_badge.dart';

// Filter state
final depositTabFilterProvider = StateProvider<String>((ref) => 'pending');

class DepositHistoryScreen extends ConsumerWidget {
  const DepositHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsState = ref.watch(depositsProvider);
    final currentFilter = ref.watch(depositTabFilterProvider);

    if (depositsState.isLoading && depositsState.deposits.isEmpty) {
      return const LoadingIndicator();
    }

    if (depositsState.error != null && depositsState.deposits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error: ${depositsState.error}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(depositsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final deposits = depositsState.deposits;
    final pending = deposits.where((d) => d.isPending).toList();
    final approved = deposits.where((d) => d.isApproved).toList();
    final rejected = deposits.where((d) => d.isRejected).toList();

    final List<DepositModel> filtered;
    if (currentFilter == 'pending') {
      filtered = pending;
    } else if (currentFilter == 'completed') {
      filtered = approved;
    } else {
      filtered = rejected;
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(depositsProvider.notifier).refresh(),
      child: Column(
        children: [
          _buildTabBar(context, ref, currentFilter, pending.length,
              approved.length, rejected.length),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmpty(currentFilter)
                : _buildList(filtered, currentFilter),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref, String current,
      int pendingCount, int approvedCount, int rejectedCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          _buildTabButton(
              context, ref, 'pending', 'Pending ($pendingCount)', current,
              activeColor: AppColors.warning),
          _buildTabButton(
              context, ref, 'completed', 'Approved ($approvedCount)', current,
              activeColor: AppColors.success),
          _buildTabButton(
              context, ref, 'failed', 'Rejected ($rejectedCount)', current,
              activeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, WidgetRef ref, String value,
      String label, String current,
      {required Color activeColor}) {
    final isActive = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(depositTabFilterProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String filter) {
    const labels = {
      'pending': 'pending',
      'completed': 'approved',
      'failed': 'rejected',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No ${labels[filter] ?? filter} deposits found',
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          const Text('Deposits will appear here once submitted',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildList(List<DepositModel> deposits, String filter) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: deposits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _DepositTableRow(
        deposit: deposits[i],
        showReason: filter == 'failed',
      ),
    );
  }
}

// ─── Deposit Row Card ─────────────────────────────────────────────────────────

class _DepositTableRow extends StatelessWidget {
  final DepositModel deposit;
  final bool showReason;

  const _DepositTableRow({required this.deposit, this.showReason = false});

  String _initials(String? name) {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    final parts = n.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    // deposit.amount is already a double — no tryParse needed
    final amountStr = currencyFormat.format(deposit.amount);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.avatar2,
                  child: Text(
                    _initials(deposit.userName),
                    style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deposit.userName ?? 'Unknown',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        '${dateFormat.format(deposit.createdAt)}  '
                        '${timeFormat.format(deposit.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                StatusBadge.fromStatus(deposit.statusLabel),
              ],
            ),
            const Divider(height: 20),

            // Amount + method
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(amountStr,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    deposit.paymentMethodLabel,
                    style: const TextStyle(
                        color: AppColors.infoText,
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Reference
            Row(
              children: [
                const Icon(Icons.tag_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    deposit.transactionReference,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // M-Pesa phone
            if (deposit.mpesaPhone != null &&
                deposit.mpesaPhone!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_android_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(deposit.mpesaPhone!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],

            // Rejection reason
            if (showReason &&
                deposit.rejectionReason != null &&
                deposit.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.errorText, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deposit.rejectionReason!,
                        style: const TextStyle(
                            color: AppColors.errorText, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

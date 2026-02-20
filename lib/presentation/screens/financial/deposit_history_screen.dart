import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/models/deposit_model.dart';
import '../../widgets/common/loading_indicator.dart';

// Filter state: 'pending' | 'completed' | 'failed'
final depositTabFilterProvider = StateProvider<String>((ref) => 'pending');

class DepositHistoryScreen extends ConsumerWidget {
  const DepositHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsAsync = ref.watch(depositsProvider);
    final currentFilter = ref.watch(depositTabFilterProvider);

    return depositsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(depositsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (deposits) {
        // Use model helpers — isPending handles 'pending'+'processing',
        // isApproved handles 'completed', isRejected handles 'failed'+'rejected'
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
          onRefresh: () async {
            ref.invalidate(depositsProvider);
            await ref.read(depositsProvider.future);
          },
          child: Column(
            children: [
              _buildTabBar(context, ref, currentFilter,
                  pending.length, approved.length, rejected.length),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty(currentFilter)
                    : _buildList(filtered, currentFilter),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref, String current,
      int pendingCount, int approvedCount, int rejectedCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          _buildTabButton(context, ref, 'pending',
              'Pending ($pendingCount)', current,
              activeColor: Colors.blue.shade600),
          _buildTabButton(context, ref, 'completed',
              'Approved ($approvedCount)', current,
              activeColor: Colors.green.shade600),
          _buildTabButton(context, ref, 'failed',
              'Rejected ($rejectedCount)', current,
              activeColor: Colors.red.shade600),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, WidgetRef ref, String value,
      String label, String current, {required Color activeColor}) {
    final isActive = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
        ref.read(depositTabFilterProvider.notifier).state = value,
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
              color: isActive ? Colors.white : Colors.grey.shade600,
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
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No ${labels[filter] ?? filter} deposits found',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 6),
          Text('Deposits will appear here once they are submitted',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
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

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
    NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    // Use model helpers for color + label — no raw string comparisons
    final Color statusColor;
    if (deposit.isApproved) {
      statusColor = Colors.green;
    } else if (deposit.isPending) {
      statusColor = Colors.orange;
    } else if (deposit.isRejected) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.grey;
    }

    final amount =
    currencyFormat.format(double.tryParse(deposit.amount) ?? 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: avatar + name/date + status ─────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    _initials(deposit.userName),
                    style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deposit.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(
                        '${dateFormat.format(deposit.createdAt)}  '
                            '${timeFormat.format(deposit.createdAt)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // Status pill — uses model's statusLabel
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    deposit.statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // ── Amount + method row ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 2),
                    Text(amount,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                // Method badge — uses model's paymentMethodLabel
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    deposit.paymentMethodLabel,
                    style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Reference ───────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.tag, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    deposit.transactionReference,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ── M-Pesa phone ─────────────────────────────────────────────
            if (deposit.mpesaPhone != null &&
                deposit.mpesaPhone!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone_android,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    deposit.mpesaPhone!,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            // ── Rejection reason ─────────────────────────────────────────
            if (showReason &&
                deposit.rejectionReason != null &&
                deposit.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.red.shade700, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deposit.rejectionReason!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13),
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
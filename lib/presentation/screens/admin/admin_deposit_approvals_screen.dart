import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/providers/core_providers.dart';
import '../../../data/models/deposit_model.dart';

class AdminDepositApprovalsScreen extends ConsumerWidget {
  const AdminDepositApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsAsync = ref.watch(pendingDepositsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(pendingDepositsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: depositsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(pendingDepositsProvider.notifier).refresh(),
        ),
        data: (deposits) {
          if (deposits.isEmpty) {
            return const _EmptyView();
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(pendingDepositsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: deposits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _DepositCard(deposit: deposits[i]),
            ),
          );
        },
      ),
    );
  }
}

class _DepositCard extends ConsumerWidget {
  final DepositModel deposit;
  const _DepositCard({required this.deposit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KES ${deposit.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                _StatusChip(status: deposit.status),
              ],
            ),
            const SizedBox(height: 8),
            if (deposit.phoneNumber != null)
              Text('Phone: ${deposit.phoneNumber}',
                  style: theme.textTheme.bodySmall),
            Text('Method: ${deposit.method.toUpperCase()}',
                style: theme.textTheme.bodySmall),
            Text(
              'Date: ${_formatDate(deposit.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (deposit.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(context, ref, deposit.id),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approve(context, ref, deposit.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await _confirmDialog(
      context,
      title: 'Approve Deposit',
      content: 'Approve KES ${deposit.amount.toStringAsFixed(2)}?',
      confirmLabel: 'Approve',
    );
    if (!confirm) return;

    try {
      // apiClientProvider is a plain Provider<ApiClient> — no .future
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/financial/deposits/$id/approve_deposit/');
      ref.read(pendingDepositsProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await _confirmDialog(
      context,
      title: 'Reject Deposit',
      content: 'Reject this deposit? This cannot be undone.',
      confirmLabel: 'Reject',
      isDanger: true,
    );
    if (!confirm) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/financial/deposits/$id/reject_deposit/');
      ref.read(pendingDepositsProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<bool> _confirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    bool isDanger = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: isDanger
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _StatusChip extends StatelessWidget {
  final DepositStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      DepositStatus.pending => (Colors.orange, 'Pending'),
      DepositStatus.approved => (Colors.green, 'Approved'),
      DepositStatus.rejected => (Colors.red, 'Rejected'),
      DepositStatus.processing => (Colors.blue, 'Processing'),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text('No pending deposit approvals.'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

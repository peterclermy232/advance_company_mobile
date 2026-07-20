import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/providers/core_providers.dart';
import '../../../data/models/deposit_model.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';

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
                StatusBadge.fromStatus(deposit.status.name),
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
                      icon: const Icon(Icons.close, color: AppColors.error),
                      label: const Text('Reject',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approve(context, ref, deposit.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Approve Deposit',
      message: 'Approve KES ${deposit.amount.toStringAsFixed(2)}?',
      confirmText: 'Approve',
    );
    if (confirm != true) return;

    try {
      // apiClientProvider is a plain Provider<ApiClient> — no .future
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/financial/deposits/$id/approve_deposit/');
      ref.read(pendingDepositsProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit approved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String id) async {
    final reasonCtl = TextEditingController();
    String? reason;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Deposit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Reject KES ${deposit.amount.toStringAsFixed(2)}? This cannot be undone.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtl,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
                hintText: 'Explain why this deposit is being rejected',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            onPressed: () {
              if (reasonCtl.text.trim().isEmpty) return;
              reason = reasonCtl.text.trim();
              Navigator.pop(dialogContext);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonCtl.dispose();
    if (reason == null) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/financial/deposits/$id/reject_deposit/',
        data: {'reason': reason},
      );
      ref.read(pendingDepositsProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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

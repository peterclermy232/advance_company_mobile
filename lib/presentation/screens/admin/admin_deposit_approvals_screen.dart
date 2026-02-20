import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/providers/core_providers.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/models/deposit_model.dart';
import '../../widgets/common/loading_indicator.dart';

// Fetches deposits with status 'pending' from the backend.
final pendingDepositsProvider =
FutureProvider.autoDispose<List<DepositModel>>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final response = await apiClient.get(ApiEndpoints.pendingApprovals);

  // Unwrap standard envelope: { success, data: [...] }
  final raw = response.data;
  final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;

  if (data is List) {
    return data.map((e) => DepositModel.fromJson(e)).toList();
  } else if (data is Map && data.containsKey('results')) {
    return (data['results'] as List)
        .map((e) => DepositModel.fromJson(e))
        .toList();
  }
  return [];
});

class AdminDepositApprovalsScreen extends ConsumerWidget {
  const AdminDepositApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositsAsync = ref.watch(pendingDepositsProvider);

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
              onPressed: () => ref.invalidate(pendingDepositsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (deposits) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingDepositsProvider);
            await ref.read(pendingDepositsProvider.future);
          },
          child: Column(
            children: [
              _buildSummaryHeader(deposits.length),
              Expanded(
                child: deposits.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: deposits.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 16),
                  itemBuilder: (context, i) => _DepositApprovalCard(
                    deposit: deposits[i],
                    onProcessed: () =>
                        ref.invalidate(pendingDepositsProvider),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Review and approve member deposits',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Column(
            children: [
              Text('$count',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600)),
              const Text('Pending',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Pending Approvals',
              style:
              TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 6),
          Text('All deposits have been processed',
              style:
              TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ─── Approval Card ────────────────────────────────────────────────────────────

class _DepositApprovalCard extends ConsumerStatefulWidget {
  final DepositModel deposit;
  final VoidCallback onProcessed;

  const _DepositApprovalCard(
      {required this.deposit, required this.onProcessed});

  @override
  ConsumerState<_DepositApprovalCard> createState() =>
      _DepositApprovalCardState();
}

class _DepositApprovalCardState extends ConsumerState<_DepositApprovalCard> {
  bool _isProcessing = false;

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _approve() async {
    final confirmed = await _showApproveDialog();
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final repo = await ref.read(financialRepositoryProvider.future);
      await repo.approveDeposit(widget.deposit.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
          Text('✓ Deposit approved for ${widget.deposit.userName}!'),
          backgroundColor: Colors.green,
        ));
        widget.onProcessed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    String? reason;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RejectDialog(
        deposit: widget.deposit,
        controller: reasonController,
        onConfirm: (r) {
          reason = r;
          Navigator.pop(ctx);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );

    if (reason == null) return;

    setState(() => _isProcessing = true);
    try {
      final repo = await ref.read(financialRepositoryProvider.future);
      await repo.rejectDeposit(widget.deposit.id, reason!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '⚠️ Deposit rejected for ${widget.deposit.userName}'),
          backgroundColor: Colors.orange,
        ));
        widget.onProcessed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool?> _showApproveDialog() {
    final fmt = NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);
    final amount =
    fmt.format(double.tryParse(widget.deposit.amount) ?? 0);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle),
                  child: Icon(Icons.check,
                      color: Colors.green.shade600, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Approve Deposit',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),

              // Info grid
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    _infoRow('Member', widget.deposit.userName),
                    const SizedBox(height: 8),
                    _infoRow('Amount', amount),
                    const SizedBox(height: 8),
                    // paymentMethodLabel handles uppercase 'MPESA' → 'M-Pesa'
                    _infoRow('Method', widget.deposit.paymentMethodLabel),
                    const SizedBox(height: 8),
                    _infoRow(
                        'Reference', widget.deposit.transactionReference),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "This will approve the deposit and update the member's "
                    'financial account with contributions and interest.',
                style:
                TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve Deposit'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style:
              const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fmt =
    NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final amount =
    fmt.format(double.tryParse(widget.deposit.amount) ?? 0);

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
            // ── Member row ─────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    _initials(widget.deposit.userName),
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
                      Text(widget.deposit.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(
                        '${dateFormat.format(widget.deposit.createdAt)}'
                            '  ${timeFormat.format(widget.deposit.createdAt)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.orange.shade300),
                  ),
                  child: Text('PENDING',
                      style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 20),

            // ── Amount ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount',
                    style: TextStyle(color: Colors.grey)),
                Text(amount,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700)),
              ],
            ),
            const SizedBox(height: 12),

            // ── Detail rows ────────────────────────────────────────────
            _detailRow('Payment Method',
                widget.deposit.paymentMethodLabel),
            if (widget.deposit.mpesaPhone != null) ...[
              const SizedBox(height: 6),
              _detailRow('M-Pesa Phone', widget.deposit.mpesaPhone!),
            ],
            if (widget.deposit.mpesaReceiptNumber != null) ...[
              const SizedBox(height: 6),
              _detailRow(
                  'M-Pesa Receipt', widget.deposit.mpesaReceiptNumber!),
            ],
            const SizedBox(height: 6),
            _detailRow('Reference', widget.deposit.transactionReference),
            if (widget.deposit.notes != null &&
                widget.deposit.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _detailRow('Notes', widget.deposit.notes!),
            ],

            const SizedBox(height: 16),

            // ── Action buttons ────────────────────────────────────────
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reject,
                      icon: const Icon(Icons.close, size: 17),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade400),
                        padding:
                        const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _approve,
                      icon: const Icon(Icons.check, size: 17),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text('$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ],
    );
  }
}

// ─── Rejection Dialog ─────────────────────────────────────────────────────────

class _RejectDialog extends StatefulWidget {
  final DepositModel deposit;
  final TextEditingController controller;
  final ValueChanged<String> onConfirm;
  final VoidCallback onCancel;

  const _RejectDialog({
    required this.deposit,
    required this.controller,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  bool _touched = false;

  @override
  Widget build(BuildContext context) {
    final fmt =
    NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);
    final amount =
    fmt.format(double.tryParse(widget.deposit.amount) ?? 0);
    final isEmpty =
        _touched && widget.controller.text.trim().isEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle),
                child: Icon(Icons.close,
                    color: Colors.red.shade600, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Reject Deposit',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),

            // Member info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Member',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(widget.deposit.userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(amount,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason textarea
            const Text('Reason for Rejection *',
                style: TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: widget.controller,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                'Please provide a reason for rejecting this deposit...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  BorderSide(color: Colors.red.shade400),
                ),
                errorText: isEmpty ? 'Reason is required' : null,
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _touched = true);
                    if (widget.controller.text.trim().isEmpty) return;
                    widget.onConfirm(widget.controller.text.trim());
                  },
                  icon: const Icon(Icons.close, size: 17),
                  label: const Text('Reject Deposit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
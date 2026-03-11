import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/beneficiary_provider.dart';
import '../../../data/models/beneficiary_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

class BeneficiaryVerificationScreen extends ConsumerWidget {
  const BeneficiaryVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingBeneficiariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(beneficiariesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(beneficiariesProvider.notifier).refresh(),
        child: pendingAsync.when(
          data: (beneficiaries) {
            if (beneficiaries.isEmpty) {
              return const EmptyState(
                icon: Icons.people_outline,
                title: 'No Pending Verifications',
                message: 'All beneficiaries have been verified',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: beneficiaries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) =>
                  _BeneficiaryVerificationCard(
                    beneficiary: beneficiaries[index],
                    onActionComplete: () =>
                        ref.read(beneficiariesProvider.notifier).refresh(),
                  ),
            );
          },
          loading: () => const LoadingIndicator(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(beneficiariesProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _BeneficiaryVerificationCard extends ConsumerStatefulWidget {
  final BeneficiaryModel beneficiary;
  final VoidCallback onActionComplete;

  const _BeneficiaryVerificationCard({
    required this.beneficiary,
    required this.onActionComplete,
  });

  @override
  ConsumerState<_BeneficiaryVerificationCard> createState() =>
      _BeneficiaryVerificationCardState();
}

class _BeneficiaryVerificationCardState
    extends ConsumerState<_BeneficiaryVerificationCard> {
  bool _isExpanded = false;
  bool _isProcessing = false;

  Future<void> _verify() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Beneficiary'),
        content: Text(
            'Verify ${widget.beneficiary.name} for member '
                '${widget.beneficiary.userName ?? "unknown"}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final repo =
      await ref.read(beneficiaryRepositoryProvider.future);
      await repo.verifyBeneficiary(widget.beneficiary.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beneficiary verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onActionComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Beneficiary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Reason is required')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final repo =
      await ref.read(beneficiaryRepositoryProvider.future);
      // POST /beneficiary/{uuid}/reject/ with { reason: "..." }
      await repo.rejectBeneficiary(
        widget.beneficiary.id,
        reason: reasonController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beneficiary rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onActionComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.beneficiary;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                b.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            title: Text(b.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${b.relationDisplay ?? b.relation} • '
                      '${b.age} yrs • '
                      '${b.genderDisplay ?? b.gender}',
                ),
                if (b.userName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Member: ${b.userName}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (b.percentageAllocation > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Allocation: ${b.percentageAllocation.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 12, color: Colors.blue.shade600),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () =>
                  setState(() => _isExpanded = !_isExpanded),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Phone', b.phoneNumber ?? 'N/A'),
                  _detailRow('Profession', b.profession ?? 'N/A'),
                  _detailRow('Salary Range', b.salaryRange ?? 'N/A'),
                  const SizedBox(height: 16),
                  const Text('Documents',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (b.identityDocument != null)
                    _docChip('Identity Document', Icons.badge),
                  if (b.birthCertificate != null)
                    _docChip('Birth Certificate', Icons.description),
                  if (b.identityDocument == null &&
                      b.birthCertificate == null)
                    const Text('No documents uploaded',
                        style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _reject,
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                  color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _verify,
                            icon: const Icon(Icons.check),
                            label: const Text('Verify'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _docChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        backgroundColor: Colors.blue.shade50,
      ),
    );
  }
}
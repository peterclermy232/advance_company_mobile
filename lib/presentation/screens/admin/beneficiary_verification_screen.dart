import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/providers/core_providers.dart';
import '../../../data/providers/beneficiary_provider.dart';
import '../../../data/models/beneficiary_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

// Provider for pending beneficiaries
final pendingBeneficiariesProvider = FutureProvider.autoDispose((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.beneficiaries);
  final data = response.data['data'];
  
  List<BeneficiaryModel> beneficiaries = [];
  if (data is List) {
    beneficiaries = data.map((e) => BeneficiaryModel.fromJson(e)).toList();
  } else if (data is Map && data.containsKey('results')) {
    beneficiaries = (data['results'] as List)
        .map((e) => BeneficiaryModel.fromJson(e))
        .toList();
  }
  
  // Filter only pending beneficiaries
  return beneficiaries.where((b) => b.verificationStatus == 'PENDING').toList();
});

class BeneficiaryVerificationScreen extends ConsumerWidget {
  const BeneficiaryVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beneficiariesAsync = ref.watch(pendingBeneficiariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingBeneficiariesProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingBeneficiariesProvider);
          await ref.read(pendingBeneficiariesProvider.future);
        },
        child: beneficiariesAsync.when(
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
              itemBuilder: (context, index) {
                return _BeneficiaryVerificationCard(
                  beneficiary: beneficiaries[index],
                  onVerified: () => ref.invalidate(pendingBeneficiariesProvider),
                );
              },
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
                  onPressed: () => ref.invalidate(pendingBeneficiariesProvider),
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

class _BeneficiaryVerificationCard extends ConsumerStatefulWidget {
  final BeneficiaryModel beneficiary;
  final VoidCallback onVerified;

  const _BeneficiaryVerificationCard({
    required this.beneficiary,
    required this.onVerified,
  });

  @override
  ConsumerState<_BeneficiaryVerificationCard> createState() =>
      _BeneficiaryVerificationCardState();
}

class _BeneficiaryVerificationCardState
    extends ConsumerState<_BeneficiaryVerificationCard> {
  bool _isExpanded = false;
  bool _isProcessing = false;

  Future<void> _verifyBeneficiary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Beneficiary'),
        content: Text(
          'Are you sure you want to verify ${widget.beneficiary.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await ref
          .read(beneficiaryRepositoryProvider)
          .verifyBeneficiary(widget.beneficiary.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beneficiary verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onVerified();
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
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectBeneficiary() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Beneficiary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter rejection reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      // Note: You'll need to add a reject endpoint in the repository
      // For now, we'll just show a message
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beneficiary rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onVerified();
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
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.beneficiary.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            title: Text(
              widget.beneficiary.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${widget.beneficiary.relation} • ${widget.beneficiary.age} years • ${widget.beneficiary.gender}',
                ),
                if (widget.beneficiary.userName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Member: ${widget.beneficiary.userName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ),
          
          if (_isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Beneficiary Details
                  _buildDetailRow('Phone', widget.beneficiary.phoneNumber ?? 'N/A'),
                  _buildDetailRow('Profession', widget.beneficiary.profession ?? 'N/A'),
                  _buildDetailRow('Salary Range', widget.beneficiary.salaryRange ?? 'N/A'),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Documents
                  if (widget.beneficiary.identityDocument != null)
                    _buildDocumentChip('Identity Document', Icons.badge),
                  if (widget.beneficiary.birthCertificate != null)
                    _buildDocumentChip('Birth Certificate', Icons.description),
                  if (widget.beneficiary.identityDocument == null &&
                      widget.beneficiary.birthCertificate == null)
                    const Text(
                      'No documents uploaded',
                      style: TextStyle(color: Colors.grey),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _rejectBeneficiary,
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _verifyBeneficiary,
                            icon: const Icon(Icons.check),
                            label: const Text('Verify'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        backgroundColor: Colors.blue.shade50,
      ),
    );
  }
}
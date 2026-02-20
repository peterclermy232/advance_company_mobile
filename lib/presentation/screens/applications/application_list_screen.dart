import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/application_type_model.dart';
import '../../../data/providers/application_providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

class ApplicationListScreen extends ConsumerWidget {
  const ApplicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(applicationsProvider.notifier).refresh(),
        child: applicationsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(applicationsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (applications) {
            if (applications.isEmpty) {
              return EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No Applications',
                message: 'Submit applications for loans, withdrawals, or '
                    'membership changes',
                action: ElevatedButton.icon(
                  onPressed: () => context.push('/applications/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New Application'),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ApplicationCard(application: applications[index]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/applications/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Application'),
      ),
    );
  }
}

// ─── Application Card ─────────────────────────────────────────────────────────

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.application});

  final ApplicationModel application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use status colour from the choices provider if available,
    // otherwise fall back to a local default.
    final statusChoicesAsync = ref.watch(statusChoicesProvider);
    final Color statusColor = statusChoicesAsync.whenOrNull(
      data: (choices) {
        final match = choices.cast<StatusChoiceModel?>().firstWhere(
              (c) => c?.value == application.status,
          orElse: () => null,
        );
        return match != null ? Color(match.colorValue) : null;
      },
    ) ??
        _defaultColor(application.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    application.applicationTypeLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  label: application.status.replaceAll('_', ' ').toUpperCase(),
                  color: statusColor,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Reason
            Text(
              application.reason,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Submitted date
            const SizedBox(height: 8),
            Text(
              'Submitted ${_formatDate(application.submittedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),

            // Admin comments
            if (application.adminComments != null &&
                application.adminComments!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment,
                        color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        application.adminComments!,
                        style: TextStyle(color: Colors.blue.shade900),
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

  Color _defaultColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'under_review':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme_config.dart';
import '../../../data/models/application_model.dart';
import '../../../data/providers/application_providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/custom_button.dart';

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
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
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
                action: SizedBox(
                  width: 220,
                  child: CustomButton(
                    gradient: true,
                    onPressed: () => context.push('/applications/new'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text('New Application'),
                      ],
                    ),
                  ),
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

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final ApplicationModel application;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    application.applicationTypeLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge.fromStatus(application.status),
              ],
            ),

            const SizedBox(height: 10),

            // Reason
            Text(
              application.reason,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Submitted date
            const SizedBox(height: 8),
            Text(
              'Submitted ${_formatDate(application.submittedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // Admin comments
            if (application.adminComments != null &&
                application.adminComments!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        application.adminComments!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
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

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

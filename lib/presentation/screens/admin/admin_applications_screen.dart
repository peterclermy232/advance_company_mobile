import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme_config.dart';
import '../../../data/models/application_model.dart';
import '../../../data/providers/application_providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/status_badge.dart';

class AdminApplicationsScreen extends ConsumerWidget {
  const AdminApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(applicationsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(applicationsProvider.notifier).refresh(),
        child: applicationsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('$e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(applicationsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (apps) {
            // Sort: pending first, then under_review, then rest
            final sorted = [...apps]..sort((a, b) {
                const order = {
                  'pending': 0,
                  'under_review': 1,
                  'approved': 2,
                  'rejected': 3,
                };
                return (order[a.status] ?? 9).compareTo(order[b.status] ?? 9);
              });

            if (sorted.isEmpty) {
              return const EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No Applications',
                message: 'No applications have been submitted yet.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _AdminApplicationCard(application: sorted[i]),
            );
          },
        ),
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _AdminApplicationCard extends ConsumerStatefulWidget {
  final ApplicationModel application;
  const _AdminApplicationCard({required this.application});

  @override
  ConsumerState<_AdminApplicationCard> createState() =>
      _AdminApplicationCardState();
}

class _AdminApplicationCardState extends ConsumerState<_AdminApplicationCard> {
  bool _isProcessing = false;

  Color get _statusColor {
    switch (widget.application.status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'under_review':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  StatusKind get _statusKind {
    switch (widget.application.status) {
      case 'approved':
        return StatusKind.success;
      case 'rejected':
        return StatusKind.error;
      case 'under_review':
        return StatusKind.info;
      default:
        return StatusKind.warning;
    }
  }

  String get _statusLabel {
    final words = widget.application.status.split('_');
    return words
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Future<void> _doAction(Future<void> Function() action) async {
    setState(() => _isProcessing = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Done!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _approve() async {
    final commentsCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Approve ${widget.application.applicationTypeLabel} '
              'from ${widget.application.userName ?? "member"}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentsCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin Comments (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _doAction(() => ref
        .read(applicationsProvider.notifier)
        .approveApplication(widget.application.id,
            comments: commentsCtrl.text));
  }

  Future<void> _reject() async {
    final commentsCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a rejection reason:'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsCtrl,
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentsCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Reason is required')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _doAction(() => ref
        .read(applicationsProvider.notifier)
        .rejectApplication(widget.application.id, comments: commentsCtrl.text));
  }

  Future<void> _markReview() async {
    await _doAction(() => ref
        .read(applicationsProvider.notifier)
        .markUnderReview(widget.application.id));
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _statusColor.withOpacity(0.15),
                  child: Text(
                    (app.userName?.isNotEmpty == true ? app.userName! : '?')[0]
                        .toUpperCase(),
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.userName ?? 'Unknown Member',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Submitted ${dateFormat.format(app.submittedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: _statusLabel,
                  kind: _statusKind,
                ),
              ],
            ),

            const Divider(height: 20),

            // Type & Reason
            Text(
              app.applicationTypeLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              app.reason,
              style:
                  const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),

            // Document chip
            if (app.supportingDocument != null) ...[
              const SizedBox(height: 10),
              Chip(
                avatar: const Icon(Icons.attach_file, size: 16),
                label: const Text('Supporting Document'),
                backgroundColor: AppColors.infoBg,
              ),
            ],

            // Admin comments
            if (app.adminComments != null && app.adminComments!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(app.adminComments!)),
                  ],
                ),
              ),
            ],

            // Action buttons (only for pending / under_review)
            if (app.isPending || app.isUnderReview) ...[
              const SizedBox(height: 16),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    if (app.isPending)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _markReview,
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Mark Under Review'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.info,
                            side: const BorderSide(color: AppColors.info),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _reject,
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _approve,
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

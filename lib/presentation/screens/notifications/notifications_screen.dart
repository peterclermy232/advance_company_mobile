import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../config/theme_config.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/status_badge.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              // notificationRepositoryProvider is now a plain Provider
              final repo = ref.read(notificationRepositoryProvider);
              await repo.markAllAsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_outlined,
                title: 'No Notifications',
                message: 'You\'re all caught up!',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = !notification.isRead;
                final chipColor =
                    _getNotificationColor(notification.notificationType);

                return Material(
                  color: isUnread ? AppColors.infoBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () async {
                      if (isUnread) {
                        final repo =
                            ref.read(notificationRepositoryProvider);
                        await repo.markAsRead(notification.id);
                        ref.invalidate(notificationsProvider);
                        ref.invalidate(unreadCountProvider);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: isUnread
                            ? null
                            : Border.all(color: AppColors.border),
                        boxShadow:
                            isUnread ? null : AppColors.cardShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconChip(
                            icon: _getNotificationIcon(
                                notification.notificationType),
                            color: chipColor,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                    fontWeight: isUnread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notification.timeAgo,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    // API returns lowercase snake_case
    switch (type.toLowerCase()) {
      case 'deposit_approved':
      case 'deposit_rejected':
      case 'deposit_created':
        return Icons.account_balance_wallet;
      case 'application_approved':
      case 'application_rejected':
      case 'application_submitted':
        return Icons.assignment;
      case 'beneficiary_verified':
        return Icons.people;
      case 'document_verified':
      case 'document_rejected':
        return Icons.file_copy;
      default:
        return Icons.notifications;
    }
  }

  /// Maps notification type to the semantic status color, mirroring the
  /// web's approved=green / rejected=red / submitted=blue conventions.
  Color _getNotificationColor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('rejected') || normalized.contains('failed')) {
      return AppColors.error;
    }
    if (normalized.contains('approved') || normalized.contains('verified')) {
      return AppColors.success;
    }
    if (normalized.contains('submitted') || normalized.contains('created')) {
      return AppColors.info;
    }
    return AppColors.neutral;
  }
}

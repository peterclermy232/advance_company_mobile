import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/notification_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final notificationRepository =
              await ref.read(notificationRepositoryProvider.future);
              await notificationRepository.markAllAsRead();
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
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? Colors.grey.shade100
                          : Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.notificationType),
                      color: notification.isRead ? Colors.grey : Colors.blue,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification.message),
                      const SizedBox(height: 4),
                      Text(
                        notification.timeAgo,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () async {
                    if (!notification.isRead) {
                      final notificationRepository =
                      await ref.read(notificationRepositoryProvider.future);
                      await notificationRepository.markAsRead(notification.id);
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadCountProvider);
                    }
                  },
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
}
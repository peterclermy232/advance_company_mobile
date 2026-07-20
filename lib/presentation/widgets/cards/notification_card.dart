import 'package:flutter/material.dart';
import '../../../config/theme_config.dart';
import '../../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead ? null : AppColors.infoBg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? AppColors.neutralBg
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.notificationType),
                  color: notification.isRead
                      ? AppColors.textSecondary
                      : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
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
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
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
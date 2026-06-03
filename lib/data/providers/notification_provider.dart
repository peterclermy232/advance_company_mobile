import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/notification_repository.dart';
import '../models/notification_model.dart';

// NotificationRepository is NOT async — apiClientProvider is a plain Provider
final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});
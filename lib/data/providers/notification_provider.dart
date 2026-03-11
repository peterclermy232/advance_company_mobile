import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/notification_repository.dart';
import '../models/notification_model.dart';

// Repository Provider
final notificationRepositoryProvider = FutureProvider<NotificationRepository>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});

// Notifications List Provider
final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repository = await ref.watch(notificationRepositoryProvider.future);
  return repository.getNotifications();
});

// Unread Count Provider
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = await ref.watch(notificationRepositoryProvider.future);
  return repository.getUnreadCount();
});
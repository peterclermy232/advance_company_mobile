import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/notification_repository.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = FutureProvider<NotificationRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return NotificationRepository(apiClient);
});

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repository = await ref.watch(notificationRepositoryProvider.future);
  return repository.getNotifications();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final repository = await ref.watch(notificationRepositoryProvider.future);
  return repository.getUnreadCount();
});
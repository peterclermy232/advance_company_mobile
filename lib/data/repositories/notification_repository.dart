// ============================================
// lib/data/repositories/notification_repository.dart
// ============================================
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get(ApiEndpoints.notifications);
    final data = response.data['data'];
    
    if (data is List) {
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    } else if (data is Map && data.containsKey('results')) {
      return (data['results'] as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.unreadCount);
    return response.data['count'] as int;
  }

  Future<void> markAsRead(int id) async {
    await _apiClient.post(ApiEndpoints.markAsRead(id), data: {});
  }

  Future<void> markAllAsRead() async {
    await _apiClient.post(ApiEndpoints.markAllAsRead, data: {});
  }
}
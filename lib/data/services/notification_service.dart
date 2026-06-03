// lib/data/services/notification_service.dart
// Notification retrieval and management service

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService({required ApiClient apiClient}) : _apiClient = apiClient;

  // ─────────────────────────────────────────────────────────────────────────────
  // Notification Retrieval
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all notifications (paginated)
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get notification by UUID
  Future<NotificationModel> getNotificationByUuid(String uuid) async {
    final response =
        await _apiClient.get(ApiEndpoints.notificationDetail(uuid));
    return NotificationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get unread notifications (paginated)
  Future<Map<String, dynamic>> getUnreadNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.unreadNotifications,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get count of unread notifications
  /// Returns: { "unread_count": N }
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.unreadCount);
    return response.data['unread_count'] as int;
  }

  /// Get recent notifications (limited set)
  /// Returns: List of recent notifications
  Future<List<NotificationModel>> getRecentNotifications({
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.recentNotifications,
      queryParameters: {'limit': limit},
    );
    if (response.data is List) {
      return (response.data as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Notification Actions
  // ─────────────────────────────────────────────────────────────────────────────

  /// Mark single notification as read
  Future<NotificationModel> markAsRead(String uuid) async {
    final response = await _apiClient.post(
      ApiEndpoints.markAsRead(uuid),
    );
    return NotificationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _apiClient.post(ApiEndpoints.markAllAsRead);
  }

  /// Delete single notification
  Future<void> deleteNotification(String uuid) async {
    await _apiClient.delete(ApiEndpoints.deleteNotification(uuid));
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    await _apiClient.delete(ApiEndpoints.clearAll);
  }
}

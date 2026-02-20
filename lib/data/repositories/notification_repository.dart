import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get(ApiEndpoints.notifications);
    final raw = response.data;

    List<dynamic> list;

    if (raw is List) {
      // Plain list response
      list = raw;
    } else if (raw is Map && raw.containsKey('results')) {
      // Paginated response: { count, next, previous, results: [...] }
      list = raw['results'] as List;
    } else if (raw is Map && raw.containsKey('data')) {
      final data = raw['data'];
      if (data is List) {
        list = data;
      } else if (data is Map && data.containsKey('results')) {
        list = data['results'] as List;
      } else {
        return [];
      }
    } else {
      return [];
    }

    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.unreadCount);
    final raw = response.data;
    // Handle both { count: 5 } and { data: { count: 5 } }
    if (raw is Map && raw.containsKey('data')) {
      return (raw['data']['count'] as num).toInt();
    }
    return (raw['count'] as num).toInt();
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.post(ApiEndpoints.markAsRead(id));
  }

  Future<void> markAllAsRead() async {
    await _apiClient.post(ApiEndpoints.markAllAsRead, data: {});
  }
}
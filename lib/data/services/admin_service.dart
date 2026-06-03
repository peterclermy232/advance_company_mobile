// lib/data/services/admin_service.dart
// Admin analytics and management service (admin only)

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class AdminService {
  final ApiClient _apiClient;

  AdminService({required ApiClient apiClient}) : _apiClient = apiClient;

  // ─────────────────────────────────────────────────────────────────────────────
  // Admin Analytics (Admin Only)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get members analytics (admin only)
  /// Returns: Member statistics including registrations, activity, etc.
  Future<Map<String, dynamic>> getMembersAnalytics({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.adminMembers,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get analytics summary (admin only)
  /// Returns: { "total_members": N, "total_deposits": N, "total_interest": N,
  ///   "pending_approvals": N, "member_trends": [...], ... }
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final response = await _apiClient.get(ApiEndpoints.adminSummary);
    return response.data as Map<String, dynamic>;
  }

  /// Export analytics data (admin only)
  /// Query params: { "format": "excel" | "pdf" }
  /// Returns: File URL or file content
  Future<Map<String, dynamic>> exportAnalytics({
    required String format, // excel or pdf
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.adminExport,
      queryParameters: {'format': format},
    );
    return response.data as Map<String, dynamic>;
  }
}

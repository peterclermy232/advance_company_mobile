// lib/data/services/report_service.dart
// Report generation and retrieval service

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class ReportService {
  final ApiClient _apiClient;

  ReportService({required ApiClient apiClient}) : _apiClient = apiClient;

  // ─────────────────────────────────────────────────────────────────────────────
  // Report Retrieval
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all reports (paginated)
  Future<Map<String, dynamic>> getReports({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.reports,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get report by UUID (returns report metadata)
  Future<Map<String, dynamic>> getReportByUuid(String uuid) async {
    final response = await _apiClient.get(ApiEndpoints.reportDetail(uuid));
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Report Generation
  // ─────────────────────────────────────────────────────────────────────────────

  /// Generate financial report
  /// Body: { "start_date": "2024-01-01", "end_date": "2024-12-31" }
  /// Returns: Generated report data/file URL
  Future<Map<String, dynamic>> generateFinancialReport({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.generateFinancialReport,
      data: {
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Generate compensatory report
  /// Body: { "start_date": "2024-01-01", "end_date": "2024-12-31" }
  /// Returns: Generated report data/file URL
  Future<Map<String, dynamic>> generateCompensatoryReport({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.generateCompensatoryReport,
      data: {
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Generate activity report
  /// Body: { "start_date": "2024-01-01", "end_date": "2024-12-31" }
  /// Returns: Generated report data/file URL
  Future<Map<String, dynamic>> generateActivityReport({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.generateActivityReport,
      data: {
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Resend report via email
  Future<void> resendReportEmail(String uuid) async {
    await _apiClient.post(ApiEndpoints.resendReportEmail(uuid));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Dashboard & Summary Data
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get dashboard summary for current user
  /// Returns: { "total_deposits": N, "pending_approvals": N, "total_interest": N, ... }
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await _apiClient.get(ApiEndpoints.dashboardSummary);
    return response.data as Map<String, dynamic>;
  }

  /// Get general report summary
  /// Returns: Summary statistics
  Future<Map<String, dynamic>> getReportSummary() async {
    final response = await _apiClient.get(ApiEndpoints.reportSummary);
    return response.data as Map<String, dynamic>;
  }

  /// Get deposit trends
  /// Returns: { "month": "...", "amount": N, "count": N, ... }
  Future<List<Map<String, dynamic>>> getDepositTrends() async {
    final response = await _apiClient.get(ApiEndpoints.depositTrends);
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data as List);
    }
    return [];
  }

  /// Get activity logs (paginated)
  /// Returns: User activity history
  Future<Map<String, dynamic>> getActivityLogs({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.activityLogs,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }
}

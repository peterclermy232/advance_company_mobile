// lib/data/services/health_service.dart
// Health check and system metrics service

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class HealthService {
  final ApiClient _apiClient;

  HealthService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Health check endpoint (public)
  /// Returns: { "status": "healthy", "version": "1.0.0", ... }
  Future<Map<String, dynamic>> health() async {
    final response = await _apiClient.get(ApiEndpoints.health);
    return response.data as Map<String, dynamic>;
  }

  /// System metrics endpoint (public)
  /// Returns: System performance metrics
  Future<Map<String, dynamic>> getMetrics() async {
    final response = await _apiClient.get(ApiEndpoints.metrics);
    return response.data as Map<String, dynamic>;
  }
}


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/dashboard_summary_model.dart';
import 'core_providers.dart';

final dashboardSummaryProvider =
FutureProvider<DashboardSummaryModel>((ref) async {
  // Same pattern as financialAccountProvider, depositsProvider, etc.
  final apiClient = await ref.watch(apiClientProvider.future);

  final response = await apiClient.get(ApiEndpoints.dashboardSummary);

  final raw     = response.data;
  final payload = (raw is Map && raw['data'] != null) ? raw['data'] : raw;

  return DashboardSummaryModel.fromJson(payload as Map<String, dynamic>);
});
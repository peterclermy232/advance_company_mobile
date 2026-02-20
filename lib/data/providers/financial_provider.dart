import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/deposit_model.dart';
import '../models/financial_account_model.dart';
import 'core_providers.dart';

// ─── Financial Account ────────────────────────────────────────────────────────

final financialAccountProvider =
FutureProvider.autoDispose<FinancialAccountModel>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final response = await apiClient.get(ApiEndpoints.myAccount);
  final raw = response.data;
  final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
  return FinancialAccountModel.fromJson(Map<String, dynamic>.from(data as Map));
});

// ─── Deposits list ────────────────────────────────────────────────────────────

final depositsProvider =
FutureProvider.autoDispose<List<DepositModel>>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final response = await apiClient.get(ApiEndpoints.deposits);

  final raw = response.data;
  final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;

  if (data is List) {
    return data.map((e) => DepositModel.fromJson(e)).toList();
  } else if (data is Map && data.containsKey('results')) {
    return (data['results'] as List)
        .map((e) => DepositModel.fromJson(e))
        .toList();
  }
  return [];
});

// ─── Financial Repository ─────────────────────────────────────────────────────

class FinancialRepository {
  final dynamic _apiClient;

  FinancialRepository(this._apiClient);

  Future<void> approveDeposit(String id) async {
    await _apiClient.post(ApiEndpoints.approveDeposit(id));
  }

  Future<void> rejectDeposit(String id, String reason) async {
    await _apiClient.post(
      ApiEndpoints.rejectDeposit(id),
      data: {'rejection_reason': reason},
    );
  }

  Future<void> createDeposit(Map<String, dynamic> data) async {
    await _apiClient.post(ApiEndpoints.createDeposit, data: data);
  }

  Future<Map<String, dynamic>> canDeposit() async {
    final response = await _apiClient.get(ApiEndpoints.canDeposit);
    final raw = response.data;
    return (raw is Map && raw['data'] != null)
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : Map<String, dynamic>.from(raw as Map);
  }
}

final financialRepositoryProvider =
FutureProvider<FinancialRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return FinancialRepository(apiClient);
});
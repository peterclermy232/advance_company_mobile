// lib/data/repositories/financial_repository.dart
//
// Single canonical FinancialRepository.
// The duplicate class in financial_provider.dart has been removed.

import '../models/deposit_model.dart';
import '../models/financial_account_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';

class FinancialRepository {
  final ApiClient _api;

  const FinancialRepository(this._api);

  // ── Account ─────────────────────────────────────────────────────────────────

  Future<FinancialAccountModel> getMyAccount() async {
    final res = await _api.get(ApiEndpoints.myAccount);
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    return FinancialAccountModel.fromJson(data as Map<String, dynamic>);
  }

  // ── Deposits ─────────────────────────────────────────────────────────────────

  Future<List<DepositModel>> getDeposits({
    int page = 1,
    int pageSize = 20,
    DepositStatus? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (status != null) 'status': status.name,
    };
    final res = await _api.get(ApiEndpoints.deposits, queryParameters: params);
    final raw  = res.data;
    final data = (raw is Map && raw['results'] != null)
        ? raw['results'] as List
        : raw as List;
    return data.map((e) => DepositModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DepositModel> getDeposit(int id) async {
    final res = await _api.get('${ApiEndpoints.depositDetail}$id/');
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    return DepositModel.fromJson(data as Map<String, dynamic>);
  }

  /// Initiates an M-Pesa STK Push. Returns the created DepositModel.
  Future<DepositModel> createDeposit({
    required double amount,
    required String phoneNumber,
    String method = 'mpesa',
  }) async {
    final res = await _api.post(
      ApiEndpoints.createDeposit,
      data: {
        'amount': amount,
        'phone_number': phoneNumber,
        'method': method,
      },
    );
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    return DepositModel.fromJson(data as Map<String, dynamic>);
  }

  // ── Monthly limit check ──────────────────────────────────────────────────────

  Future<Map<String, double>> getMonthlyLimit() async {
    final res = await _api.get(ApiEndpoints.monthlyLimit);
    final data = res.data is Map ? res.data as Map<String, dynamic> : <String, dynamic>{};
    return {
      'limit': (data['limit'] as num?)?.toDouble() ?? 20000.0,
      'used':  (data['used']  as num?)?.toDouble() ?? 0.0,
    };
  }
}
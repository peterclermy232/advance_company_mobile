// ============================================
// lib/data/repositories/financial_repository.dart
// ============================================
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/deposit_model.dart';
import '../models/financial_account_model.dart';

class FinancialRepository {
  final ApiClient _apiClient;

  FinancialRepository(this._apiClient);

  Future<FinancialAccountModel> getMyAccount() async {
    final response = await _apiClient.get(ApiEndpoints.myAccount);
    return FinancialAccountModel.fromJson(response.data['data']);
  }

  Future<List<DepositModel>> getDeposits() async {
    final response = await _apiClient.get(ApiEndpoints.deposits);
    final data = response.data['data'];
    
    if (data is List) {
      return data.map((e) => DepositModel.fromJson(e)).toList();
    } else if (data is Map && data.containsKey('results')) {
      return (data['results'] as List)
          .map((e) => DepositModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<DepositModel> createDeposit(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiEndpoints.createDeposit,
      data: data,
    );
    return DepositModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> canDeposit() async {
    final response = await _apiClient.get(ApiEndpoints.canDeposit);
    return response.data['data'];
  }

  Future<List<Map<String, dynamic>>> getMonthlySummary() async {
    final response = await _apiClient.get(ApiEndpoints.monthlySummary);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<void> approveDeposit(int depositId) async {
    await _apiClient.post(ApiEndpoints.approveDeposit(depositId), data: {});
  }

  Future<void> rejectDeposit(int depositId, String reason) async {
    await _apiClient.post(
      ApiEndpoints.rejectDeposit(depositId),
      data: {'reason': reason},
    );
  }
}
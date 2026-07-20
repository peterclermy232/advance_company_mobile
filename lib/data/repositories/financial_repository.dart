import '../models/deposit_model.dart';
import '../models/financial_account_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class MonthlySummary {
  final double totalDeposited;
  final double monthlyLimit;
  final double remaining;
  final int depositCount;
  final int month;
  final int year;

  const MonthlySummary({
    required this.totalDeposited,
    required this.monthlyLimit,
    required this.remaining,
    required this.depositCount,
    required this.month,
    required this.year,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    final limit = (json['monthly_limit'] as num?)?.toDouble() ?? 0.0;
    final deposited = (json['total_deposited'] as num?)?.toDouble() ?? 0.0;
    return MonthlySummary(
      totalDeposited: deposited,
      monthlyLimit: limit,
      remaining: (json['remaining'] as num?)?.toDouble() ?? (limit - deposited),
      depositCount: json['deposit_count'] as int? ?? 0,
      month: json['month'] as int? ?? DateTime.now().month,
      year: json['year'] as int? ?? DateTime.now().year,
    );
  }
}

class FinancialRepository {
  final ApiClient _apiClient;

  FinancialRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ── Account ──────────────────────────────────────────────────────────────

  Future<FinancialAccountModel> getMyAccount() async {
    final response = await _apiClient.get(ApiEndpoints.myAccount);
    return FinancialAccountModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Deposits ─────────────────────────────────────────────────────────────

  Future<List<DepositModel>> getDeposits({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.deposits,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null) 'status': status,
      },
    );
    final data = response.data;
    final List<dynamic> results;
    if (data is List) {
      results = data;
    } else if (data is Map && data.containsKey('results')) {
      results = data['results'] as List<dynamic>;
    } else {
      results = [];
    }
    return results
        .map((e) => DepositModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DepositModel> getDepositDetail(int id) async {
    final response = await _apiClient.get(ApiEndpoints.depositDetail(id.toString()));
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DepositModel> createDeposit({
    required double amount,
    required String method,
    String? phoneNumber,
    String? mpesaTransactionId,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.createDeposit,
      data: {
        'amount': amount,
        'payment_method': method,
        if (phoneNumber != null) 'mpesa_phone': phoneNumber,
        if (mpesaTransactionId != null)
          'mpesa_transaction_id': mpesaTransactionId,
        if (notes != null) 'notes': notes,
      },
    );
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Monthly summary ───────────────────────────────────────────────────────

  Future<MonthlySummary> getMonthlySummary() async {
    final response = await _apiClient.get(ApiEndpoints.monthlySummary);
    return MonthlySummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<double> getMonthlyLimit() async {
    final response = await _apiClient.get(ApiEndpoints.monthlyLimit);
    final data = response.data as Map<String, dynamic>;
    return (data['monthly_limit'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>> canDeposit(double amount) async {
    final response = await _apiClient.get(
      ApiEndpoints.canDeposit,
      queryParameters: {'amount': amount},
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  Future<List<DepositModel>> getPendingApprovals() async {
    final response = await _apiClient.get(ApiEndpoints.pendingApprovals);
    final data = response.data;
    final List<dynamic> results = data is List
        ? data
        : (data is Map && data.containsKey('results')
        ? data['results'] as List<dynamic>
        : []);
    return results
        .map((e) => DepositModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DepositModel> approveDeposit(String id) async {
    final response = await _apiClient.post(ApiEndpoints.approveDeposit(id));
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DepositModel> rejectDeposit(String id, {String? reason}) async {
    final response = await _apiClient.post(
      ApiEndpoints.rejectDeposit(id),
      data: reason != null ? {'reason': reason} : null,
    );
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }
}
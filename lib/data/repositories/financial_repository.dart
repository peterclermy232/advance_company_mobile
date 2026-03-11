import 'package:dio/dio.dart';
import '../models/deposit_model.dart';
import '../../core/constants/api_endpoints.dart';

class AccountModel {
  final int id;
  final String accountNumber;
  final double balance;
  final double totalDeposited;
  final double monthlyTarget;
  final bool isActive;

  const AccountModel({
    required this.id,
    required this.accountNumber,
    required this.balance,
    required this.totalDeposited,
    required this.monthlyTarget,
    required this.isActive,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int,
      accountNumber: json['account_number'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      totalDeposited: (json['total_deposited'] as num?)?.toDouble() ?? 0.0,
      monthlyTarget: (json['monthly_target'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

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
  final Dio _dio;

  FinancialRepository({required Dio dio}) : _dio = dio;

  // -------------------------------------------------------------------------
  // Account
  // -------------------------------------------------------------------------
  Future<AccountModel> getMyAccount() async {
    final response = await _dio.get(ApiEndpoints.myAccount);
    return AccountModel.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Deposits list
  // -------------------------------------------------------------------------
  Future<List<DepositModel>> getDeposits({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (status != null) 'status': status,
    };
    final response = await _dio.get(
      ApiEndpoints.deposits,
      queryParameters: queryParams,
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

  // -------------------------------------------------------------------------
  // Deposit detail — uses ApiEndpoints.depositDetail base path + id
  // -------------------------------------------------------------------------
  Future<DepositModel> getDepositDetail(int id) async {
    final response = await _dio.get('${ApiEndpoints.depositDetail}$id/');
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Create deposit
  // -------------------------------------------------------------------------
  Future<DepositModel> createDeposit({
    required double amount,
    required String method,
    String? phoneNumber,
    String? mpesaTransactionId,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.createDeposit,
      data: {
        'amount': amount,
        'method': method,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (mpesaTransactionId != null)
          'mpesa_transaction_id': mpesaTransactionId,
        if (notes != null) 'notes': notes,
      },
    );
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Monthly summary — uses ApiEndpoints.monthlySummary (correct endpoint)
  // -------------------------------------------------------------------------
  Future<MonthlySummary> getMonthlySummary() async {
    final response = await _dio.get(ApiEndpoints.monthlySummary);
    return MonthlySummary.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Monthly limit — uses ApiEndpoints.monthlyLimit (previously missing)
  // -------------------------------------------------------------------------
  Future<double> getMonthlyLimit() async {
    final response = await _dio.get(ApiEndpoints.monthlyLimit);
    final data = response.data as Map<String, dynamic>;
    return (data['monthly_limit'] as num?)?.toDouble() ?? 0.0;
  }

  // -------------------------------------------------------------------------
  // Can deposit check
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> canDeposit(double amount) async {
    final response = await _dio.get(
      ApiEndpoints.canDeposit,
      queryParameters: {'amount': amount},
    );
    return response.data as Map<String, dynamic>;
  }

  // -------------------------------------------------------------------------
  // Pending approvals (admin)
  // -------------------------------------------------------------------------
  Future<List<DepositModel>> getPendingApprovals() async {
    final response = await _dio.get(ApiEndpoints.pendingApprovals);
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

  // -------------------------------------------------------------------------
  // Approve / reject deposit (admin)
  // -------------------------------------------------------------------------
  Future<DepositModel> approveDeposit(String id) async {
    final response = await _dio.post(ApiEndpoints.approveDeposit(id));
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DepositModel> rejectDeposit(String id, {String? reason}) async {
    final response = await _dio.post(
        ApiEndpoints.rejectDeposit(id),
        data: if (reason != null) {'reason': reason} else null,
    );
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }
}
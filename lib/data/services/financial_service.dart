// lib/data/services/financial_service.dart
// Financial service for accounts, deposits, and interest endpoints

import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/financial_account_model.dart';
import '../models/deposit_model.dart';

class FinancialService {
  final ApiClient _apiClient;

  FinancialService({required ApiClient apiClient}) : _apiClient = apiClient;

  // ─────────────────────────────────────────────────────────────────────────────
  // Accounts (Protected)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all accounts
  Future<List<FinancialAccountModel>> getAccounts() async {
    final response = await _apiClient.get(ApiEndpoints.accounts);
    return (response.data as List)
        .map((e) => FinancialAccountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get account by UUID
  Future<FinancialAccountModel> getAccountByUuid(String uuid) async {
    final response = await _apiClient.get(ApiEndpoints.accountDetail(uuid));
    return FinancialAccountModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Get current user's account
  Future<FinancialAccountModel> getMyAccount() async {
    final response = await _apiClient.get(ApiEndpoints.myAccount);
    return FinancialAccountModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Deposits
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all deposits (paginated)
  /// Returns: { "count": N, "next": "...", "previous": "...", "results": [...] }
  Future<Map<String, dynamic>> getDeposits({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.deposits,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Create deposit
  /// Body: { "payment_method": "mpesa|bank|mansa_x", "mpesa_phone": "254712345678", "notes": "..." }
  /// Monthly deposit amount is fixed at KES 20000.00
  Future<DepositModel> createDeposit({
    required String paymentMethod,
    String? mpesaPhone,
    String? bankAccountNumber,
    String? notes,
    String? supportingDocument,
  }) async {
    final data = <String, dynamic>{
      'payment_method': paymentMethod,
      if (mpesaPhone != null) 'mpesa_phone': mpesaPhone,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      if (notes != null) 'notes': notes,
    };

    FormData formData;
    if (supportingDocument != null) {
      formData = FormData.fromMap({
        ...data,
        'supporting_document': await MultipartFile.fromFile(supportingDocument),
      });
      final response = await _apiClient.post(
        ApiEndpoints.deposits,
        data: formData,
      );
      return DepositModel.fromJson(response.data as Map<String, dynamic>);
    } else {
      final response = await _apiClient.post(
        ApiEndpoints.deposits,
        data: data,
      );
      return DepositModel.fromJson(response.data as Map<String, dynamic>);
    }
  }

  /// Get deposit by UUID
  Future<DepositModel> getDepositByUuid(String uuid) async {
    final response = await _apiClient.get(ApiEndpoints.depositDetail(uuid));
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Check if user can deposit this month
  /// Returns: { "can_deposit": true/false, "reason": "..." }
  Future<Map<String, dynamic>> canDeposit() async {
    final response = await _apiClient.get(ApiEndpoints.canDeposit);
    return response.data as Map<String, dynamic>;
  }

  /// Get monthly deposit summary
  /// Returns deposit statistics for current month
  Future<Map<String, dynamic>> getMonthlySummary() async {
    final response = await _apiClient.get(ApiEndpoints.monthlySummary);
    return response.data as Map<String, dynamic>;
  }

  /// Get pending deposit approvals (admin only)
  Future<Map<String, dynamic>> getPendingApprovals({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.pendingApprovals,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Approve deposit (admin only)
  Future<DepositModel> approveDeposit(String uuid) async {
    final response = await _apiClient.post(
      ApiEndpoints.approveDeposit(uuid),
    );
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Reject deposit (admin only)
  /// Body: { "rejection_reason": "..." }
  Future<DepositModel> rejectDeposit(
    String uuid, {
    required String rejectionReason,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.rejectDeposit(uuid),
      data: {'rejection_reason': rejectionReason},
    );
    return DepositModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Interest
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all interest records
  Future<List<Map<String, dynamic>>> getInterest() async {
    final response = await _apiClient.get(ApiEndpoints.interest);
    return (response.data as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Get interest by UUID
  Future<Map<String, dynamic>> getInterestByUuid(String uuid) async {
    final response = await _apiClient.get(ApiEndpoints.interestDetail(uuid));
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // M-Pesa Callback (Public, used by payment provider)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Handle M-Pesa callback (public endpoint)
  Future<void> handleMpesaCallback(Map<String, dynamic> callbackData) async {
    await _apiClient.post(
      ApiEndpoints.mpesaCallback,
      data: callbackData,
    );
  }
}

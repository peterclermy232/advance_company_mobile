// lib/data/models/financial_account_model.dart

import '../../core/utils/parsing.dart';

class FinancialAccountModel {
  final String id;
  final String userId;
  final double balance;
  final double interestEarned;
  final double interestRate;
  final double monthlyDepositTotal; // how much deposited this month
  final double monthlyDepositLimit; // KES 20,000 from backend
  final String accountNumber;
  final String status; // 'active' | 'suspended' | 'closed'
  final DateTime createdAt;

  const FinancialAccountModel({
    required this.id,
    required this.userId,
    required this.balance,
    this.interestEarned = 0.0,
    this.interestRate = 0.0,
    required this.monthlyDepositTotal,
    required this.monthlyDepositLimit,
    required this.accountNumber,
    required this.status,
    required this.createdAt,
  });

  double get remainingMonthlyLimit =>
      (monthlyDepositLimit - monthlyDepositTotal).clamp(0, double.infinity);

  bool get isActive => status == 'active';

  double get limitUsagePercent {
    if (monthlyDepositLimit <= 0) return 0;
    return (monthlyDepositTotal / monthlyDepositLimit).clamp(0.0, 1.0);
  }

  factory FinancialAccountModel.fromJson(Map<String, dynamic> json) {
    // Backend's my_account/ payload has no separate "balance" field — the
    // running balance is total_contributions (+ interest, if credited).
    final totalContributions = parseDouble(json['total_contributions']);
    final interestEarned = parseDouble(json['interest_earned']);
    return FinancialAccountModel(
      id:                   json['uuid'] as String? ?? json['id']?.toString() ?? '',
      userId:               json['user'] as String? ?? json['user_id']?.toString() ?? '',
      balance:              parseDouble(json['balance'], totalContributions + interestEarned),
      interestEarned:       interestEarned,
      interestRate:         parseDouble(json['interest_rate']),
      monthlyDepositTotal:  parseDouble(json['monthly_deposit_total']),
      monthlyDepositLimit:  parseDouble(json['monthly_deposit_limit'], 20000.0),
      accountNumber:        json['account_number'] as String? ?? '',
      status:               json['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
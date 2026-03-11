// lib/data/models/financial_account_model.dart

class FinancialAccountModel {
  final int id;
  final int userId;
  final double balance;
  final double monthlyDepositTotal; // how much deposited this month
  final double monthlyDepositLimit; // KES 20,000 from backend
  final String accountNumber;
  final String status; // 'active' | 'suspended' | 'closed'
  final DateTime createdAt;

  const FinancialAccountModel({
    required this.id,
    required this.userId,
    required this.balance,
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
    return FinancialAccountModel(
      id:                   json['id'] as int,
      userId:               json['user'] as int? ?? json['user_id'] as int? ?? 0,
      balance:              (json['balance'] as num?)?.toDouble() ?? 0.0,
      monthlyDepositTotal:  (json['monthly_deposit_total'] as num?)?.toDouble() ?? 0.0,
      monthlyDepositLimit:  (json['monthly_deposit_limit'] as num?)?.toDouble() ?? 20000.0,
      accountNumber:        json['account_number'] as String? ?? '',
      status:               json['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
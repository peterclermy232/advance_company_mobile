// ============================================
// lib/data/models/financial_account_model.dart
// ============================================
class FinancialAccountModel extends Equatable {
  final int id;
  final int user;
  final String? userName;
  final String totalContributions;
  final String interestEarned;
  final String interestRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialAccountModel({
    required this.id,
    required this.user,
    this.userName,
    required this.totalContributions,
    required this.interestEarned,
    required this.interestRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FinancialAccountModel.fromJson(Map<String, dynamic> json) {
    return FinancialAccountModel(
      id: json['id'] as int,
      user: json['user'] as int,
      userName: json['user_name'] as String?,
      totalContributions: json['total_contributions'] as String,
      interestEarned: json['interest_earned'] as String,
      interestRate: json['interest_rate'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        user,
        userName,
        totalContributions,
        interestEarned,
        interestRate,
        createdAt,
        updatedAt,
      ];
}

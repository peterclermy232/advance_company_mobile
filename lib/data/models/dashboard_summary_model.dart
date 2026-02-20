// lib/data/models/dashboard_summary_model.dart

class DashboardSummaryModel {
  final double totalContributions;
  final double interestEarned;
  final double monthlyDeposits;
  final int activeBeneficiaries;
  final int totalDeposits;

  const DashboardSummaryModel({
    required this.totalContributions,
    required this.interestEarned,
    required this.monthlyDeposits,
    required this.activeBeneficiaries,
    required this.totalDeposits,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalContributions: (json['total_contributions'] as num?)?.toDouble() ?? 0.0,
      interestEarned: (json['interest_earned'] as num?)?.toDouble() ?? 0.0,
      monthlyDeposits: (json['monthly_deposits'] as num?)?.toDouble() ?? 0.0,
      activeBeneficiaries: (json['active_beneficiaries'] as num?)?.toInt() ?? 0,
      totalDeposits: (json['total_deposits'] as num?)?.toInt() ?? 0,
    );
  }

  /// Empty/loading placeholder
  factory DashboardSummaryModel.empty() {
    return const DashboardSummaryModel(
      totalContributions: 0,
      interestEarned: 0,
      monthlyDeposits: 0,
      activeBeneficiaries: 0,
      totalDeposits: 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_contributions': totalContributions,
    'interest_earned': interestEarned,
    'monthly_deposits': monthlyDeposits,
    'active_beneficiaries': activeBeneficiaries,
    'total_deposits': totalDeposits,
  };
}
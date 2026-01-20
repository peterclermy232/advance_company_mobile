
import 'package:equatable/equatable.dart';
class DashboardSummaryModel extends Equatable {
  final String totalContributions;
  final String interestEarned;
  final String monthlyDeposits;
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
      totalContributions: json['total_contributions'].toString(),
      interestEarned: json['interest_earned'].toString(),
      monthlyDeposits: json['monthly_deposits'].toString(),
      activeBeneficiaries: json['active_beneficiaries'] as int,
      totalDeposits: json['total_deposits'] as int,
    );
  }

  @override
  List<Object?> get props => [
        totalContributions,
        interestEarned,
        monthlyDeposits,
        activeBeneficiaries,
        totalDeposits,
      ];
}
import 'package:flutter/material.dart';
import '../../../config/theme_config.dart';
import '../../../data/models/beneficiary_model.dart';
import '../common/status_badge.dart';

class BeneficiaryCard extends StatelessWidget {
  final BeneficiaryModel beneficiary;
  final VoidCallback? onTap;

  const BeneficiaryCard({
    super.key,
    required this.beneficiary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String statusLabel;
    final StatusKind statusKind;

    if (beneficiary.isVerified) {
      statusKind = StatusKind.success;
      statusLabel = beneficiary.verificationStatusDisplay ?? 'Verified';
    } else if (beneficiary.isPending) {
      statusKind = StatusKind.warning;
      statusLabel = beneficiary.verificationStatusDisplay ?? 'Pending';
    } else if (beneficiary.isRejected) {
      statusKind = StatusKind.error;
      statusLabel = beneficiary.verificationStatusDisplay ?? 'Rejected';
    } else {
      statusKind = StatusKind.neutral;
      statusLabel = beneficiary.verificationStatus;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      beneficiary.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          beneficiary.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${beneficiary.relationDisplay ?? beneficiary.relation} '
                          '• ${beneficiary.age} yrs'
                          '${beneficiary.genderDisplay != null ? ' • ${beneficiary.genderDisplay}' : ''}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        // Allocation badge
                        if (beneficiary.percentageAllocation > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.pie_chart_outline,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${beneficiary.percentageAllocation.toStringAsFixed(0)}% allocation',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Verification status chip
                  StatusBadge(label: statusLabel, kind: statusKind),
                ],
              ),

              // ── Details ──────────────────────────────────────────────────
              if (beneficiary.phoneNumber != null ||
                  beneficiary.profession != null) ...[
                const Divider(height: 20),
                if (beneficiary.phoneNumber != null)
                  _buildInfoRow(Icons.phone, beneficiary.phoneNumber!),
                if (beneficiary.profession != null) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.work, beneficiary.profession!),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(text,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }
}

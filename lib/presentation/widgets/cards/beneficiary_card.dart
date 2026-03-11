import 'package:flutter/material.dart';
import '../../../data/models/beneficiary_model.dart';

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
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (beneficiary.isVerified) {
      statusColor = Colors.green;
      statusIcon = Icons.verified;
      statusLabel = beneficiary.verificationStatusDisplay ?? 'Verified';
    } else if (beneficiary.isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusLabel = beneficiary.verificationStatusDisplay ?? 'Pending';
    } else if (beneficiary.isRejected) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusLabel = beneficiary.verificationStatusDisplay ?? 'Rejected';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help;
      statusLabel = beneficiary.verificationStatus;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      beneficiary.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
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
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        // Allocation badge
                        if (beneficiary.percentageAllocation > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.pie_chart_outline,
                                  size: 13,
                                  color: Colors.blue.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${beneficiary.percentageAllocation.toStringAsFixed(0)}% allocation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
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
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
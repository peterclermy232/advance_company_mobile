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
    // Backend may return lowercase or uppercase — normalise to lowercase.
    final statusLower = beneficiary.verificationStatus.toLowerCase();

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (statusLower) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusLabel = 'Verified';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusLabel = 'Pending';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'Rejected';
        break;
      default:
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      beneficiary.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${beneficiary.relation} • ${beneficiary.age} years',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (beneficiary.phoneNumber != null ||
                  beneficiary.profession != null) ...[
                const Divider(height: 24),
                if (beneficiary.phoneNumber != null)
                  _buildInfoRow(Icons.phone, beneficiary.phoneNumber!),
                if (beneficiary.profession != null) ...[
                  const SizedBox(height: 8),
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
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
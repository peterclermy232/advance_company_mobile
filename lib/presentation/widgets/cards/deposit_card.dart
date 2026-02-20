import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/deposit_model.dart';

class DepositCard extends StatelessWidget {
  final DepositModel deposit;

  const DepositCard({super.key, required this.deposit});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
    NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Use model helpers — handles 'completed'→Approved, 'failed'→Rejected, etc.
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;

    if (deposit.isApproved) {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
      statusIcon = Icons.check_circle_rounded;
    } else if (deposit.isPending) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      statusIcon = Icons.schedule_rounded;
    } else if (deposit.isRejected) {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = Colors.grey.shade600;
      statusBg = Colors.grey.shade100;
      statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top header: amount + status ─────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: statusBg.withOpacity(0.45),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat
                          .format(double.tryParse(deposit.amount) ?? 0),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: statusColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        deposit.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: method + date side by side
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.payment_rounded,
                        iconColor: Colors.blue.shade600,
                        label: 'Method',
                        // paymentMethodLabel handles 'MPESA' → 'M-Pesa'
                        value: deposit.paymentMethodLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.calendar_today_rounded,
                        iconColor: Colors.purple.shade600,
                        label: 'Date',
                        value:
                        '${dateFormat.format(deposit.createdAt)}\n${timeFormat.format(deposit.createdAt)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Reference
                _InfoRow(
                  icon: Icons.tag_rounded,
                  iconColor: Colors.grey.shade500,
                  label: 'Reference',
                  value: deposit.transactionReference,
                  isMonospace: true,
                ),

                // M-Pesa phone
                if (deposit.mpesaPhone != null &&
                    deposit.mpesaPhone!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.phone_android_rounded,
                    iconColor: Colors.green.shade600,
                    label: 'M-Pesa Phone',
                    value: deposit.mpesaPhone!,
                  ),
                ],

                // M-Pesa receipt
                if (deposit.mpesaReceiptNumber != null &&
                    deposit.mpesaReceiptNumber!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.receipt_rounded,
                    iconColor: Colors.teal.shade600,
                    label: 'M-Pesa Receipt',
                    value: deposit.mpesaReceiptNumber!,
                    isMonospace: true,
                  ),
                ],

                // Notes
                if (deposit.notes != null &&
                    deposit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.notes_rounded,
                    iconColor: Colors.orange.shade600,
                    label: 'Notes',
                    value: deposit.notes!,
                  ),
                ],

                // Approved timestamp
                if (deposit.approvedAt != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.check_circle_rounded,
                    iconColor: Colors.green.shade600,
                    label: 'Approved',
                    value: DateFormat('MMM dd, yyyy • h:mm a')
                        .format(deposit.approvedAt!),
                  ),
                ],

                // Rejection reason
                if (deposit.isRejected &&
                    deposit.rejectionReason != null &&
                    deposit.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFCA5A5), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Color(0xFFDC2626), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rejection Reason',
                                style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                deposit.rejectionReason!,
                                style: const TextStyle(
                                    color: Color(0xFF991B1B), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared tile widgets ──────────────────────────────────────────────────────

/// Square tile used in the 2-column row (method + date).
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width row used for reference, phone, notes etc.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isMonospace;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: isMonospace ? 'monospace' : null,
              letterSpacing: isMonospace ? 0.3 : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
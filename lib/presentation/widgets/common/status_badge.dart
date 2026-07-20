import 'package:flutter/material.dart';
import '../../../config/theme_config.dart';

/// Semantic status pill — mirrors the web app's
/// `bg-{color}-100 / text-{color}-800` badge pattern.
enum StatusKind { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusKind kind;

  const StatusBadge({super.key, required this.label, required this.kind});

  /// Maps common status strings (deposit/application/beneficiary statuses)
  /// to the right badge kind, matching the web's status → color mapping:
  /// green=approved/completed, yellow=pending, blue=processing, red=rejected/failed, gray=cancelled.
  factory StatusBadge.fromStatus(String status) {
    final normalized = status.toLowerCase().trim();
    StatusKind kind;
    switch (normalized) {
      case 'approved':
      case 'completed':
      case 'active':
      case 'verified':
        kind = StatusKind.success;
        break;
      case 'pending':
        kind = StatusKind.warning;
        break;
      case 'processing':
      case 'submitted':
      case 'in_review':
      case 'in review':
        kind = StatusKind.info;
        break;
      case 'rejected':
      case 'failed':
      case 'declined':
        kind = StatusKind.error;
        break;
      default:
        kind = StatusKind.neutral;
    }
    final label = status.isEmpty
        ? status
        : status[0].toUpperCase() + status.substring(1).toLowerCase();
    return StatusBadge(label: label, kind: kind);
  }

  Color get _bg {
    switch (kind) {
      case StatusKind.success:
        return AppColors.successBg;
      case StatusKind.warning:
        return AppColors.warningBg;
      case StatusKind.error:
        return AppColors.errorBg;
      case StatusKind.info:
        return AppColors.infoBg;
      case StatusKind.neutral:
        return AppColors.neutralBg;
    }
  }

  Color get _text {
    switch (kind) {
      case StatusKind.success:
        return AppColors.successText;
      case StatusKind.warning:
        return AppColors.warningText;
      case StatusKind.error:
        return AppColors.errorText;
      case StatusKind.info:
        return AppColors.infoText;
      case StatusKind.neutral:
        return AppColors.neutralText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Solid color + white icon "chip" used on stat cards, list-row leading icons,
/// and quick-action tiles — mirrors the web's `p-3 rounded-lg bg-{color}-600`.
class IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconChip({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

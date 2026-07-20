import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme_config.dart';
import '../../widgets/common/status_badge.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _AdminTile(
            title: 'Deposit Approvals',
            icon: Icons.pending_actions,
            color: AppColors.warning,
            onTap: () => context.push('/admin/deposits'),
          ),
          _AdminTile(
            title: 'Application Reviews',
            icon: Icons.assignment_outlined,
            color: AppColors.info,
            onTap: () => context.push('/admin/applications'),
          ),
          _AdminTile(
            title: 'Analytics',
            icon: Icons.bar_chart,
            color: AppColors.secondary,
            onTap: () => context.push('/admin/analytics'),
          ),
          _AdminTile(
            title: 'Members',
            icon: Icons.people,
            color: AppColors.primary,
            onTap: () => context.push('/admin/members'),
          ),
          _AdminTile(
            title: 'Beneficiary Verification',
            icon: Icons.verified_user,
            color: AppColors.success,
            onTap: () => context.push('/admin/beneficiary-verification'),
          ),
        ],
      ),
    );
  }
}

// Mirrors the web's admin quick-launch cards: white shadow-card with a
// solid colored IconChip, matching the shared StatCard/quick-action styling.
class _AdminTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconChip(icon: icon, color: color, size: 48),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            color: Colors.orange,
            onTap: () => context.push('/admin/deposit-approvals'),
          ),
          _AdminTile(
            title: 'Application Reviews',
            icon: Icons.assignment_outlined,
            color: Colors.teal,
            onTap: () => context.push('/admin/applications'),
          ),
          _AdminTile(
            title: 'Analytics',
            icon: Icons.bar_chart,
            color: Colors.purple,
            onTap: () => context.push('/admin/analytics'),
          ),
          _AdminTile(
            title: 'Members',
            icon: Icons.people,
            color: Colors.blue,
            onTap: () => context.push('/admin/members'),
          ),
          _AdminTile(
            title: 'Beneficiary Verification',
            icon: Icons.verified_user,
            color: Colors.green,
            onTap: () => context.push('/admin/beneficiary-verification'),
          ),
        ],
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
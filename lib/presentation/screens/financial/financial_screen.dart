import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/financial_provider.dart';
import '../admin/admin_deposit_approvals_screen.dart';
import 'deposit_form_screen.dart';
import 'deposit_history_screen.dart';

class FinancialScreen extends ConsumerStatefulWidget {
  const FinancialScreen({super.key});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isAdmin;

  @override
  void initState() {
    super.initState();
    _isAdmin = ref.read(authProvider).user?.isAdmin ?? false;
    _tabController = TabController(length: _isAdmin ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _isAdmin
        ? ref.watch(pendingDepositsProvider).maybeWhen(
            data: (list) => list.length,
            orElse: () => 0,
          )
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(depositsProvider.notifier).refresh();
              ref.read(pendingDepositsProvider.notifier).refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            const Tab(
              icon: Icon(Icons.add_circle_outline),
              text: 'Make Deposit',
            ),
            const Tab(
              icon: Icon(Icons.receipt_long),
              text: 'My Deposits',
            ),
            if (_isAdmin)
              Tab(
                icon: pendingCount > 0
                    ? Badge(
                        backgroundColor: AppColors.error,
                        label: Text('$pendingCount'),
                        child: const Icon(Icons.admin_panel_settings),
                      )
                    : const Icon(Icons.admin_panel_settings),
                text: 'Admin Review',
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _EmbeddedDepositForm(),
          const _EmbeddedDepositHistory(),
          if (_isAdmin) const _EmbeddedAdminApprovals(),
        ],
      ),
    );
  }
}

class _EmbeddedDepositForm extends StatelessWidget {
  const _EmbeddedDepositForm();

  @override
  Widget build(BuildContext context) {
    return const DepositFormScreen(embedded: true);
  }
}

class _EmbeddedDepositHistory extends StatelessWidget {
  const _EmbeddedDepositHistory();

  @override
  Widget build(BuildContext context) {
    return const DepositHistoryScreen();
  }
}

class _EmbeddedAdminApprovals extends StatelessWidget {
  const _EmbeddedAdminApprovals();

  @override
  Widget build(BuildContext context) {
    return const AdminDepositApprovalsScreen();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/financial_provider.dart';
import '../admin/admin_deposit_approvals_screen.dart' hide pendingDepositsProvider;
import 'deposit_form_screen.dart';
import 'deposit_history_screen.dart';

/// FinancialScreen — main entry for the Financial feature.
///
/// FIX: DepositFormScreen used to have its own Scaffold+AppBar which caused
/// a double AppBar when embedded here. Both child screens now use
/// _EmbeddedDepositFormScreen and _EmbeddedDepositHistoryScreen wrappers
/// (no Scaffold, no AppBar) so the host Scaffold's TabBar is the only bar.
class FinancialScreen extends ConsumerStatefulWidget {
  const FinancialScreen({super.key});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingDepositsProvider);
    final pendingCount = pendingAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Financial',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(depositsProvider);
              ref.invalidate(pendingDepositsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
            Tab(
              icon: pendingCount > 0
                  ? Badge(
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
        // FIX: Use scaffold=false wrappers to prevent double AppBar.
        // DepositHistoryScreen and AdminDepositApprovalsScreen now conditionally
        // wrap with Scaffold only when used as standalone routes.
        children: const [
          _EmbeddedDepositForm(),
          _EmbeddedDepositHistory(),
          _EmbeddedAdminApprovals(),
        ],
      ),
    );
  }
}

// ── Tab content wrappers (no Scaffold/AppBar) ─────────────────────────────────

/// Renders DepositFormScreen content without its own Scaffold or AppBar.
/// The form already uses ListView internally so this works seamlessly.
class _EmbeddedDepositForm extends StatelessWidget {
  const _EmbeddedDepositForm();

  @override
  Widget build(BuildContext context) {
    // DepositFormScreen extends ConsumerStatefulWidget.
    // We embed it inside the TabBarView — its Scaffold is the host's.
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
    // AdminDepositApprovalsScreen's Scaffold has no appBar, so it's safe here.
    return const AdminDepositApprovalsScreen();
  }
}
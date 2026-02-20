import '../../widgets/common/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../data/models/deposit_model.dart';
import '../../../data/models/dashboard_summary_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/cards/stat_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<double> _monthlyContributions = [4200, 4800, 5100, 4500, 5300, 5000];
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  String _selectedRange = 'Last 6 Months';

  final _currency = NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final userAsync        = ref.watch(currentUserProvider);
    final summaryAsync     = ref.watch(dashboardSummaryProvider); // ← live API
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final depositsAsync    = ref.watch(depositsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(unreadCountAsync),
      drawer: const AppDrawer(),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const LoadingIndicator();
          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: () async {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(unreadCountProvider);
              ref.invalidate(depositsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(user.fullName, user.isAdmin),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 4-card stats powered by reports/dashboard_summary/ ──
                        summaryAsync.when(
                          data:    (s) => _buildStatsGrid(s),
                          loading: ()  => _buildStatsGridSkeleton(),
                          error:   (e, _) =>
                              _buildErrorCard('Could not load summary: $e'),
                        ),
                        const SizedBox(height: 24),
                        if (user.isAdmin) ...[
                          _buildAdminQuickAccess(),
                          const SizedBox(height: 24),
                        ],
                        depositsAsync.when(
                          data:    (d) => _buildRecentActivity(d),
                          loading: ()  => const LoadingIndicator(),
                          error:   (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildMonthlyContributionsChart(),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error:   (e, _) => _buildFullError(e),
      ),
    );
  }

  // ── STATS GRID ────────────────────────────────────────────

  Widget _buildStatsGrid(DashboardSummaryModel s) {
    final cards = [
      _StatData(
        label: 'Monthly Deposits',
        value: _currency.format(s.monthlyDeposits),
        icon:  Icons.account_balance_wallet_outlined,
        color: const Color(0xFF2563EB),
        trend: '+5%',
      ),
      _StatData(
        label: 'Total Contributions',
        value: _currency.format(s.totalContributions),
        icon:  Icons.trending_up_rounded,
        color: const Color(0xFF16A34A),
        trend: '+12%',
      ),
      _StatData(
        label: 'Interest Earned',
        value: _currency.format(s.interestEarned),
        icon:  Icons.show_chart_rounded,
        color: const Color(0xFF7C3AED),
        trend: '+8%',
      ),
      _StatData(
        label: 'Active Beneficiaries',
        value: s.activeBeneficiaries.toString(),
        icon:  Icons.people_outline_rounded,
        color: const Color(0xFF4F46E5),
        trend: null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Overview'),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => StatCard(
            label: cards[i].label,
            value: cards[i].value,
            icon:  cards[i].icon,
            color: cards[i].color,
            trend: cards[i].trend,
          ),
        ),
      ],
    );
  }

  /// Pulse skeleton shown while the API call is in-flight
  Widget _buildStatsGridSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Overview'),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => const _SkeletonCard(),
        ),
      ],
    );
  }

  // ── APP BAR ───────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(AsyncValue<int> unreadCountAsync) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
      title: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.account_balance, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('AdvanceCompany',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
        ],
      ),
      actions: [
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
            onPressed: () => context.push('/notifications'),
          ),
          unreadCountAsync.when(
            data: (count) => count > 0
                ? Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Color(0xFFEF4444), shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ))
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
          ),
        ]),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── WELCOME BANNER ────────────────────────────────────────

  Widget _buildWelcomeSection(String userName, bool isAdmin) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20,
              child: _circle(130, 0.06)),
          Positioned(right: 50, bottom: -35,
              child: _circle(90, 0.07)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 24,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, $userName!',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 8),
                      Row(children: [
                        _pill(isAdmin ? 'Administrator' : 'Member',
                            Colors.white.withOpacity(0.2), Colors.white),
                        const SizedBox(width: 8),
                        _activePill(),
                      ]),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('Edit Profile',
                        style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
      width: size, height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity)));

  Widget _pill(String text, Color bg, Color textColor) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w500)));

  Widget _activePill() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.3),
          borderRadius: BorderRadius.circular(20)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, size: 10, color: Color(0xFF86EFAC)),
        SizedBox(width: 4),
        Text('Active',
            style: TextStyle(
                color: Color(0xFF86EFAC),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]));

  // ── ADMIN CONTROLS ────────────────────────────────────────

  Widget _buildAdminQuickAccess() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(border: const Color(0xFFFECACA)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _iconBox(Icons.admin_panel_settings_outlined,
                const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
            const SizedBox(width: 10),
            const Text('Admin Controls',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontSize: 15)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _adminChip('Approvals',
                Icons.pending_actions_outlined,
                '/admin/deposit-approvals',
                const Color(0xFFF59E0B), const Color(0xFFFFFBEB))),
            const SizedBox(width: 8),
            Expanded(child: _adminChip('Analytics',
                Icons.bar_chart_rounded,
                '/admin/analytics',
                const Color(0xFF7C3AED), const Color(0xFFF5F3FF))),
            const SizedBox(width: 8),
            Expanded(child: _adminChip('Members',
                Icons.people_outline_rounded,
                '/admin/members',
                const Color(0xFF2563EB), const Color(0xFFEFF6FF))),
          ]),
        ],
      ),
    );
  }

  Widget _adminChip(String label, IconData icon, String route,
      Color color, Color bg) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── RECENT ACTIVITY ───────────────────────────────────────

  Widget _buildRecentActivity(List<DepositModel> deposits) {
    final recent  = deposits.take(5).toList();
    final dateFmt = DateFormat('MMM dd');

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Recent Activity'),
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: () => context.push('/notifications'),
                  child: const Text('View All',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('No recent activity',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ]),
              ),
            )
          else
            ...recent.asMap().entries.map((e) {
              final idx     = e.key;
              final deposit = e.value;
              final s       = _statusStyle(deposit.status.toLowerCase());
              return Column(children: [
                if (idx > 0)
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: s.dot, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Container(
                      width: 40, height: 40,
                      decoration:
                      BoxDecoration(color: s.bg, shape: BoxShape.circle),
                      child: Icon(s.icon, color: s.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deposit ${s.label}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text(
                            '${deposit.paymentMethod.replaceAll('_', ' ')} · ${dateFmt.format(deposit.createdAt)}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _currency.format(
                          double.tryParse(deposit.amount) ?? 0),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569)),
                    ),
                  ]),
                ),
              ]);
            }),
        ],
      ),
    );
  }

  _StatusStyle _statusStyle(String s) {
    switch (s) {
      case 'approved':
      case 'completed':
        return _StatusStyle('Approved', const Color(0xFF16A34A),
            const Color(0xFFF0FDF4), const Color(0xFF22C55E),
            Icons.check_circle_outline_rounded);
      case 'pending':
        return _StatusStyle('Pending', const Color(0xFFD97706),
            const Color(0xFFFFFBEB), const Color(0xFFF59E0B),
            Icons.schedule_rounded);
      case 'processing':
        return _StatusStyle('Processing', const Color(0xFF2563EB),
            const Color(0xFFEFF6FF), const Color(0xFF3B82F6),
            Icons.sync_rounded);
      default:
        return _StatusStyle('Rejected', const Color(0xFFDC2626),
            const Color(0xFFFEF2F2), const Color(0xFFEF4444),
            Icons.cancel_outlined);
    }
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Make Deposit',    Icons.account_balance_wallet_outlined,
          const Color(0xFF2563EB), () => context.push('/deposit-form')),
      _QuickAction('Upload Document', Icons.upload_file_outlined,
          const Color(0xFF16A34A), () => context.push('/documents')),
      _QuickAction('View Reports',    Icons.assessment_outlined,
          const Color(0xFF7C3AED), () => context.push('/applications')),
      _QuickAction('Add Beneficiary', Icons.people_outline_rounded,
          const Color(0xFF4F46E5), () => context.push('/beneficiaries')),
    ];

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Quick Actions'),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: actions.length,
            itemBuilder: (_, i) {
              final a = actions[i];
              return InkWell(
                onTap: a.onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                      color: a.color,
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(a.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(a.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            maxLines: 2,
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── MONTHLY CONTRIBUTIONS CHART ───────────────────────────

  Widget _buildMonthlyContributionsChart() {
    final maxVal  = _monthlyContributions.reduce((a, b) => a > b ? a : b);
    final compact = NumberFormat.compactCurrency(symbol: 'KES ');

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Monthly Contributions'),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRange,
                    isDense: true,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: Color(0xFF94A3B8)),
                    items: ['Last 6 Months', 'Last Year', 'All Time']
                        .map((e) => DropdownMenuItem(
                        value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRange = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_monthlyContributions.length, (i) {
                final val   = _monthlyContributions[i];
                final frac  = val / maxVal;
                final isMax = val == maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isMax)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(compact.format(val),
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB))),
                          ),
                        Flexible(
                          fit: FlexFit.loose,
                          child: FractionallySizedBox(
                            heightFactor: frac,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isMax
                                      ? [
                                    const Color(0xFF1D4ED8),
                                    const Color(0xFF3B82F6)
                                  ]
                                      : [
                                    const Color(0xFF2563EB),
                                    const Color(0xFF60A5FA)
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_months[i],
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────

  BoxDecoration _cardDecoration(
      {Color border = const Color(0xFFE2E8F0)}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ],
    );
  }

  Widget _iconBox(IconData icon, Color color, Color bg) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18));

  Widget _buildErrorCard(String message) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFEF4444), size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFF991B1B), fontSize: 13))),
      ]));

  Widget _buildFullError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.error_outline,
                size: 48, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          const Text('Something went wrong',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text('$error',
              style: const TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => ref.invalidate(currentUserProvider),
            child: const Text('Try Again'),
          ),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
          letterSpacing: -0.2));
}

// ── SKELETON CARD ─────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _bone(38, 38, radius: 10),
                  _bone(40, 18, radius: 20),
                ],
              ),
              const Spacer(),
              _bone(double.infinity, 18),
              const SizedBox(height: 6),
              _bone(80, 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bone(double w, double h, {double radius = 6}) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(radius)));
}

// ── DATA CLASSES ──────────────────────────────────────────

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  final String? trend;
  const _StatData({required this.label, required this.value,
    required this.icon, required this.color, this.trend});
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.title, this.icon, this.color, this.onTap);
}

class _StatusStyle {
  final String label;
  final Color color, bg, dot;
  final IconData icon;
  const _StatusStyle(this.label, this.color, this.bg, this.dot, this.icon);
}
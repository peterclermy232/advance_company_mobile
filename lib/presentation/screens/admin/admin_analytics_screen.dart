import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../config/theme_config.dart';
import '../../../data/providers/core_providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/common/status_badge.dart';

// Chart accent palette — mirrors the web app's Chart.js dataset colors.
// Kept as literals (distinct from the semantic AppColors status palette)
// so the mobile charts visually match the Angular dashboard 1:1.
const _chartBlue = Color(0xFF3B82F6);
const _chartGreen = Color(0xFF10B981);
const _chartAmber = Color(0xFFF59E0B);
const _chartViolet = Color(0xFF8B5CF6);

// Provider for analytics summary
final analyticsSummaryProvider = FutureProvider.autoDispose((ref) async {
  // apiClientProvider is a plain Provider<ApiClient>
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.analyticsSummary);
  final raw = response.data;
  return raw is Map ? (raw['data'] ?? raw) : raw;
});

// Provider for monthly trends
final monthlyTrendsProvider = FutureProvider.autoDispose((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.monthlyTrends);
  final raw = response.data;
  final data = raw is Map ? (raw['data'] ?? raw) : raw;
  if (data is List) return data;
  return <dynamic>[];
});

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final trendsAsync = ref.watch(monthlyTrendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(analyticsSummaryProvider);
              ref.invalidate(monthlyTrendsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportAnalytics(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsSummaryProvider);
          ref.invalidate(monthlyTrendsProvider);
          await Future.wait([
            ref.read(analyticsSummaryProvider.future),
            ref.read(monthlyTrendsProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summaryAsync.when(
                data: (summary) => _buildSummaryStats(
                    context, summary as Map<String, dynamic>),
                loading: () => const LoadingIndicator(),
                error: (error, _) =>
                    _buildErrorCard('Failed to load summary', error),
              ),
              const SizedBox(height: 24),
              Text(
                'Monthly Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              trendsAsync.when(
                data: (trends) => _buildTrendsChart(context, trends),
                loading: () => const LoadingIndicator(),
                error: (error, _) =>
                    _buildErrorCard('Failed to load trends', error),
              ),
              const SizedBox(height: 24),
              summaryAsync.when(
                data: (summary) {
                  final s = summary as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMemberActivityCard(context, s),
                      const SizedBox(height: 16),
                      _buildTopContributorsCard(context, s),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(
      BuildContext context, Map<String, dynamic> summary) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        StatCard(
          label: 'Total Members',
          value: (summary['total_members'] ?? 0).toString(),
          icon: Icons.people,
          color: AppColors.primary,
        ),
        StatCard(
          label: 'Active Members',
          value: (summary['active_members'] ?? 0).toString(),
          icon: Icons.person_outline,
          color: AppColors.success,
        ),
        StatCard(
          label: 'Total Deposits',
          value: currencyFormat.format(
            double.tryParse(summary['total_deposits']?.toString() ?? '0') ?? 0,
          ),
          icon: Icons.account_balance_wallet,
          color: AppColors.warning,
        ),
        StatCard(
          label: 'Pending Approvals',
          value: (summary['pending_approvals'] ?? 0).toString(),
          icon: Icons.pending_actions,
          color: AppColors.secondary,
        ),
        StatCard(
          label: 'Total Beneficiaries',
          value: (summary['total_beneficiaries'] ?? 0).toString(),
          icon: Icons.family_restroom,
          color: AppColors.info,
        ),
        StatCard(
          label: 'Documents Pending',
          value: (summary['documents_pending'] ?? 0).toString(),
          icon: Icons.description,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildTrendsChart(BuildContext context, List<dynamic> trends) {
    if (trends.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No trend data available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final depositSpots = <FlSpot>[];
    final memberSpots = <FlSpot>[];

    for (var i = 0; i < trends.length; i++) {
      final trend = trends[i];
      depositSpots.add(FlSpot(
        i.toDouble(),
        double.tryParse(trend['total_deposits']?.toString() ?? '0') ?? 0,
      ));
      memberSpots.add(FlSpot(
        i.toDouble(),
        (trend['new_members'] ?? 0).toDouble(),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < trends.length) {
                            return Text(
                              trends[idx]['month'] ?? '',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: depositSpots,
                      isCurved: true,
                      color: _chartBlue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: memberSpots,
                      isCurved: true,
                      color: _chartGreen,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Deposits', _chartBlue),
                const SizedBox(width: 24),
                _buildLegendItem('New Members', _chartGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMemberActivityCard(
      BuildContext context, Map<String, dynamic> summary) {
    final newReg =
        (summary['new_registrations_this_month'] ?? summary['new_members_this_month'] ?? 0)
            .toString();
    final activeMembers = (summary['active_members'] ?? 0).toString();
    final pendingApprovals = (summary['pending_approvals'] ?? 0).toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member Activity',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActivityItem('New Registrations', newReg, Icons.person_add,
                AppColors.primary),
            const Divider(),
            _buildActivityItem('Active Members', activeMembers, Icons.people,
                AppColors.success),
            const Divider(),
            _buildActivityItem('Pending Approvals', pendingApprovals,
                Icons.pending_actions, AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String label, String value, IconData icon, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconChip(icon: icon, color: color, size: 40),
      title: Text(label),
      trailing: Text(value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
    );
  }

  Widget _buildTopContributorsCard(
      BuildContext context, Map<String, dynamic> summary) {
    final rawList = summary['top_contributors'];
    final topContributors = rawList is List ? rawList : <dynamic>[];
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Contributors',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (topContributors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('No contributor data available',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ...topContributors.asMap().entries.map((entry) {
                final index = entry.key;
                final contributor = entry.value as Map<String, dynamic>;
                final name = contributor['name'] as String? ??
                    contributor['full_name'] as String? ??
                    'Member';
                final amount = double.tryParse(
                        contributor['amount']?.toString() ?? '0') ??
                    0.0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _getRankColor(index),
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name),
                  trailing: Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return _chartAmber;
      case 1:
        return AppColors.textMuted;
      case 2:
        return _chartViolet;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildErrorCard(String title, Object error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(error.toString(),
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAnalytics(BuildContext context, WidgetRef ref) async {
    try {
      // apiClientProvider is a plain Provider<ApiClient>
      final apiClient = ref.read(apiClientProvider);
      await apiClient.get(ApiEndpoints.exportAnalytics);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics exported successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

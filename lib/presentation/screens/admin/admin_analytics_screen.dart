import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/providers/core_providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/cards/stat_card.dart';

// Provider for analytics summary
final analyticsSummaryProvider = FutureProvider.autoDispose((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.analyticsSummary);
  return response.data['data'];
});

// Provider for monthly trends
final monthlyTrendsProvider = FutureProvider.autoDispose((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.monthlyTrends);
  return response.data['data'];
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
              // Summary Stats
              summaryAsync.when(
                data: (summary) => _buildSummaryStats(context, summary),
                loading: () => const LoadingIndicator(),
                error: (error, _) => _buildErrorCard('Failed to load summary', error),
              ),
              const SizedBox(height: 24),

              // Monthly Trends Chart
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
                error: (error, _) => _buildErrorCard('Failed to load trends', error),
              ),
              const SizedBox(height: 24),

              // Additional Analytics
              _buildMemberActivityCard(context),
              const SizedBox(height: 16),
              _buildTopContributorsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, Map<String, dynamic> summary) {
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
          color: Colors.blue,
        ),
        StatCard(
          label: 'Active Members',
          value: (summary['active_members'] ?? 0).toString(),
          icon: Icons.person_outline,
          color: Colors.green,
        ),
        StatCard(
          label: 'Total Deposits',
          value: currencyFormat.format(
            double.tryParse(summary['total_deposits']?.toString() ?? '0') ?? 0,
          ),
          icon: Icons.account_balance_wallet,
          color: Colors.orange,
        ),
        StatCard(
          label: 'Pending Approvals',
          value: (summary['pending_approvals'] ?? 0).toString(),
          icon: Icons.pending_actions,
          color: Colors.purple,
        ),
        StatCard(
          label: 'Total Beneficiaries',
          value: (summary['total_beneficiaries'] ?? 0).toString(),
          icon: Icons.family_restroom,
          color: Colors.teal,
        ),
        StatCard(
          label: 'Documents Pending',
          value: (summary['documents_pending'] ?? 0).toString(),
          icon: Icons.description,
          color: Colors.red,
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
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    // Prepare data for chart
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
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < trends.length) {
                            final trend = trends[value.toInt()];
                            return Text(
                              trend['month'] ?? '',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: depositSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: memberSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Deposits', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('New Members', Colors.green),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMemberActivityCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              'New Registrations (This Month)',
              '24',
              Icons.person_add,
              Colors.blue,
              '+12%',
            ),
            const Divider(),
            _buildActivityItem(
              'Active Users (Last 30 Days)',
              '156',
              Icons.people,
              Colors.green,
              '+8%',
            ),
            const Divider(),
            _buildActivityItem(
              'Deposits This Month',
              '89',
              Icons.account_balance_wallet,
              Colors.orange,
              '+15%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String label,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            trend,
            style: TextStyle(
              fontSize: 12,
              color: trend.startsWith('+') ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContributorsCard(BuildContext context) {
    // Mock data - replace with actual API data
    final topContributors = [
      {'name': 'John Doe', 'amount': 50000.0},
      {'name': 'Jane Smith', 'amount': 45000.0},
      {'name': 'Bob Johnson', 'amount': 40000.0},
      {'name': 'Alice Williams', 'amount': 35000.0},
      {'name': 'Charlie Brown', 'amount': 30000.0},
    ];

    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Contributors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...topContributors.asMap().entries.map((entry) {
              final index = entry.key;
              final contributor = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(index),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(contributor['name'] as String),
                trailing: Text(
                  currencyFormat.format(contributor['amount']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Widget _buildErrorCard(String title, Object error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAnalytics(BuildContext context, WidgetRef ref) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.get(ApiEndpoints.exportAnalytics);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/installment_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().refreshDashboardWithRetry();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardProvider>().refreshDashboardWithRetry();
            },
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          if (dashboardProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dashboardProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your internet connection and try again.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Clear error before retrying
                      dashboardProvider.clearError();
                      dashboardProvider.refreshDashboardWithRetry();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = dashboardProvider.dashboardStats;
          if (stats == null) {
            return const Center(child: Text('No data available'));
          }

          return RefreshIndicator(
            onRefresh: () => dashboardProvider.refreshDashboardWithRetry(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  _buildWelcomeSection(context, dashboardProvider),
                  const SizedBox(height: 24),

                  // Quick stats cards
                  _buildQuickStatsSection(context, stats),
                  const SizedBox(height: 24),

                  // Charts section
                  _buildChartsSection(context, dashboardProvider),
                  const SizedBox(height: 24),

                  // Alerts section
                  _buildAlertsSection(context, dashboardProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    DashboardProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Business Overview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              provider.getDashboardSummary(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (provider.lastUpdated != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(provider.lastUpdated!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context, stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Statistics',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              'Total Customers',
              stats.totalCustomers.toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              context,
              'Active Plans',
              stats.activeInstallmentPlans.toString(),
              Icons.assignment,
              Colors.green,
            ),
            _buildStatCard(
              context,
              'Pending Payments',
              stats.pendingPayments.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
            _buildStatCard(
              context,
              'Overdue Payments',
              stats.overduePayments.toString(),
              Icons.warning,
              Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildAmountCard(
              context,
              'Total Collected',
              stats.totalPaidAmount,
              Icons.account_balance_wallet,
              Colors.green,
            ),
            _buildAmountCard(
              context,
              'Pending Amount',
              stats.totalPendingAmount,
              Icons.schedule,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    final formatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Text(
              formatter.format(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analytics', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),

        // Monthly Revenue Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Revenue Trend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildRevenueChart(provider.getRevenueChartData()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Payment Status Distribution
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Status Distribution',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildPaymentStatusPieChart(
                    provider.getPaymentStatusDistribution(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(List<Map<String, dynamic>> revenueData) {
    if (revenueData.isEmpty) {
      return const Center(child: Text('No revenue data available'));
    }

    final spots = revenueData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index.toDouble(), data['amount'].toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat.compact().format(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < revenueData.length) {
                  return Text(
                    revenueData[index]['month'],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusPieChart(Map<String, double> statusData) {
    if (statusData.isEmpty) {
      return const Center(child: Text('No payment data available'));
    }

    final sections = statusData.entries.map((entry) {
      Color color;
      switch (entry.key) {
        case 'Paid':
          color = Colors.green;
          break;
        case 'Pending':
          color = Colors.orange;
          break;
        case 'Overdue':
          color = Colors.red;
          break;
        default:
          color = Colors.grey;
      }

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.value.toInt()}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: statusData.entries.map((entry) {
              Color color;
              switch (entry.key) {
                case 'Paid':
                  color = Colors.green;
                  break;
                case 'Pending':
                  color = Colors.orange;
                  break;
                case 'Overdue':
                  color = Colors.red;
                  break;
                default:
                  color = Colors.grey;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${entry.value.toInt()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection(BuildContext context, DashboardProvider provider) {
    final alertsCount = provider.alertsCount;
    final hasCriticalAlerts = provider.hasCriticalAlerts;

    if (alertsCount == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All systems running smoothly!',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: hasCriticalAlerts ? Colors.red.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasCriticalAlerts ? Icons.error : Icons.warning,
                  color: hasCriticalAlerts ? Colors.red : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasCriticalAlerts
                        ? 'Critical Alerts'
                        : 'Attention Required',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: hasCriticalAlerts ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(alertsCount.toString()),
                  backgroundColor: hasCriticalAlerts
                      ? Colors.red
                      : Colors.orange,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You have $alertsCount item${alertsCount > 1 ? 's' : ''} requiring attention.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

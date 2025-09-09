import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/installment_provider.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DashboardProvider>();
      // Always refresh when entering the dashboard
      provider.refreshDashboardWithRetry();
    });
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      // Navigation is handled by the auth state listener in main.dart
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (String result) {
              if (result == 'logout') {
                _showLogoutConfirmation();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
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
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Clear error before retrying
                          dashboardProvider.clearError();
                          dashboardProvider.refreshDashboardWithRetry();
                        },
                        child: const Text('Retry'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Test connectivity
                          final isConnected = await dashboardProvider
                              .testConnectivity();
                          if (context.mounted) {
                            if (isConnected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Connection successful!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connection failed. Check your internet.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            dashboardProvider.refreshDashboardWithRetry();
                          }
                        },
                        child: const Text('Test Connection'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Run Firestore tests
                          dashboardProvider.clearError();
                          await dashboardProvider.testFirestore();
                        },
                        child: const Text('Test Database'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Test Firebase configuration
                          dashboardProvider.clearError();
                          await dashboardProvider.testFirebaseConfig();
                        },
                        child: const Text('Test Config'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Clear cache and retry
                          dashboardProvider.clearError();
                          context.read<CustomerProvider>().clearError();
                          context.read<InstallmentProvider>().clearError();
                          dashboardProvider.refreshDashboardWithRetry();
                        },
                        child: const Text('Clear Cache'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Troubleshooting Tips:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Ensure you are logged in with the correct account',
                        ),
                        const Text(
                          '• Check your internet connection',
                        ),
                        const Text(
                          '• Make sure your Firebase rules are deployed',
                        ),
                        const Text(
                          '• Verify your Firebase project configuration',
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // Show more detailed help
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Database Error Help'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'This error typically occurs when there are issues with Firebase authentication or database permissions.',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Possible Solutions:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          '1. Check Firebase Authentication:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          '   • Ensure you are logged in with a valid account',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          '2. Verify Firestore Security Rules:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          '   • Make sure your Firestore rules allow read/write access for authenticated users',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          '3. Check Firebase Project Configuration:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          '   • Verify that your Firebase configuration files are correct',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          '4. Internet Connection:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          '   • Ensure you have a stable internet connection',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text(
                            'Show Detailed Help',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
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

                  // Overdue payments section
                  _buildOverduePaymentsSection(context, dashboardProvider),
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

  // Add this new method to build the overdue payments section
  Widget _buildOverduePaymentsSection(
    BuildContext context,
    DashboardProvider provider,
  ) {
    // For now, we'll create a simple section that shows the overdue payments count
    // In a more advanced implementation, this could show detailed overdue payment information
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overdue Payments',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      '${provider.overduePayments} Overdue Payments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'These payments require immediate attention. The due dates for these payments have passed.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to payments screen to view details
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigate to overdue payments list'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View Overdue Payments'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

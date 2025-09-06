import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/dashboard_stats.dart';
import '../services/firestore_service.dart';

class DashboardProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  DashboardStats? _dashboardStats;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  // Getters
  DashboardStats? get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  // Quick access to common stats
  int get totalCustomers => _dashboardStats?.totalCustomers ?? 0;
  int get totalInstallmentPlans => _dashboardStats?.totalInstallmentPlans ?? 0;
  int get activeInstallmentPlans =>
      _dashboardStats?.activeInstallmentPlans ?? 0;
  int get pendingPayments => _dashboardStats?.pendingPayments ?? 0;
  int get overduePayments => _dashboardStats?.overduePayments ?? 0;
  double get totalPendingAmount => _dashboardStats?.totalPendingAmount ?? 0.0;
  double get totalPaidAmount => _dashboardStats?.totalPaidAmount ?? 0.0;
  double get totalRevenue => _dashboardStats?.totalRevenue ?? 0.0;
  double get collectionRate => _dashboardStats?.collectionRate ?? 0.0;

  // Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      _setLoading(true);

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('Loading dashboard stats for user: ${user.email}');
      final stats = await _firestoreService.getDashboardStats();
      _dashboardStats = stats;
      _lastUpdated = DateTime.now();
      _setError(null);
    } catch (e) {
      print('Dashboard error: $e');
      String errorMessage = 'Failed to load dashboard statistics. ';

      // Provide more user-friendly error messages
      if (e.toString().contains('UNAVAILABLE') ||
          e.toString().contains('Unable to resolve host')) {
        errorMessage += 'Please check your internet connection and try again.';
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage += 'Access denied. Please contact support.';
      } else {
        errorMessage += 'Please try again later.';
      }

      _setError(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Refresh dashboard data (force reload)
  Future<void> refreshDashboard() async {
    await loadDashboardStats();
  }

  // Refresh dashboard with retry mechanism
  Future<void> refreshDashboardWithRetry({int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        await loadDashboardStats();
        // If successful, break the retry loop
        if (_error == null) {
          break;
        }
      } catch (e) {
        print('Dashboard refresh attempt ${attempts + 1} failed: $e');
      }

      attempts++;

      // If we haven't reached max retries, wait before retrying
      if (attempts < maxRetries) {
        // Exponential backoff: wait 1s, 2s, 4s, etc.
        await Future.delayed(Duration(seconds: pow(2, attempts).toInt()));
      }
    }
  }

  // Get quick stats for dashboard cards
  Map<String, dynamic> getQuickStats() {
    if (_dashboardStats == null) return {};

    return {
      'totalCustomers': _dashboardStats!.totalCustomers,
      'activeInstallmentPlans': _dashboardStats!.activeInstallmentPlans,
      'pendingPayments': _dashboardStats!.pendingPayments,
      'overduePayments': _dashboardStats!.overduePayments,
      'totalPendingAmount': _dashboardStats!.totalPendingAmount,
      'totalPaidAmount': _dashboardStats!.totalPaidAmount,
      'collectionRate': _dashboardStats!.collectionRate,
      'overdueRate': _dashboardStats!.overdueRate,
    };
  }

  // Get data for revenue chart
  List<Map<String, dynamic>> getRevenueChartData() {
    if (_dashboardStats?.monthlyRevenue == null) return [];

    return _dashboardStats!.monthlyRevenue
        .map(
          (revenue) => {
            'month': revenue.month,
            'amount': revenue.amount,
            'year': revenue.year,
          },
        )
        .toList();
  }

  // Get installment status distribution for pie chart
  Map<String, double> getInstallmentStatusDistribution() {
    if (_dashboardStats == null) return {};

    return {
      'Active': _dashboardStats!.activeInstallmentPlans.toDouble(),
      'Completed': _dashboardStats!.completedInstallmentPlans.toDouble(),
      'Overdue': _dashboardStats!.overdueInstallmentPlans.toDouble(),
    };
  }

  // Get payment status distribution
  Map<String, double> getPaymentStatusDistribution() {
    if (_dashboardStats == null) return {};

    return {
      'Paid': _dashboardStats!.paidPayments.toDouble(),
      'Pending': _dashboardStats!.pendingPayments.toDouble(),
      'Overdue': _dashboardStats!.overduePayments.toDouble(),
    };
  }

  // Check if data needs refresh (older than 5 minutes)
  bool get needsRefresh {
    if (_lastUpdated == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);
    return difference.inMinutes > 5;
  }

  // Get alerts count (overdue payments + critical metrics)
  int get alertsCount {
    if (_dashboardStats == null) return 0;

    int alerts = 0;

    // Overdue payments
    alerts += _dashboardStats!.overduePayments;

    // Low collection rate (below 70%)
    if (_dashboardStats!.collectionRate < 70) alerts++;

    // High overdue rate (above 20%)
    if (_dashboardStats!.overdueRate > 20) alerts++;

    return alerts;
  }

  // Check if there are critical alerts
  bool get hasCriticalAlerts {
    if (_dashboardStats == null) return false;

    // Critical if overdue rate is above 30% or collection rate is below 50%
    return _dashboardStats!.overdueRate > 30 ||
        _dashboardStats!.collectionRate < 50;
  }

  // Get summary text for dashboard
  String getDashboardSummary() {
    if (_dashboardStats == null) return 'No data available';

    final stats = _dashboardStats!;
    final collectionRate = stats.collectionRate.toStringAsFixed(1);

    if (stats.totalCustomers == 0) {
      return 'Welcome! Start by adding your first customer.';
    } else if (stats.totalInstallmentPlans == 0) {
      return 'You have ${stats.totalCustomers} customers. Create installment plans to get started.';
    } else {
      return 'Managing ${stats.totalCustomers} customers with ${stats.activeInstallmentPlans} active plans. Collection rate: $collectionRate%';
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Check if there's an internet connection by attempting a simple Firestore operation
  Future<bool> checkConnection() async {
    try {
      // Try a simple count query to check connectivity
      await _firestoreService.db.collection('customers').limit(1).get();
      return true;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }

  // Auto-refresh if data is stale
  void checkAndRefreshIfNeeded() {
    if (needsRefresh && !_isLoading) {
      loadDashboardStats();
    }
  }
}

class MonthlyRevenue {
  final String month;
  final double amount;
  final int year;

  const MonthlyRevenue({
    required this.month,
    required this.amount,
    required this.year,
  });

  DateTime get date => DateTime(year, _monthNameToNumber(month));

  static int _monthNameToNumber(String monthName) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[monthName] ?? 1;
  }

  Map<String, dynamic> toMap() {
    return {'month': month, 'amount': amount, 'year': year};
  }

  factory MonthlyRevenue.fromMap(Map<String, dynamic> map) {
    return MonthlyRevenue(
      month: map['month'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      year: map['year'] ?? DateTime.now().year,
    );
  }
}

class DashboardStats {
  final int totalCustomers;
  final int totalInstallmentPlans;
  final int activeInstallmentPlans;
  final int completedInstallmentPlans;
  final int overdueInstallmentPlans;
  final double totalPendingAmount;
  final double totalPaidAmount;
  final double totalOverdueAmount;
  final int pendingPayments;
  final int paidPayments;
  final int overduePayments;
  final List<MonthlyRevenue> monthlyRevenue;

  const DashboardStats({
    required this.totalCustomers,
    required this.totalInstallmentPlans,
    required this.activeInstallmentPlans,
    required this.completedInstallmentPlans,
    required this.overdueInstallmentPlans,
    required this.totalPendingAmount,
    required this.totalPaidAmount,
    required this.totalOverdueAmount,
    required this.pendingPayments,
    required this.paidPayments,
    required this.overduePayments,
    required this.monthlyRevenue,
  });

  // Computed properties
  double get collectionRate {
    final total = totalPaidAmount + totalPendingAmount;
    return total > 0 ? (totalPaidAmount / total) * 100 : 0.0;
  }

  double get overdueRate {
    return totalInstallmentPlans > 0
        ? (overdueInstallmentPlans / totalInstallmentPlans) * 100
        : 0.0;
  }

  double get completionRate {
    return totalInstallmentPlans > 0
        ? (completedInstallmentPlans / totalInstallmentPlans) * 100
        : 0.0;
  }

  double get totalRevenue {
    return totalPaidAmount;
  }

  // Create empty stats
  factory DashboardStats.empty() {
    return const DashboardStats(
      totalCustomers: 0,
      totalInstallmentPlans: 0,
      activeInstallmentPlans: 0,
      completedInstallmentPlans: 0,
      overdueInstallmentPlans: 0,
      totalPendingAmount: 0.0,
      totalPaidAmount: 0.0,
      totalOverdueAmount: 0.0,
      pendingPayments: 0,
      paidPayments: 0,
      overduePayments: 0,
      monthlyRevenue: [],
    );
  }

  @override
  String toString() {
    return 'DashboardStats(customers: $totalCustomers, plans: $totalInstallmentPlans, revenue: $totalRevenue)';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/customer_provider.dart';
import '../providers/installment_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/customer.dart';
import '../models/installment_plan.dart';
import '../models/payment.dart';
import 'add_customer_screen.dart';
import 'add_installment_plan_screen.dart';
import '../constants/app_colors.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Customer? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomer();

    // Initialize data loading with proper timing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInstallmentData();
    });
  }

  void _loadCustomer() {
    final customerProvider = context.read<CustomerProvider>();
    _customer = customerProvider.getCustomerById(widget.customerId);
    setState(() {
      _isLoading = false;
    });
  }

  void _loadInstallmentData() {
    final installmentProvider = context.read<InstallmentProvider>();

    // Initialize the provider if needed
    if (!installmentProvider.isLoading) {
      installmentProvider.initializeInstallmentPlans();
      installmentProvider.initializePayments();
    }

    // Load customer-specific data
    installmentProvider.loadCustomerInstallmentPlans(widget.customerId);
    installmentProvider.loadCustomerPayments(widget.customerId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_customer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_customer!.name),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.iconPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCustomerScreen(customer: _customer),
                ),
              ).then((_) => _loadCustomer());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.person, color: AppColors.iconPrimary),
              text: 'Info',
            ),
            Tab(
              icon: Icon(Icons.assignment, color: AppColors.iconPrimary),
              text: 'Plans',
            ),
            Tab(
              icon: Icon(Icons.payment, color: AppColors.iconPrimary),
              text: 'Payments',
            ),
          ],
          indicatorColor: AppColors.accent,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.iconPrimary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomerInfoTab(),
          _buildInstallmentPlansTab(),
          _buildPaymentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddInstallmentPlanScreen(customer: _customer!),
            ),
          ).then((_) {
            // Refresh data when returning from add screen
            _loadInstallmentData();
            // Also refresh dashboard stats
            context.read<DashboardProvider>().refreshDashboard();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Plan'),
      ),
    );
  }

  Widget _buildCustomerInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer avatar and basic info
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _customer!.name.isNotEmpty
                          ? _customer!.name[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customer!.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer since ${DateFormat('MMM yyyy').format(_customer!.createdAt)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact information
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone, 'Phone', _customer!.phone),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.credit_card, 'NIC', _customer!.nic),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on,
                    'Address',
                    _customer!.address,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Additional information
          if (_customer!.notes.isNotEmpty) ...[
            Card(
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _customer!.notes,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Financial summary
          Consumer<InstallmentProvider>(
            builder: (context, installmentProvider, child) {
              final totalPending = installmentProvider
                  .getTotalPendingAmountForCustomer(widget.customerId);
              final totalPaid = installmentProvider
                  .getTotalPaidAmountForCustomer(widget.customerId);
              final nextPayment = installmentProvider
                  .getNextPaymentDueForCustomer(widget.customerId);

              return Card(
                color: AppColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Summary',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Paid',
                              NumberFormat.currency(
                                symbol: 'Rs. ',
                                decimalDigits: 0,
                              ).format(totalPaid),
                              Colors.green,
                              Icons.account_balance_wallet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Pending',
                              NumberFormat.currency(
                                symbol: 'Rs. ',
                                decimalDigits: 0,
                              ).format(totalPending),
                              Colors.orange,
                              Icons.schedule,
                            ),
                          ),
                        ],
                      ),
                      if (nextPayment != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: nextPayment.isOverdue
                                ? Colors.red.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: nextPayment.isOverdue
                                  ? Colors.red
                                  : Colors.blue,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                nextPayment.isOverdue
                                    ? Icons.warning
                                    : Icons.schedule,
                                color: nextPayment.isOverdue
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nextPayment.isOverdue
                                          ? 'Overdue Payment'
                                          : 'Next Payment',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: nextPayment.isOverdue
                                            ? Colors.red
                                            : Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      '${NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0).format(nextPayment.amount)} due on ${DateFormat('MMM dd, yyyy').format(nextPayment.dueDate)}',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildInstallmentPlansTab() {
    return Consumer<InstallmentProvider>(
      builder: (context, installmentProvider, child) {
        // Show loading state
        if (installmentProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Loading installment plans...',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          );
        }

        // Show error state
        if (installmentProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading plans',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  installmentProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _loadInstallmentData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: AppColors.buttonText,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final plans = installmentProvider.customerInstallmentPlans;

        // Debug information
        print('Customer ${widget.customerId} - Plans count: ${plans.length}');
        print(
          'All installment plans count: ${installmentProvider.installmentPlans.length}',
        );

        // Show empty state
        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: AppColors.iconPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No installment plans yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an installment plan for this customer',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddInstallmentPlanScreen(customer: _customer!),
                      ),
                    ).then((_) {
                      _loadInstallmentData();
                      context.read<DashboardProvider>().refreshDashboard();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: AppColors.buttonText,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Plan'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadInstallmentData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _buildInstallmentPlanCard(context, plan);
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    return Consumer<InstallmentProvider>(
      builder: (context, installmentProvider, child) {
        if (installmentProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (installmentProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading payments',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  installmentProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _loadInstallmentData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: AppColors.buttonText,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final payments = installmentProvider.customerPayments;

        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: AppColors.iconPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No payments yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Payments will appear here once received',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadInstallmentData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(context, payment);
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.iconPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentPlanCard(BuildContext context, InstallmentPlan plan) {
    // Calculate progress based on the plan status
    double progress = 0.0;
    if (plan.status == InstallmentStatus.completed) {
      progress = 1.0;
    } else if (plan.status == InstallmentStatus.active) {
      // For active plans, we could calculate progress based on payments
      // For now, we'll use a simple calculation
      progress = 0.5;
    }

    bool isActive = plan.status == InstallmentStatus.active;

    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.item,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Completed',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 16,
                  color: AppColors.iconPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  NumberFormat.currency(
                    symbol: 'Rs. ',
                    decimalDigits: 0,
                  ).format(plan.totalAmount),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.event, size: 16, color: AppColors.iconPrimary),
                const SizedBox(width: 8),
                Text(
                  '${plan.numberOfInstallments} months',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
                Text(
                  '${plan.numberOfInstallments}/${plan.numberOfInstallments} paid',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: payment.isOverdue
                ? Colors.red.withOpacity(0.2)
                : payment.status == PaymentStatus.paid
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            payment.isOverdue
                ? Icons.warning
                : payment.status == PaymentStatus.paid
                ? Icons.check_circle
                : Icons.schedule,
            color: payment.isOverdue
                ? Colors.red
                : payment.status == PaymentStatus.paid
                ? Colors.green
                : Colors.orange,
          ),
        ),
        title: Text(
          NumberFormat.currency(
            symbol: 'Rs. ',
            decimalDigits: 0,
          ).format(payment.amount),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Due: ${DateFormat('MMM dd, yyyy').format(payment.dueDate)}',
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              payment.status.toString().split('.').last.toUpperCase(),
              style: TextStyle(
                color: payment.isOverdue
                    ? Colors.red
                    : payment.status == PaymentStatus.paid
                    ? Colors.green
                    : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Text(
          DateFormat(
            'MMM dd, yyyy',
          ).format(payment.paidDate ?? payment.dueDate),
          style: TextStyle(
            color: AppColors.textPrimary.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        onTap: payment.status == PaymentStatus.paid
            ? null
            : () => _markPaymentAsPaid(
                payment,
              ), // Add onTap handler for pending payments
        enabled:
            payment.status != PaymentStatus.paid, // Disable for paid payments
      ),
    );
  }

  void _markPaymentAsPaid(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mark Payment as Paid',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Mark payment of ${NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0).format(payment.amount)} as paid?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardBackground,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<InstallmentProvider>()
                  .markPaymentAsPaid(payment.id!);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Payment marked as paid successfully'
                          : 'Failed to update payment',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );

                // Refresh data after marking payment as paid
                if (success) {
                  _loadInstallmentData();
                  context.read<DashboardProvider>().refreshDashboard();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonBackground,
              foregroundColor: AppColors.buttonText,
            ),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );
  }
}

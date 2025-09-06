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
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer!.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Info'),
            Tab(icon: Icon(Icons.assignment), text: 'Plans'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
          ],
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer since ${DateFormat('MMM yyyy').format(_customer!.createdAt)}',
                          style: Theme.of(context).textTheme.bodyMedium,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleMedium,
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _customer!.notes,
                      style: Theme.of(context).textTheme.bodyMedium,
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Summary',
                        style: Theme.of(context).textTheme.titleMedium,
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
                                ? Colors.red.shade50
                                : Colors.blue.shade50,
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading installment plans...'),
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
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading plans',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  installmentProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _loadInstallmentData();
                  },
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
          return RefreshIndicator(
            onRefresh: () async {
              _loadInstallmentData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No installment plans',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create an installment plan to get started',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddInstallmentPlanScreen(
                                customer: _customer!,
                              ),
                            ),
                          ).then((_) {
                            // Refresh data when returning from add screen
                            _loadInstallmentData();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Installment Plan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Show plans list with refresh capability
        return RefreshIndicator(
          onRefresh: () async {
            _loadInstallmentData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _buildInstallmentPlanCard(plan);
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    return Consumer<InstallmentProvider>(
      builder: (context, installmentProvider, child) {
        final payments = installmentProvider.customerPayments;

        if (payments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No payments found', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text(
                  'Payments will appear here once installment plans are created',
                ),
              ],
            ),
          );
        }

        // Group payments by status
        final pendingPayments = payments
            .where((p) => p.status == PaymentStatus.pending)
            .toList();
        final paidPayments = payments
            .where((p) => p.status == PaymentStatus.paid)
            .toList();
        final overduePayments = payments.where((p) => p.isOverdue).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overduePayments.isNotEmpty) ...[
                Text(
                  'Overdue Payments',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ...overduePayments.map(
                  (payment) => _buildPaymentCard(payment, isOverdue: true),
                ),
                const SizedBox(height: 16),
              ],

              if (pendingPayments.isNotEmpty) ...[
                Text(
                  'Pending Payments',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.orange),
                ),
                const SizedBox(height: 8),
                ...pendingPayments
                    .where((p) => !p.isOverdue)
                    .map((payment) => _buildPaymentCard(payment)),
                const SizedBox(height: 16),
              ],

              if (paidPayments.isNotEmpty) ...[
                Text(
                  'Paid Payments',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.green),
                ),
                const SizedBox(height: 8),
                ...paidPayments.map(
                  (payment) => _buildPaymentCard(payment, isPaid: true),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentPlanCard(InstallmentPlan plan) {
    Color statusColor;
    switch (plan.status) {
      case InstallmentStatus.active:
        statusColor = Colors.blue;
        break;
      case InstallmentStatus.completed:
        statusColor = Colors.green;
        break;
      case InstallmentStatus.overdue:
        statusColor = Colors.red;
        break;
      case InstallmentStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    plan.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPlanDetailItem(
                    'Total Amount',
                    NumberFormat.currency(
                      symbol: 'Rs. ',
                      decimalDigits: 0,
                    ).format(plan.totalAmount),
                  ),
                ),
                Expanded(
                  child: _buildPlanDetailItem(
                    'Advance Paid',
                    NumberFormat.currency(
                      symbol: 'Rs. ',
                      decimalDigits: 0,
                    ).format(plan.advancePaid),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPlanDetailItem(
                    'Installments',
                    '${plan.numberOfInstallments} payments',
                  ),
                ),
                Expanded(
                  child: _buildPlanDetailItem(
                    'Per Installment',
                    NumberFormat.currency(
                      symbol: 'Rs. ',
                      decimalDigits: 0,
                    ).format(plan.installmentAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPlanDetailItem(
              'Start Date',
              DateFormat('MMM dd, yyyy').format(plan.startDate),
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

  Widget _buildPaymentCard(
    Payment payment, {
    bool isOverdue = false,
    bool isPaid = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue
          ? Colors.red.shade50
          : (isPaid ? Colors.green.shade50 : null),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue
              ? Colors.red
              : (isPaid ? Colors.green : Colors.orange),
          child: Text(
            payment.installmentNumber.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          NumberFormat.currency(
            symbol: 'Rs. ',
            decimalDigits: 0,
          ).format(payment.amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Due: ${DateFormat('MMM dd, yyyy').format(payment.dueDate)}'),
            if (isPaid && payment.paidDate != null)
              Text(
                'Paid: ${DateFormat('MMM dd, yyyy').format(payment.paidDate!)}',
              ),
          ],
        ),
        trailing: isPaid
            ? const Icon(Icons.check_circle, color: Colors.green)
            : (isOverdue
                  ? const Icon(Icons.warning, color: Colors.red)
                  : IconButton(
                      icon: const Icon(Icons.payment),
                      onPressed: () => _markPaymentAsPaid(payment),
                    )),
      ),
    );
  }

  void _markPaymentAsPaid(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Payment as Paid'),
        content: Text(
          'Mark payment of ${NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0).format(payment.amount)} as paid?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                          ? 'Payment marked as paid'
                          : 'Failed to update payment',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );
  }
}

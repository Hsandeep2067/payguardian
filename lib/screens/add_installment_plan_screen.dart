import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/installment_provider.dart';
import '../models/customer.dart';
import '../models/installment_plan.dart';

class AddInstallmentPlanScreen extends StatefulWidget {
  final Customer customer;
  final InstallmentPlan? installmentPlan; // For editing existing plan

  const AddInstallmentPlanScreen({
    super.key,
    required this.customer,
    this.installmentPlan,
  });

  @override
  State<AddInstallmentPlanScreen> createState() =>
      _AddInstallmentPlanScreenState();
}

class _AddInstallmentPlanScreenState extends State<AddInstallmentPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _advancePaidController = TextEditingController();
  final _numberOfInstallmentsController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _dueDate; // Added due date variable
  bool _isLoading = false;
  double _balanceAmount = 0.0;
  double _installmentAmount = 0.0;

  bool get _isEditing => widget.installmentPlan != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
    _advancePaidController.text = '0';
    _calculateAmounts();
  }

  void _populateFields() {
    final plan = widget.installmentPlan!;
    _itemController.text = plan.item;
    _totalAmountController.text = plan.totalAmount.toString();
    _advancePaidController.text = plan.advancePaid.toString();
    _numberOfInstallmentsController.text = plan.numberOfInstallments.toString();
    _startDate = plan.startDate;
    _dueDate = plan.dueDate; // Populate due date
  }

  void _calculateAmounts() {
    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    final advancePaid = double.tryParse(_advancePaidController.text) ?? 0.0;
    final numberOfInstallments =
        int.tryParse(_numberOfInstallmentsController.text) ?? 1;

    setState(() {
      _balanceAmount = totalAmount - advancePaid;
      _installmentAmount = numberOfInstallments > 0
          ? _balanceAmount / numberOfInstallments
          : 0.0;
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _totalAmountController.dispose();
    _advancePaidController.dispose();
    _numberOfInstallmentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Installment Plan' : 'Add Installment Plan',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          widget.customer.name.isNotEmpty
                              ? widget.customer.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Colors.white,
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
                              widget.customer.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              widget.customer.phone,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Item field
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Item/Product *',
                  hintText: 'Enter item or product name',
                  prefixIcon: Icon(Icons.shopping_cart),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Item is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Total amount field
              TextFormField(
                controller: _totalAmountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount (Rs.) *',
                  hintText: 'Enter total amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Total amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                onChanged: (value) => _calculateAmounts(),
              ),
              const SizedBox(height: 16),

              // Advance paid field
              TextFormField(
                controller: _advancePaidController,
                decoration: const InputDecoration(
                  labelText: 'Advance Paid (Rs.)',
                  hintText: 'Enter advance amount paid',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final totalAmount =
                      double.tryParse(_totalAmountController.text) ?? 0.0;
                  final advancePaid = double.tryParse(value ?? '0') ?? 0.0;

                  if (advancePaid < 0) {
                    return 'Advance amount cannot be negative';
                  }
                  if (advancePaid >= totalAmount) {
                    return 'Advance amount must be less than total amount';
                  }
                  return null;
                },
                onChanged: (value) => _calculateAmounts(),
              ),
              const SizedBox(height: 16),

              // Number of installments field
              TextFormField(
                controller: _numberOfInstallmentsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Installments *',
                  hintText: 'Enter number of installments',
                  prefixIcon: Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Number of installments is required';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Please enter a valid number';
                  }
                  if (number > 120) {
                    return 'Maximum 120 installments allowed';
                  }
                  return null;
                },
                onChanged: (value) => _calculateAmounts(),
              ),
              const SizedBox(height: 16),

              // Start date picker
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_startDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Due date picker
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date (Optional)',
                    prefixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                        : 'Select due date',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Calculation summary card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculation Summary',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Total Amount:',
                        _totalAmountController.text.isEmpty
                            ? 'Rs. 0'
                            : 'Rs. ${NumberFormat('#,##0').format(double.tryParse(_totalAmountController.text) ?? 0)}',
                      ),
                      _buildSummaryRow(
                        'Advance Paid:',
                        _advancePaidController.text.isEmpty
                            ? 'Rs. 0'
                            : 'Rs. ${NumberFormat('#,##0').format(double.tryParse(_advancePaidController.text) ?? 0)}',
                      ),
                      _buildSummaryRow(
                        'Balance Amount:',
                        'Rs. ${NumberFormat('#,##0').format(_balanceAmount)}',
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Per Installment:',
                        'Rs. ${NumberFormat('#,##0').format(_installmentAmount)}',
                        isBold: true,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isLoading
                      ? 'Processing...'
                      : (_isEditing ? 'Update Plan' : 'Create Plan'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel button
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // Added due date selection method
  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final installmentPlan = InstallmentPlan.create(
        id: _isEditing ? widget.installmentPlan!.id : null,
        customerId: widget.customer.id!,
        item: _itemController.text.trim(),
        totalAmount: double.parse(_totalAmountController.text),
        advancePaid: double.parse(_advancePaidController.text),
        numberOfInstallments: int.parse(_numberOfInstallmentsController.text),
        startDate: _startDate,
        dueDate: _dueDate, // Added due date
      );

      final installmentProvider = context.read<InstallmentProvider>();
      bool success;

      if (_isEditing) {
        success = await installmentProvider.updateInstallmentPlan(
          installmentPlan,
        );
      } else {
        success = await installmentProvider.addInstallmentPlan(installmentPlan);
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Installment plan updated successfully'
                    : 'Installment plan created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          String errorMessage =
              installmentProvider.error ??
              'Failed to ${_isEditing ? 'update' : 'create'} installment plan';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

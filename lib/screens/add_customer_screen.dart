import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/customer_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/customer.dart';
import '../constants/app_colors.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer; // For editing existing customer

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _referenceController = TextEditingController();

  bool _isLoading = false;
  bool _createInstallmentPlan = false;
  String _customerType = 'Regular';
  int _riskLevel = 1; // 1-5 scale
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }

    // Load dashboard stats for preview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().checkAndRefreshIfNeeded();
    });
  }

  void _populateFields() {
    final customer = widget.customer!;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _nicController.text = customer.nic;
    _addressController.text = customer.address;
    _notesController.text = customer.notes;
    // Populate new business information fields
    _customerType = customer.customerType;
    if (customer.creditLimit != null) {
      _creditLimitController.text = customer.creditLimit.toString();
    }
    _riskLevel = customer.riskLevel;
    _referenceController.text = customer.referenceContact;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _creditLimitController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Customer' : 'Add Customer'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dashboard Statistics Preview (for context)
              if (!_isEditing) _buildDashboardPreview(context),

              // Header card
              Card(
                color: AppColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        _isEditing ? Icons.person : Icons.person_add,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isEditing
                            ? 'Update customer information'
                            : 'Add New Customer to Grow Your Business',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      if (!_isEditing) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Each new customer increases your business potential',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter customer\'s full name',
                  prefixIcon: Icon(Icons.person, color: AppColors.iconPrimary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  hintStyle: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Clear validation errors on change
                  if (_formKey.currentState?.validate() == false) {
                    _formKey.currentState?.validate();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone, color: AppColors.iconPrimary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  hintStyle: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // NIC field
              TextFormField(
                controller: _nicController,
                decoration: InputDecoration(
                  labelText: 'NIC Number *',
                  hintText: 'Enter NIC number',
                  prefixIcon: Icon(
                    Icons.credit_card,
                    color: AppColors.iconPrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  hintStyle: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NIC number is required';
                  }
                  if (value.trim().length < 9) {
                    return 'Invalid NIC number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter customer address',
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: AppColors.iconPrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  hintStyle: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Business Information Section
              Card(
                color: AppColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, color: AppColors.iconPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Business Information',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Customer Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _customerType,
                        decoration: InputDecoration(
                          labelText: 'Customer Type',
                          prefixIcon: Icon(
                            Icons.category,
                            color: AppColors.iconPrimary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.accent,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          labelStyle: TextStyle(color: AppColors.textPrimary),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Regular',
                            child: Text('Regular'),
                          ),
                          DropdownMenuItem(
                            value: 'Premium',
                            child: Text('Premium'),
                          ),
                          DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                          DropdownMenuItem(
                            value: 'Corporate',
                            child: Text('Corporate'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _customerType = value;
                            });
                          }
                        },
                        style: TextStyle(color: AppColors.textPrimary),
                        dropdownColor: AppColors.cardBackground,
                      ),
                      const SizedBox(height: 16),

                      // Credit Limit Field
                      TextFormField(
                        controller: _creditLimitController,
                        decoration: InputDecoration(
                          labelText: 'Credit Limit (Rs.)',
                          hintText: 'Enter credit limit',
                          prefixIcon: Icon(
                            Icons.account_balance,
                            color: AppColors.iconPrimary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.accent,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          labelStyle: TextStyle(color: AppColors.textPrimary),
                          hintStyle: TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                        style: TextStyle(color: AppColors.textPrimary),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final creditLimit = double.tryParse(value);
                            if (creditLimit == null || creditLimit < 0) {
                              return 'Please enter a valid credit limit';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Risk Assessment Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risk Assessment: ${_getRiskLabel(_riskLevel)} ($_riskLevel/5)',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.border,
                              thumbColor: AppColors.primary,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12.0,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 24.0,
                              ),
                            ),
                            child: Slider(
                              value: _riskLevel.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              label: _getRiskLabel(_riskLevel),
                              onChanged: (value) {
                                setState(() {
                                  _riskLevel = value.toInt();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Reference Contact Field
                      TextFormField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: 'Reference Contact',
                          hintText: 'Enter reference contact number',
                          prefixIcon: Icon(
                            Icons.contact_phone,
                            color: AppColors.iconPrimary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.accent,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          labelStyle: TextStyle(color: AppColors.textPrimary),
                          hintStyle: TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                        style: TextStyle(color: AppColors.textPrimary),
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      // Create Installment Plan Toggle
                      if (!_isEditing) ...[
                        Divider(color: AppColors.border),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Installment Plan',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create an installment plan immediately after adding this customer',
                                    style: TextStyle(
                                      color: AppColors.textPrimary.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _createInstallmentPlan,
                              onChanged: (value) {
                                setState(() {
                                  _createInstallmentPlan = value;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Additional notes about the customer',
                  prefixIcon: Icon(Icons.note, color: AppColors.iconPrimary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  labelStyle: TextStyle(color: AppColors.textPrimary),
                  hintStyle: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBackground,
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBackground,
                        foregroundColor: AppColors.buttonText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Update Customer' : 'Add Customer',
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardPreview(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        final stats = dashboardProvider.dashboardStats;
        if (stats == null) return const SizedBox.shrink();

        return Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Current Business Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatCard(
                        context,
                        'Total Customers',
                        stats.totalCustomers.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniStatCard(
                        context,
                        'Active Plans',
                        stats.activeInstallmentPlans.toString(),
                        Icons.assignment,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Adding a new customer will increase your total customer count to ${stats.totalCustomers + 1}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getRiskLabel(int risk) {
    switch (risk) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Medium';
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      // Build enhanced notes with business information
      String enhancedNotes = _notesController.text.trim();
      if (!_isEditing) {
        final businessInfo = [];
        businessInfo.add('Type: $_customerType');
        businessInfo.add(
          'Risk Level: ${_getRiskLabel(_riskLevel)} ($_riskLevel/5)',
        );

        if (_creditLimitController.text.isNotEmpty) {
          businessInfo.add('Credit Limit: Rs. ${_creditLimitController.text}');
        }

        if (_referenceController.text.isNotEmpty) {
          businessInfo.add('Reference: ${_referenceController.text}');
        }

        if (businessInfo.isNotEmpty) {
          if (enhancedNotes.isNotEmpty) enhancedNotes += '\n\n';
          enhancedNotes += 'Business Info: ${businessInfo.join(', ')}';
        }
      }

      final customer = _isEditing
          ? widget.customer!.copyWith(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              nic: _nicController.text.trim(),
              address: _addressController.text.trim(),
              notes: enhancedNotes,
              // New business information fields
              customerType: _customerType,
              creditLimit: _creditLimitController.text.isEmpty
                  ? null
                  : double.tryParse(_creditLimitController.text),
              riskLevel: _riskLevel,
              referenceContact: _referenceController.text.trim(),
              updatedAt: now,
            )
          : Customer(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              nic: _nicController.text.trim(),
              address: _addressController.text.trim(),
              notes: enhancedNotes,
              // New business information fields
              customerType: _customerType,
              creditLimit: _creditLimitController.text.isEmpty
                  ? null
                  : double.tryParse(_creditLimitController.text),
              riskLevel: _riskLevel,
              referenceContact: _referenceController.text.trim(),
              createdAt: now,
              updatedAt: now,
            );

      final customerProvider = context.read<CustomerProvider>();
      bool success;

      if (_isEditing) {
        success = await customerProvider.updateCustomer(customer);
      } else {
        success = await customerProvider.addCustomer(customer);
      }

      if (mounted) {
        if (success) {
          // Refresh dashboard statistics
          context.read<DashboardProvider>().refreshDashboard();

          Navigator.pop(context);

          // Show success message with enhanced information
          final message = _isEditing
              ? 'Customer updated successfully'
              : 'Customer added successfully! ${_createInstallmentPlan ? 'Create an installment plan next.' : ''}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.success,
              action: !_isEditing && _createInstallmentPlan
                  ? SnackBarAction(
                      label: 'CREATE PLAN',
                      onPressed: () {
                        // Navigate to create installment plan
                        // This would need to be implemented
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Navigate to create installment plan',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
        } else {
          String errorMessage =
              customerProvider.error ??
              'Failed to ${_isEditing ? 'update' : 'add'} customer';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppColors.error,
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

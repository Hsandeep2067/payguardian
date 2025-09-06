import 'package:flutter/foundation.dart';
import '../models/installment_plan.dart';
import '../models/payment.dart';
import '../services/firestore_service.dart';

class InstallmentProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<InstallmentPlan> _installmentPlans = [];
  List<InstallmentPlan> _customerInstallmentPlans = [];
  List<Payment> _payments = [];
  List<Payment> _customerPayments = [];
  List<Payment> _overduePayments = [];
  List<Payment> _paymentsDueSoon = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<InstallmentPlan> get installmentPlans => _installmentPlans;
  List<InstallmentPlan> get customerInstallmentPlans =>
      _customerInstallmentPlans;
  List<Payment> get payments => _payments;
  List<Payment> get customerPayments => _customerPayments;
  List<Payment> get overduePayments => _overduePayments;
  List<Payment> get paymentsDueSoon => _paymentsDueSoon;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize all installment plans
  void initializeInstallmentPlans() {
    _setLoading(true);
    _firestoreService.getInstallmentPlans().listen(
      (plans) {
        _installmentPlans = plans;
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load installment plans: $error');
        _setLoading(false);
      },
    );
  }

  // Initialize payments
  void initializePayments() {
    _firestoreService.getPayments().listen(
      (payments) {
        _payments = payments;
        _updatePaymentLists();
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load payments: $error');
      },
    );
  }

  // Load installment plans for specific customer
  void loadCustomerInstallmentPlans(String customerId) {
    print('Loading installment plans for customer: $customerId');
    _firestoreService
        .getInstallmentPlans(customerId: customerId)
        .listen(
          (plans) {
            print(
              'Received ${plans.length} installment plans for customer $customerId',
            );
            _customerInstallmentPlans = plans;
            notifyListeners();
          },
          onError: (error) {
            print('Error loading customer installment plans: $error');
            _setError('Failed to load customer installment plans: $error');
          },
        );
  }

  // Load payments for specific customer
  void loadCustomerPayments(String customerId) {
    _firestoreService
        .getPayments(customerId: customerId)
        .listen(
          (payments) {
            _customerPayments = payments;
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load customer payments: $error');
          },
        );
  }

  // Add new installment plan
  Future<bool> addInstallmentPlan(InstallmentPlan plan) async {
    try {
      _setLoading(true);
      await _firestoreService.addInstallmentPlan(plan);
      _setError(null);
      return true;
    } catch (e) {
      _setError('Failed to add installment plan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update installment plan
  Future<bool> updateInstallmentPlan(InstallmentPlan plan) async {
    try {
      _setLoading(true);
      await _firestoreService.updateInstallmentPlan(plan);
      _setError(null);
      return true;
    } catch (e) {
      _setError('Failed to update installment plan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete installment plan
  Future<bool> deleteInstallmentPlan(String planId) async {
    try {
      _setLoading(true);
      await _firestoreService.deleteInstallmentPlan(planId);
      _setError(null);
      return true;
    } catch (e) {
      _setError('Failed to delete installment plan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mark payment as paid
  Future<bool> markPaymentAsPaid(
    String paymentId, {
    DateTime? paymentDate,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      await _firestoreService.markPaymentAsPaid(
        paymentId,
        paymentDate: paymentDate,
        notes: notes,
      );
      _setError(null);
      return true;
    } catch (e) {
      _setError('Failed to mark payment as paid: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get installment plan by ID
  InstallmentPlan? getInstallmentPlanById(String planId) {
    try {
      return _installmentPlans.firstWhere((plan) => plan.id == planId);
    } catch (e) {
      return null;
    }
  }

  // Get payments for specific installment plan
  List<Payment> getPaymentsForPlan(String planId) {
    return _payments
        .where((payment) => payment.installmentPlanId == planId)
        .toList();
  }

  // Get active installment plans for customer
  List<InstallmentPlan> getActiveInstallmentPlansForCustomer(
    String customerId,
  ) {
    return _installmentPlans
        .where(
          (plan) =>
              plan.customerId == customerId &&
              plan.status == InstallmentStatus.active,
        )
        .toList();
  }

  // Get completed installment plans for customer
  List<InstallmentPlan> getCompletedInstallmentPlansForCustomer(
    String customerId,
  ) {
    return _installmentPlans
        .where(
          (plan) =>
              plan.customerId == customerId &&
              plan.status == InstallmentStatus.completed,
        )
        .toList();
  }

  // Calculate total pending amount for customer
  double getTotalPendingAmountForCustomer(String customerId) {
    return _payments
        .where(
          (payment) =>
              payment.customerId == customerId &&
              payment.status == PaymentStatus.pending,
        )
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  // Calculate total paid amount for customer
  double getTotalPaidAmountForCustomer(String customerId) {
    return _payments
        .where(
          (payment) =>
              payment.customerId == customerId &&
              payment.status == PaymentStatus.paid,
        )
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  // Get next payment due for customer
  Payment? getNextPaymentDueForCustomer(String customerId) {
    final pendingPayments = _payments
        .where(
          (payment) =>
              payment.customerId == customerId &&
              payment.status == PaymentStatus.pending,
        )
        .toList();

    if (pendingPayments.isEmpty) return null;

    pendingPayments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pendingPayments.first;
  }

  // Private helper methods
  void _updatePaymentLists() {
    _overduePayments = _payments.where((payment) => payment.isOverdue).toList();
    _paymentsDueSoon = _payments.where((payment) => payment.isDueSoon).toList();
  }

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
}

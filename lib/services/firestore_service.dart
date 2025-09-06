import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/installment_plan.dart';
import '../models/payment.dart';
import '../models/dashboard_stats.dart';
import '../models/installment_plan.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Make db accessible for connection checks
  FirebaseFirestore get db => _db;

  // Collection references
  static const String _customersCollection = 'customers';
  static const String _installmentPlansCollection = 'installmentPlans';
  static const String _paymentsCollection = 'payments';

  // Customer operations
  Future<String> addCustomer(Customer customer) async {
    try {
      final docRef = await _db
          .collection(_customersCollection)
          .add(customer.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  Stream<List<Customer>> getCustomers() {
    return _db
        .collection(_customersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Customer.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<Customer?> getCustomer(String customerId) async {
    try {
      final doc = await _db
          .collection(_customersCollection)
          .doc(customerId)
          .get();
      if (doc.exists) {
        return Customer.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null)
      throw Exception('Customer ID is required for update');
    try {
      await _db
          .collection(_customersCollection)
          .doc(customer.id)
          .update(customer.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      // Use batch to delete customer and all related data
      final batch = _db.batch();

      // Delete customer
      batch.delete(_db.collection(_customersCollection).doc(customerId));

      // Delete all installment plans for this customer
      final installmentPlans = await _db
          .collection(_installmentPlansCollection)
          .where('customerId', isEqualTo: customerId)
          .get();

      for (final doc in installmentPlans.docs) {
        batch.delete(doc.reference);
      }

      // Delete all payments for this customer
      final payments = await _db
          .collection(_paymentsCollection)
          .where('customerId', isEqualTo: customerId)
          .get();

      for (final doc in payments.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  // Installment Plan operations
  Future<String> addInstallmentPlan(InstallmentPlan plan) async {
    try {
      final docRef = await _db
          .collection(_installmentPlansCollection)
          .add(plan.toMap());

      // Generate payment schedule
      await _generatePaymentSchedule(docRef.id, plan);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add installment plan: $e');
    }
  }

  Stream<List<InstallmentPlan>> getInstallmentPlans({String? customerId}) {
    if (customerId != null) {
      // For customer-specific queries, use simple where clause without ordering
      return _db
          .collection(_installmentPlansCollection)
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) {
            var plans = snapshot.docs
                .map(
                  (doc) => InstallmentPlan.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();

            // Sort in memory by createdAt descending
            plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return plans;
          });
    } else {
      // For all plans, use ordering without where clause
      return _db
          .collection(_installmentPlansCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => InstallmentPlan.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList(),
          );
    }
  }

  Future<InstallmentPlan?> getInstallmentPlan(String planId) async {
    try {
      final doc = await _db
          .collection(_installmentPlansCollection)
          .doc(planId)
          .get();
      if (doc.exists) {
        return InstallmentPlan.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get installment plan: $e');
    }
  }

  Future<void> updateInstallmentPlan(InstallmentPlan plan) async {
    if (plan.id == null) throw Exception('Plan ID is required for update');
    try {
      await _db
          .collection(_installmentPlansCollection)
          .doc(plan.id)
          .update(plan.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Failed to update installment plan: $e');
    }
  }

  Future<void> deleteInstallmentPlan(String planId) async {
    try {
      final batch = _db.batch();

      // Delete installment plan
      batch.delete(_db.collection(_installmentPlansCollection).doc(planId));

      // Delete all payments for this plan
      final payments = await _db
          .collection(_paymentsCollection)
          .where('installmentPlanId', isEqualTo: planId)
          .get();

      for (final doc in payments.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete installment plan: $e');
    }
  }

  // Payment operations
  Stream<List<Payment>> getPayments({
    String? customerId,
    String? installmentPlanId,
  }) {
    Query query;

    if (customerId != null) {
      // For customer-specific queries, filter by customerId
      query = _db
          .collection(_paymentsCollection)
          .where('customerId', isEqualTo: customerId);
    } else if (installmentPlanId != null) {
      // For plan-specific queries, filter by installmentPlanId
      query = _db
          .collection(_paymentsCollection)
          .where('installmentPlanId', isEqualTo: installmentPlanId);
    } else {
      // For all payments, order by dueDate
      query = _db
          .collection(_paymentsCollection)
          .orderBy('dueDate', descending: false);
    }

    return query.snapshots().map((snapshot) {
      var payments = snapshot.docs
          .map(
            (doc) =>
                Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Sort in memory for filtered queries
      if (customerId != null || installmentPlanId != null) {
        payments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      }

      return payments;
    });
  }

  Future<void> markPaymentAsPaid(
    String paymentId, {
    DateTime? paymentDate,
    String? notes,
  }) async {
    try {
      final payment = await getPayment(paymentId);
      if (payment == null) throw Exception('Payment not found');

      final updatedPayment = payment.markAsPaid(
        paymentDate: paymentDate,
        notes: notes,
      );

      await _db
          .collection(_paymentsCollection)
          .doc(paymentId)
          .update(updatedPayment.toMap());

      // Check if all payments for this plan are completed
      await _checkAndUpdatePlanStatus(payment.installmentPlanId);
    } catch (e) {
      throw Exception('Failed to mark payment as paid: $e');
    }
  }

  Future<Payment?> getPayment(String paymentId) async {
    try {
      final doc = await _db
          .collection(_paymentsCollection)
          .doc(paymentId)
          .get();
      if (doc.exists) {
        return Payment.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  // Dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Get customers count
      final customersSnapshot = await _db
          .collection(_customersCollection)
          .count()
          .get();
      final totalCustomers = customersSnapshot.count ?? 0;

      // Get installment plans data
      final plansSnapshot = await _db
          .collection(_installmentPlansCollection)
          .get();
      final plans = plansSnapshot.docs
          .map((doc) => InstallmentPlan.fromMap(doc.data(), doc.id))
          .toList();

      // Get payments data
      final paymentsSnapshot = await _db.collection(_paymentsCollection).get();
      final payments = paymentsSnapshot.docs
          .map((doc) => Payment.fromMap(doc.data(), doc.id))
          .toList();

      // Calculate statistics
      final totalInstallmentPlans = plans.length;
      final activeInstallmentPlans = plans
          .where((p) => p.status == InstallmentStatus.active)
          .length;
      final completedInstallmentPlans = plans
          .where((p) => p.status == InstallmentStatus.completed)
          .length;
      final overdueInstallmentPlans = plans
          .where((p) => p.status == InstallmentStatus.overdue)
          .length;

      final pendingPayments = payments
          .where((p) => p.status == PaymentStatus.pending)
          .length;
      final paidPayments = payments
          .where((p) => p.status == PaymentStatus.paid)
          .length;
      final overduePayments = payments
          .where((p) => p.status == PaymentStatus.overdue)
          .length;

      final totalPendingAmount = payments
          .where((p) => p.status == PaymentStatus.pending)
          .fold(0.0, (sum, p) => sum + p.amount);

      final totalPaidAmount = payments
          .where((p) => p.status == PaymentStatus.paid)
          .fold(0.0, (sum, p) => sum + p.amount);

      final totalOverdueAmount = payments
          .where((p) => p.status == PaymentStatus.overdue)
          .fold(0.0, (sum, p) => sum + p.amount);

      // Calculate monthly revenue (last 12 months)
      final monthlyRevenue = _calculateMonthlyRevenue(payments);

      return DashboardStats(
        totalCustomers: totalCustomers,
        totalInstallmentPlans: totalInstallmentPlans,
        activeInstallmentPlans: activeInstallmentPlans,
        completedInstallmentPlans: completedInstallmentPlans,
        overdueInstallmentPlans: overdueInstallmentPlans,
        totalPendingAmount: totalPendingAmount,
        totalPaidAmount: totalPaidAmount,
        totalOverdueAmount: totalOverdueAmount,
        pendingPayments: pendingPayments,
        paidPayments: paidPayments,
        overduePayments: overduePayments,
        monthlyRevenue: monthlyRevenue,
      );
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  // Private helper methods
  Future<void> _generatePaymentSchedule(
    String planId,
    InstallmentPlan plan,
  ) async {
    final batch = _db.batch();

    for (int i = 1; i <= plan.numberOfInstallments; i++) {
      final dueDate = DateTime(
        plan.startDate.year,
        plan.startDate.month + i,
        plan.startDate.day,
      );

      final payment = Payment(
        installmentPlanId: planId,
        customerId: plan.customerId,
        amount: plan.installmentAmount,
        dueDate: dueDate,
        status: PaymentStatus.pending,
        notes: 'Auto-generated payment $i of ${plan.numberOfInstallments}',
        installmentNumber: i,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final paymentRef = _db.collection(_paymentsCollection).doc();
      batch.set(paymentRef, payment.toMap());
    }

    await batch.commit();
  }

  Future<void> _checkAndUpdatePlanStatus(String planId) async {
    try {
      final payments = await _db
          .collection(_paymentsCollection)
          .where('installmentPlanId', isEqualTo: planId)
          .get();

      final allPayments = payments.docs
          .map((doc) => Payment.fromMap(doc.data(), doc.id))
          .toList();

      final allPaid = allPayments.every((p) => p.status == PaymentStatus.paid);
      final hasOverdue = allPayments.any((p) => p.isOverdue);

      InstallmentStatus newStatus;
      if (allPaid) {
        newStatus = InstallmentStatus.completed;
      } else if (hasOverdue) {
        newStatus = InstallmentStatus.overdue;
      } else {
        newStatus = InstallmentStatus.active;
      }

      await _db.collection(_installmentPlansCollection).doc(planId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating plan status: $e');
    }
  }

  List<MonthlyRevenue> _calculateMonthlyRevenue(List<Payment> payments) {
    final now = DateTime.now();
    final monthlyData = <String, double>{};

    // Initialize last 12 months
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = '${_getMonthAbbreviation(date.month)}-${date.year}';
      monthlyData[monthKey] = 0.0;
    }

    // Sum paid payments by month
    for (final payment in payments) {
      if (payment.status == PaymentStatus.paid && payment.paidDate != null) {
        final paidDate = payment.paidDate!;
        final monthKey =
            '${_getMonthAbbreviation(paidDate.month)}-${paidDate.year}';

        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = monthlyData[monthKey]! + payment.amount;
        }
      }
    }

    return monthlyData.entries
        .map(
          (entry) => MonthlyRevenue(
            month: entry.key.split('-')[0],
            amount: entry.value,
            year: int.parse(entry.key.split('-')[1]),
          ),
        )
        .toList();
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

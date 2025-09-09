import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, paid, overdue, cancelled }

class Payment {
  final String? id;
  final String installmentPlanId;
  final String customerId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final PaymentStatus status;
  final String notes;
  final int installmentNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    this.id,
    required this.installmentPlanId,
    required this.customerId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    required this.notes,
    required this.installmentNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Payment to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'installmentPlanId': installmentPlanId,
      'customerId': customerId,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'status': status.name,
      'notes': notes,
      'installmentNumber': installmentNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Payment from Firestore Map
  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      installmentPlanId: map['installmentPlanId'] ?? '',
      customerId: map['customerId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidDate: (map['paidDate'] as Timestamp?)?.toDate(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      notes: map['notes'] ?? '',
      installmentNumber: map['installmentNumber'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Mark payment as paid
  Payment markAsPaid({DateTime? paymentDate, String? notes}) {
    return copyWith(
      status: PaymentStatus.paid,
      paidDate: paymentDate ?? DateTime.now(),
      notes: notes ?? this.notes,
      updatedAt: DateTime.now(),
    );
  }

  // Check if payment is overdue
  bool get isOverdue {
    // A payment is overdue if:
    // 1. It's still pending
    // 2. The due date has passed (including today)
    return status == PaymentStatus.pending &&
        !DateTime.now().isBefore(dueDate);
  }

  // Check if payment is due soon (within 7 days)
  bool get isDueSoon {
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    return status == PaymentStatus.pending &&
        daysUntilDue <= 7 &&
        daysUntilDue >= 0;
  }

  // Create a copy with updated fields
  Payment copyWith({
    String? id,
    String? installmentPlanId,
    String? customerId,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    PaymentStatus? status,
    String? notes,
    int? installmentNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      installmentPlanId: installmentPlanId ?? this.installmentPlanId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Payment(id: $id, amount: $amount, dueDate: $dueDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment &&
        other.id == id &&
        other.installmentPlanId == installmentPlanId &&
        other.customerId == customerId &&
        other.amount == amount &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        installmentPlanId.hashCode ^
        customerId.hashCode ^
        amount.hashCode ^
        status.hashCode;
  }
}

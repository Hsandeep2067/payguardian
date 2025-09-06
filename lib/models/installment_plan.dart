import 'package:cloud_firestore/cloud_firestore.dart';

enum InstallmentStatus { active, completed, cancelled, overdue }

class InstallmentPlan {
  final String? id;
  final String customerId;
  final String item;
  final double totalAmount;
  final double advancePaid;
  final double balanceAmount;
  final int numberOfInstallments;
  final double installmentAmount;
  final DateTime startDate;
  final InstallmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPlan({
    this.id,
    required this.customerId,
    required this.item,
    required this.totalAmount,
    required this.advancePaid,
    required this.balanceAmount,
    required this.numberOfInstallments,
    required this.installmentAmount,
    required this.startDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert InstallmentPlan to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'item': item,
      'totalAmount': totalAmount,
      'advancePaid': advancePaid,
      'balanceAmount': balanceAmount,
      'numberOfInstallments': numberOfInstallments,
      'installmentAmount': installmentAmount,
      'startDate': Timestamp.fromDate(startDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create InstallmentPlan from Firestore Map
  factory InstallmentPlan.fromMap(Map<String, dynamic> map, String id) {
    return InstallmentPlan(
      id: id,
      customerId: map['customerId'] ?? '',
      item: map['item'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      advancePaid: (map['advancePaid'] ?? 0).toDouble(),
      balanceAmount: (map['balanceAmount'] ?? 0).toDouble(),
      numberOfInstallments: map['numberOfInstallments'] ?? 0,
      installmentAmount: (map['installmentAmount'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: InstallmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InstallmentStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Factory constructor to create with calculated fields
  factory InstallmentPlan.create({
    String? id,
    required String customerId,
    required String item,
    required double totalAmount,
    required double advancePaid,
    required int numberOfInstallments,
    required DateTime startDate,
    InstallmentStatus status = InstallmentStatus.active,
  }) {
    final balance = totalAmount - advancePaid;
    final installmentValue = numberOfInstallments > 0
        ? balance / numberOfInstallments
        : 0.0;
    final now = DateTime.now();

    return InstallmentPlan(
      id: id,
      customerId: customerId,
      item: item,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      balanceAmount: balance,
      numberOfInstallments: numberOfInstallments,
      installmentAmount: installmentValue,
      startDate: startDate,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create a copy with updated fields
  InstallmentPlan copyWith({
    String? id,
    String? customerId,
    String? item,
    double? totalAmount,
    double? advancePaid,
    double? balanceAmount,
    int? numberOfInstallments,
    double? installmentAmount,
    DateTime? startDate,
    InstallmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentPlan(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      item: item ?? this.item,
      totalAmount: totalAmount ?? this.totalAmount,
      advancePaid: advancePaid ?? this.advancePaid,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      numberOfInstallments: numberOfInstallments ?? this.numberOfInstallments,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'InstallmentPlan(id: $id, item: $item, totalAmount: $totalAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstallmentPlan &&
        other.id == id &&
        other.customerId == customerId &&
        other.item == item &&
        other.totalAmount == totalAmount &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        customerId.hashCode ^
        item.hashCode ^
        totalAmount.hashCode ^
        status.hashCode;
  }
}

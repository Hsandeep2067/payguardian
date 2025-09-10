import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String? id;
  final String name;
  final String phone;
  final String nic;
  final String address;
  final String notes;
  // New business information fields
  final String customerType;
  final double? creditLimit;
  final int riskLevel;
  final String referenceContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.nic,
    required this.address,
    required this.notes,
    // New business information fields
    this.customerType = 'Regular',
    this.creditLimit,
    this.riskLevel = 1,
    this.referenceContact = '',
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Customer to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'nic': nic,
      'address': address,
      'notes': notes,
      // New business information fields
      'customerType': customerType,
      'creditLimit': creditLimit,
      'riskLevel': riskLevel,
      'referenceContact': referenceContact,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Customer from Firestore Map
  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      nic: map['nic'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      // New business information fields
      customerType: map['customerType'] ?? 'Regular',
      creditLimit: map['creditLimit'] is num
          ? map['creditLimit'].toDouble()
          : null,
      riskLevel: map['riskLevel'] ?? 1,
      referenceContact: map['referenceContact'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create a copy with updated fields
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? nic,
    String? address,
    String? notes,
    // New business information fields
    String? customerType,
    double? creditLimit,
    int? riskLevel,
    String? referenceContact,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      nic: nic ?? this.nic,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      // New business information fields
      customerType: customerType ?? this.customerType,
      creditLimit: creditLimit ?? this.creditLimit,
      riskLevel: riskLevel ?? this.riskLevel,
      referenceContact: referenceContact ?? this.referenceContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, nic: $nic, customerType: $customerType, riskLevel: $riskLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.nic == nic &&
        other.address == address &&
        other.notes == notes &&
        other.customerType == customerType &&
        other.creditLimit == creditLimit &&
        other.riskLevel == riskLevel &&
        other.referenceContact == referenceContact;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        nic.hashCode ^
        address.hashCode ^
        notes.hashCode ^
        customerType.hashCode ^
        creditLimit.hashCode ^
        riskLevel.hashCode ^
        referenceContact.hashCode;
  }
}

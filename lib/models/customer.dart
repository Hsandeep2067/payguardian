import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String? id;
  final String name;
  final String phone;
  final String nic;
  final String address;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.nic,
    required this.address,
    required this.notes,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, nic: $nic)';
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
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        nic.hashCode ^
        address.hashCode ^
        notes.hashCode;
  }
}

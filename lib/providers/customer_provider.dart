import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer.dart';
import '../services/firestore_service.dart';

class CustomerProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize customers stream
  void initializeCustomers() {
    _setLoading(true);

    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated. Please log in again.');
      _setLoading(false);
      return;
    }

    print('Loading customers for user: ${user.email}');
    _firestoreService.getCustomers().listen(
      (customers) {
        _customers = customers;
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        print('Customer loading error: $error');
        _setError('Failed to load customers: $error');
        _setLoading(false);
      },
    );
  }

  // Add new customer
  Future<bool> addCustomer(Customer customer) async {
    try {
      _setLoading(true);
      final id = await _firestoreService.addCustomer(customer);
      _setError(null);
      return true;
    } catch (e) {
      _setError('Failed to add customer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update customer
  Future<bool> updateCustomer(Customer customer) async {
    try {
      _setLoading(true);
      await _firestoreService.updateCustomer(customer);
      _setError(null);
      return true;
    } catch (e) {
      _setError('Failed to update customer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(String customerId) async {
    try {
      _setLoading(true);
      await _firestoreService.deleteCustomer(customerId);
      _setError(null);
      return true;
    } catch (e) {
      _setError('Failed to delete customer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get customer by ID
  Customer? getCustomerById(String customerId) {
    try {
      return _customers.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }

  // Search customers
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;

    final lowercaseQuery = query.toLowerCase();
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(lowercaseQuery) ||
          customer.phone.toLowerCase().contains(lowercaseQuery) ||
          customer.nic.toLowerCase().contains(lowercaseQuery) ||
          customer.address.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Private helper methods
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

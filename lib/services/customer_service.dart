import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/auth_service.dart';

class CustomerService {
  static const _baseUrl = 'https://ezyerp.ezyplus.in/customers.php';

  // Mock data - in real app, this would come from API
  static List<Customer> _mockCustomers = [
    Customer(
      id: '1',
      name: 'ABC Corporation',
      areaName: 'Andheri',
      balanceAmount: 25000.0,
      mobileNumbers: ['9876543210', '9876543211'],
      whatsappNumber: '9876543210',
      address: 'Andheri East, Mumbai',
      locationSet: true,
      latitude: 19.1136,
      longitude: 72.8697,
    ),
    Customer(
      id: '2',
      name: 'XYZ Enterprises',
      areaName: 'Bandra',
      balanceAmount: -5000.0,
      mobileNumbers: ['9876543212'],
      whatsappNumber: '9876543212',
      address: 'Bandra West, Mumbai',
      locationSet: false,
    ),
    Customer(
      id: '3',
      name: 'PQR Industries',
      areaName: 'Andheri',
      balanceAmount: 15000.0,
      mobileNumbers: ['9876543213', '9876543214', '9876543215'],
      whatsappNumber: '9876543213',
      address: 'Andheri West, Mumbai',
      locationSet: true,
      latitude: 19.1197,
      longitude: 72.8464,
    ),
    Customer(
      id: '4',
      name: 'LMN Trading',
      areaName: 'Borivali',
      balanceAmount: 8500.0,
      mobileNumbers: ['9876543216'],
      address: 'Borivali East, Mumbai',
      locationSet: false,
    ),
    Customer(
      id: '5',
      name: 'RST Solutions',
      areaName: 'Bandra',
      balanceAmount: 32000.0,
      mobileNumbers: ['9876543217', '9876543218'],
      whatsappNumber: '9876543217',
      address: 'Bandra East, Mumbai',
      locationSet: true,
      latitude: 19.0596,
      longitude: 72.8295,
    ),
  ];

  static List<Transaction> _mockTransactions = [
    Transaction(
      id: '1',
      customerId: '1',
      invoiceNo: 'INV-001',
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: TransactionType.sales,
      creditAmount: 25000.0,
      receiptAmount: 0.0,
      balanceAmount: 25000.0,
      remarks: 'Product sale',
    ),
    Transaction(
      id: '2',
      customerId: '1',
      invoiceNo: 'RCP-001',
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: TransactionType.receipt,
      creditAmount: 0.0,
      receiptAmount: 10000.0,
      balanceAmount: 15000.0,
      remarks: 'Partial payment',
    ),
    Transaction(
      id: '3',
      customerId: '2',
      invoiceNo: 'INV-002',
      date: DateTime.now().subtract(const Duration(days: 10)),
      type: TransactionType.sales,
      creditAmount: 15000.0,
      receiptAmount: 0.0,
      balanceAmount: 15000.0,
    ),
    Transaction(
      id: '4',
      customerId: '2',
      invoiceNo: 'RCP-002',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: TransactionType.receipt,
      creditAmount: 0.0,
      receiptAmount: 20000.0,
      balanceAmount: -5000.0,
      remarks: 'Advance payment',
    ),
  ];

  static List<CollectionEntry> _mockCollections = [
    CollectionEntry(
      id: '1',
      customerId: '1',
      date: DateTime.now().subtract(const Duration(days: 3)),
      amount: 10000.0,
      type: CollectionType.cash,
      paymentType: PaymentType.cash,
      remarks: 'Partial payment from ABC Corp',
    ),
    CollectionEntry(
      id: '2',
      customerId: '2',
      date: DateTime.now().subtract(const Duration(days: 2)),
      amount: 20000.0,
      type: CollectionType.bank,
      paymentType: PaymentType.cheque,
      chequeNo: 'CHQ123456',
      chequeDate: DateTime.now().subtract(const Duration(days: 2)),
      remarks: 'Advance payment from XYZ Enterprises',
    ),
    CollectionEntry(
      id: '3',
      customerId: '3',
      date: DateTime.now().subtract(const Duration(days: 1)),
      amount: 5000.0,
      type: CollectionType.cash,
      paymentType: PaymentType.cash,
      remarks: 'Cash collection from PQR Industries',
    ),
  ];

  static List<Stock> _mockStocks = [
    Stock(
      id: '1',
      productName: 'Product A',
      category: 'Electronics',
      brand: 'Brand X',
      mrp: 1500.0,
      stockCount: 50,
    ),
    Stock(
      id: '2',
      productName: 'Product B',
      category: 'Electronics',
      brand: 'Brand Y',
      mrp: 2500.0,
      stockCount: 25,
    ),
    Stock(
      id: '3',
      productName: 'Product C',
      category: 'Accessories',
      brand: 'Brand X',
      mrp: 500.0,
      stockCount: 100,
    ),
    Stock(
      id: '4',
      productName: 'Product D',
      category: 'Accessories',
      brand: 'Brand Z',
      mrp: 750.0,
      stockCount: 75,
    ),
  ];

  static Future<List<Customer>> getCustomers() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get authentication headers
      final authHeaders = await AuthService.authHeaders();

      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
        ...authHeaders,
      };

      final body = {
        'officeid': '1',
        'officecode': 'WF01',
        'financialyearid': '2',
      };

      if (kDebugMode) {
        debugPrint('Fetching customers with params: $body');
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('Customers API response: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);

      if (kDebugMode) {
        debugPrint('Parsed JSON data type: ${jsonData.runtimeType}');
        if (jsonData is List) {
          debugPrint('JSON is a List with ${jsonData.length} items');
          if (jsonData.isNotEmpty) {
            debugPrint('First item keys: ${(jsonData.first as Map<String, dynamic>).keys.toList()}');
          }
        } else if (jsonData is Map) {
          debugPrint('JSON is a Map with keys: ${jsonData.keys.toList()}');
        }
      }

      // Handle different response formats
      List<dynamic> customersList;
      if (jsonData is List) {
        customersList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('customers')) {
        customersList = jsonData['customers'] as List;
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        customersList = jsonData['data'] as List;
      } else {
        throw Exception('Unexpected API response format');
      }

      if (kDebugMode) {
        debugPrint('Processing ${customersList.length} customers');
      }

      final customers = customersList.map((json) => Customer.fromJson(json as Map<String, dynamic>)).toList();

      if (kDebugMode) {
        debugPrint('Successfully parsed ${customers.length} customers');
        if (customers.isNotEmpty) {
          debugPrint('First customer: ${customers.first.name} (ID: ${customers.first.id})');
        }
      }

      return customers;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching customers: $e');
      }
      // Fallback to mock data in case of error during development
      await Future.delayed(const Duration(milliseconds: 500));
      return List.from(_mockCustomers);
    }
  }

  static Future<Customer?> getCustomer(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockCustomers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Transaction>> getCustomerTransactions(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockTransactions.where((t) => t.customerId == customerId).toList();
  }

  static Future<List<CollectionEntry>> getCustomerCollections(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockCollections.where((c) => c.customerId == customerId).toList();
  }

  static Future<List<CollectionEntry>> getCollections() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockCollections);
  }

  static Future<List<Stock>> getStocks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockStocks);
  }

  static Future<bool> addCollectionEntry(CollectionEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _mockCollections.add(entry);
    return true;
  }

  static Future<bool> updateCustomerLocation(String customerId, double latitude, double longitude) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _mockCustomers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _mockCustomers[index] = _mockCustomers[index].copyWith(
        latitude: latitude,
        longitude: longitude,
        locationSet: true,
      );
      return true;
    }
    return false;
  }

  static List<Transaction> getCreditAgeTransactions(String customerId) {
    return _mockTransactions
        .where((t) => t.customerId == customerId &&
                     (t.type == TransactionType.sales || t.type == TransactionType.openingBalance))
        .toList();
  }

  // Customer Statement API
  static Future<List<Transaction>> getCustomerStatement({
    required String customerId,
    required String financialYearId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get authentication headers
      final authHeaders = await AuthService.authHeaders();

      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
        ...authHeaders,
      };

      final body = {
        'financialyearid': financialYearId,
        'sdate': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'edate': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'customerid': customerId,
      };

      if (kDebugMode) {
        debugPrint('Fetching customer statement with params: $body');
      }

      final response = await http.post(
        Uri.parse('https://ezyerp.ezyplus.in/customerstatement.php'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('Customer Statement API response: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load customer statement: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);

      // Handle different response formats
      List<dynamic> transactionsList;
      if (jsonData is List) {
        transactionsList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('transactions')) {
        transactionsList = jsonData['transactions'] as List;
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        transactionsList = jsonData['data'] as List;
      } else {
        throw Exception('Unexpected API response format');
      }

      final transactions = transactionsList.map((json) => Transaction.fromJson(json as Map<String, dynamic>)).toList();

      if (kDebugMode) {
        debugPrint('Successfully parsed ${transactions.length} transactions');
      }

      return transactions;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching customer statement: $e');
      }
      // Fallback to mock data in case of error during development
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockTransactions.where((t) => t.customerId == customerId).toList();
    }
  }

  // Credit Age Report API
  static Future<List<Transaction>> getCreditAgeReport({
    required String customerId,
    required String financialYearId,
    required int numberOfDays,
    required String condition, // e.g., "greater_than", "less_than", "equal_to"
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get authentication headers
      final authHeaders = await AuthService.authHeaders();

      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
        ...authHeaders,
      };

      final body = {
        'financialyearid': financialYearId,
        'noofdays': numberOfDays.toString(),
        'condition': condition,
        'customerid': customerId,
      };

      if (kDebugMode) {
        debugPrint('Fetching credit age report with params: $body');
      }

      final response = await http.post(
        Uri.parse('https://ezyerp.ezyplus.in/creditagingreport.php'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('Credit Age Report API response: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load credit age report: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);

      // Handle different response formats
      List<dynamic> transactionsList;
      if (jsonData is List) {
        transactionsList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('transactions')) {
        transactionsList = jsonData['transactions'] as List;
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        transactionsList = jsonData['data'] as List;
      } else {
        throw Exception('Unexpected API response format');
      }

      final transactions = transactionsList.map((json) => Transaction.fromJson(json as Map<String, dynamic>)).toList();

      if (kDebugMode) {
        debugPrint('Successfully parsed ${transactions.length} credit age transactions');
      }

      return transactions;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching credit age report: $e');
      }
      // Fallback to mock data in case of error during development
      await Future.delayed(const Duration(milliseconds: 500));
      return getCreditAgeTransactions(customerId);
    }
  }
}

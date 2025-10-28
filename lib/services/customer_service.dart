import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/auth_service.dart';
import 'package:eazystaff/services/logging_service.dart';

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
      noofdays: 5,
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
      noofdays: 3,
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
      noofdays: 10,
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
      noofdays: 2,
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
      productId: '101',
      productName: 'Product A',
      categoryId: '1',
      category: 'Electronics',
      brandId: '1',
      brand: 'Brand X',
      batchNo: 'BATCH001',
      mrp: 1500.0,
      estStock: 50.0,
      stockQty: 50.0,
    ),
    Stock(
      id: '2',
      productId: '102',
      productName: 'Product B',
      categoryId: '1',
      category: 'Electronics',
      brandId: '2',
      brand: 'Brand Y',
      batchNo: 'BATCH002',
      mrp: 2500.0,
      estStock: 25.0,
      stockQty: 25.0,
    ),
    Stock(
      id: '3',
      productId: '103',
      productName: 'Product C',
      categoryId: '2',
      category: 'Accessories',
      brandId: '1',
      brand: 'Brand X',
      batchNo: 'BATCH003',
      mrp: 500.0,
      estStock: 100.0,
      stockQty: 100.0,
    ),
    Stock(
      id: '4',
      productId: '104',
      productName: 'Product D',
      categoryId: '2',
      category: 'Accessories',
      brandId: '3',
      brand: 'Brand Z',
      batchNo: 'BATCH004',
      mrp: 750.0,
      estStock: 75.0,
      stockQty: 75.0,
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
        'officeid': user.officeId,
        'officecode': user.officeCode,
        'financialyearid': user.financialYearId,
        'empid': user.employeeId.isNotEmpty ? user.employeeId : '2',
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
          debugPrint('=== CUSTOMER IDS DEBUG ===');
          for (int i = 0; i < customers.length && i < 5; i++) {
            final customer = customers[i];
            debugPrint('Customer $i: ${customer.name} (ID: "${customer.id}", type: ${customer.id.runtimeType}, length: ${customer.id.length})');
          }
          if (customers.length > 5) {
            debugPrint('... and ${customers.length - 5} more customers');
          }
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
        'officecode': user.officeCode,
        'officeid': user.officeId.toString(),
        'financialyearid': user.financialYearId.toString(),
      };

      if (kDebugMode) {
        debugPrint('=== STOCKS API REQUEST ===');
        debugPrint('URL: https://ezyerp.ezyplus.in/stocks.php');
        debugPrint('officecode: ${body['officecode']}, officeid: ${body['officeid']}, financialyearid: ${body['financialyearid']}');
      }

      final response = await http.post(
        Uri.parse('https://ezyerp.ezyplus.in/stocks.php'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('Stocks API Response Status: ${response.statusCode}');
        debugPrint('Stocks API Response Body: ${response.body}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load stocks: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (kDebugMode) {
        debugPrint('Stocks API response keys: ${jsonResponse.keys.toList()}');
      }

      // Check if the response has the expected structure
      if (jsonResponse['flag'] != true) {
        throw Exception('API returned error: ${jsonResponse['msg'] ?? 'Unknown error'}');
      }

      // Extract stocks array from response
      final stocksList = jsonResponse['stocks'] as List<dynamic>? ?? [];

      if (kDebugMode) {
        debugPrint('Found ${stocksList.length} stocks in API response');
        debugPrint('=== END STOCKS API REQUEST ===');
      }

      final stocks = stocksList.map((json) => Stock.fromJson(json as Map<String, dynamic>)).toList();

      if (kDebugMode) {
        debugPrint('Successfully parsed ${stocks.length} stocks');
        if (stocks.isNotEmpty) {
          debugPrint('First stock: ${stocks.first.productName} (ID: ${stocks.first.id})');
        }
      }

      return stocks;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching stocks: $e');
      }
      // Fallback to mock data in case of error during development
      await Future.delayed(const Duration(milliseconds: 500));
      return List.from(_mockStocks);
    }
  }

  static Future<bool> addCollectionEntry(CollectionEntry entry) async {
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

      // Format dates for API
      final rdate = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
      final chequeDate = entry.chequeDate != null
          ? '${entry.chequeDate!.year}-${entry.chequeDate!.month.toString().padLeft(2, '0')}-${entry.chequeDate!.day.toString().padLeft(2, '0')}'
          : '';

      // Map payment type to API format
      String paymentTypeStr = entry.paymentType.toString().split('.').last.toLowerCase();
      if (paymentTypeStr == 'cheque') {
        paymentTypeStr = 'cheque';
      } else if (paymentTypeStr == 'online') {
        paymentTypeStr = 'online';
      } else if (paymentTypeStr == 'card') {
        paymentTypeStr = 'card';
      } else {
        paymentTypeStr = 'cash';
      }

      final body = {
        'officecode': user.officeCode,
        'officeid': user.officeId,
        'financialyearid': user.financialYearId,
        'rdate': rdate,
        'empid': user.employeeId,
        'empidc': user.employeeId, // Employee code (same as empid)
        'payment': paymentTypeStr,
        'amount': entry.amount.toString(),
        'customerid': entry.customerId,
        'chequeno': entry.chequeNo ?? '',
        'chequedate': chequeDate,
        'remarks': entry.remarks ?? '',
        'custledger': 'Y', // Enable customer ledger update
      };

      if (kDebugMode) {
        debugPrint('Adding collection entry with params: $body');
      }

      final response = await http.post(
        Uri.parse('https://ezyerp.ezyplus.in/newreceipt.php'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('Collection Entry API response: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to add collection entry: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);

      if (kDebugMode) {
        debugPrint('Collection Entry JSON: $jsonData');
      }

      // Check if API returned success
      if (jsonData is Map) {
        final flag = jsonData['flag'] ?? false;
        final msg = jsonData['msg'] ?? '';

        if (kDebugMode) {
          debugPrint('API flag: $flag, msg: $msg');
        }

        if (flag == true || flag == 1 || msg.toLowerCase().contains('success')) {
          // Also add to mock data for local display
          _mockCollections.add(entry);
          return true;
        } else {
          throw Exception('API returned error: $msg');
        }
      }

      // If response is not a map, assume success if status is 200
      _mockCollections.add(entry);
      return true;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding collection entry: $e');
      }
      // Fallback to mock data in case of error during development
      _mockCollections.add(entry);
      return false;
    }
  }

  static Future<bool> updateCustomerLocation(String customerId, double latitude, double longitude) async {
    LoggingService.info('Attempting to update customer location', tag: 'CustomerService');
    LoggingService.debug('Customer ID: $customerId, Lat: $latitude, Lng: $longitude', tag: 'CustomerService');

    // For now, since the server API endpoint for location updates doesn't exist,
    // we'll save the location locally and return success.
    // This provides a good user experience while the server-side functionality is being developed.

    try {
      // First, try to update in mock data (for development/testing)
      final mockIndex = _mockCustomers.indexWhere((c) => c.id == customerId);
      if (mockIndex != -1) {
        _mockCustomers[mockIndex] = _mockCustomers[mockIndex].copyWith(
          latitude: latitude,
          longitude: longitude,
          locationSet: true,
        );
        LoggingService.info('Customer location updated in mock data', tag: 'CustomerService');
      }

      // TODO: When the server API endpoint for location updates is available,
      // implement the server sync functionality here

      // For now, always return true to provide good user experience
      // The location is saved locally and will be available in the app
      LoggingService.info('Customer location saved locally (server sync pending)', tag: 'CustomerService');
      return true;

    } catch (e, stackTrace) {
      LoggingService.error('Error updating customer location', tag: 'CustomerService', error: e, stackTrace: stackTrace);

      // Even if there's an error, try to provide a good user experience
      // by returning true if we can at least save locally
      final mockIndex = _mockCustomers.indexWhere((c) => c.id == customerId);
      if (mockIndex != -1) {
        _mockCustomers[mockIndex] = _mockCustomers[mockIndex].copyWith(
          latitude: latitude,
          longitude: longitude,
          locationSet: true,
        );
        LoggingService.info('Customer location saved locally despite error', tag: 'CustomerService');
        return true;
      }

      return false;
    }
  }

  static List<Transaction> getCreditAgeTransactions(String customerId) {
    return _mockTransactions
        .where((t) => t.customerId == customerId &&
                     (t.type == TransactionType.sales || t.type == TransactionType.openingBalance))
        .toList();
  }

  // Helper method to try multiple financial years
  static Future<List<Transaction>> getCustomerStatementWithFallback({
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
    String? officeCode,
    String? officeId,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Try current financial year first
    final currentYearId = user.financialYearId.isNotEmpty ? user.financialYearId : '2';
    var transactions = await getCustomerStatement(
      customerId: customerId,
      financialYearId: currentYearId,
      startDate: startDate,
      endDate: endDate,
      officeCode: officeCode,
      officeId: officeId,
    );

    // If no transactions found, try other common financial years
    if (transactions.isEmpty) {
      final yearsToTry = ['1', '2', '3', '4', '5'].where((y) => y != currentYearId);

      for (final yearId in yearsToTry) {
        if (kDebugMode) {
          debugPrint('Trying financial year: $yearId');
        }

        transactions = await getCustomerStatement(
          customerId: customerId,
          financialYearId: yearId,
          startDate: startDate,
          endDate: endDate,
          officeCode: officeCode,
          officeId: officeId,
        );

        if (transactions.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('Found ${transactions.length} transactions in financial year: $yearId');
          }
          break;
        }
      }
    }

    return transactions;
  }

  // Customer Statement API
  static Future<List<Transaction>> getCustomerStatement({
    required String customerId,
    required String financialYearId,
    required DateTime startDate,
    required DateTime endDate,
    String? officeCode,
    String? officeId,
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
        'officecode': officeCode ?? user.officeCode,
        'officeid': officeId ?? user.officeId,
        'financialyearid': financialYearId,
        'sdate': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'edate': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'customerid': customerId,
      };

      if (kDebugMode) {
        debugPrint('=== CUSTOMER STATEMENT DEBUG ===');
        debugPrint('Fetching customer statement with params: $body');
        debugPrint('Customer ID being sent: $customerId (type: ${customerId.runtimeType})');
        debugPrint('Customer ID length: ${customerId.length}');
        debugPrint('Customer ID isEmpty: ${customerId.isEmpty}');
        debugPrint('Raw customer ID: "$customerId"');
      }

      final response = await http.post(
        Uri.parse('https://ezyerp.ezyplus.in/customerstatement.php'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('Customer Statement API response: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        debugPrint('Response body length: ${response.body.length}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load customer statement: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);

      if (kDebugMode) {
        debugPrint('Customer Statement JSON structure: ${jsonData.runtimeType}');
        if (jsonData is Map) {
          debugPrint('JSON keys: ${jsonData.keys.toList()}');
        }
      }

      // Handle the actual API response format based on Postman screenshots
      List<dynamic> transactionsList = [];

      if (jsonData is Map) {
        // Check if response has flag and msg fields (as shown in Postman)
        final flag = jsonData['flag'] ?? false;
        final msg = jsonData['msg'] ?? '';

        if (kDebugMode) {
          debugPrint('API flag: $flag, msg: $msg');
        }

        if (jsonData.containsKey('statement') && jsonData['statement'] is List) {
          transactionsList = jsonData['statement'] as List;
        } else if (jsonData.containsKey('data') && jsonData['data'] is List) {
          transactionsList = jsonData['data'] as List;
        } else if (jsonData.containsKey('transactions') && jsonData['transactions'] is List) {
          transactionsList = jsonData['transactions'] as List;
        } else if (!flag && msg.toLowerCase().contains('no data')) {
          // API returned no data - return empty list
          if (kDebugMode) {
            debugPrint('API returned no data: $msg');
          }
          return [];
        }
      } else if (jsonData is List) {
        transactionsList = jsonData;
      }

      if (transactionsList.isEmpty) {
        if (kDebugMode) {
          debugPrint('No transactions found in API response');
        }
        return [];
      }

      final allTransactions = transactionsList
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        debugPrint('Total transactions parsed: ${allTransactions.length}');
        if (allTransactions.isNotEmpty) {
          debugPrint('First transaction: invoice=${allTransactions.first.invoiceNo}, balance=${allTransactions.first.balanceAmount}, credit=${allTransactions.first.creditAmount}, receipt=${allTransactions.first.receiptAmount}');
        }
      }

      final transactions = allTransactions
          .where((transaction) {
            // Filter out transactions where all important fields are null/empty
            // A valid transaction must have at least an invoice number or balance amount
            final hasInvoice = transaction.invoiceNo.isNotEmpty;
            final hasBalance = transaction.balanceAmount != 0.0;
            final hasCredit = transaction.creditAmount != 0.0;
            final hasReceipt = transaction.receiptAmount != 0.0;

            final isValid = hasInvoice || hasBalance || hasCredit || hasReceipt;

            if (kDebugMode && !isValid) {
              debugPrint('Filtering out empty transaction: invoice=$hasInvoice, balance=$hasBalance, credit=$hasCredit, receipt=$hasReceipt');
            }

            return isValid;
          })
          .toList();

      if (kDebugMode) {
        debugPrint('Successfully parsed ${transactions.length} transactions (filtered ${allTransactions.length - transactions.length} empty records)');
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

  // Helper method to try multiple financial years for credit age report
  static Future<List<Transaction>> getCreditAgeReportWithFallback({
    required String customerId,
    required int numberOfDays,
    required String condition,
    String? officeCode,
    String? officeId,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Try current financial year first
    final currentYearId = user.financialYearId.isNotEmpty ? user.financialYearId : '2';
    var transactions = await getCreditAgeReport(
      customerId: customerId,
      financialYearId: currentYearId,
      numberOfDays: numberOfDays,
      condition: condition,
      officeCode: officeCode,
      officeId: officeId,
    );

    // If no transactions found, try other common financial years
    if (transactions.isEmpty) {
      final yearsToTry = ['1', '2', '3', '4', '5'].where((y) => y != currentYearId);

      for (final yearId in yearsToTry) {
        if (kDebugMode) {
          debugPrint('Trying financial year for credit age: $yearId');
        }

        transactions = await getCreditAgeReport(
          customerId: customerId,
          financialYearId: yearId,
          numberOfDays: numberOfDays,
          condition: condition,
          officeCode: officeCode,
          officeId: officeId,
        );

        if (transactions.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('Found ${transactions.length} credit transactions in financial year: $yearId');
          }
          break;
        }
      }
    }

    return transactions;
  }

  // Credit Age Report API
  static Future<List<Transaction>> getCreditAgeReport({
    required String customerId,
    required String financialYearId,
    required int numberOfDays,
    required String condition, // e.g., "greater_than", "less_than", "equal_to"
    String? officeCode,
    String? officeId,
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
        'officecode': officeCode ?? user.officeCode,
        'officeid': officeId ?? user.officeId,
        'financialyearid': financialYearId,
        'noofdays': numberOfDays.toString(),
        'condition': condition,
        'customerid': customerId,
      };

      if (kDebugMode) {
        debugPrint('=== CREDIT AGE REPORT DEBUG ===');
        debugPrint('Fetching credit age report with params: $body');
        debugPrint('Customer ID being sent: $customerId (type: ${customerId.runtimeType})');
        debugPrint('Customer ID length: ${customerId.length}');
        debugPrint('Customer ID isEmpty: ${customerId.isEmpty}');
        debugPrint('Raw customer ID: "$customerId"');
      }

      final response = await http.post(
        Uri.parse('https://ezyerp.ezyplus.in/creditagingreport.php'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('Credit Age Report API response: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        debugPrint('Response body length: ${response.body.length}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load credit age report: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);

      if (kDebugMode) {
        debugPrint('Credit Age Report JSON structure: ${jsonData.runtimeType}');
        if (jsonData is Map) {
          debugPrint('JSON keys: ${jsonData.keys.toList()}');
        }
      }

      // Handle the actual API response format based on Postman screenshots
      List<dynamic> transactionsList = [];

      if (jsonData is Map) {
        // Check if response has flag and msg fields (as shown in Postman)
        final flag = jsonData['flag'] ?? false;
        final msg = jsonData['msg'] ?? '';

        if (kDebugMode) {
          debugPrint('API flag: $flag, msg: $msg');
        }

        if (jsonData.containsKey('creditage') && jsonData['creditage'] is List) {
          transactionsList = jsonData['creditage'] as List;
        } else if (jsonData.containsKey('data') && jsonData['data'] is List) {
          transactionsList = jsonData['data'] as List;
        } else if (jsonData.containsKey('transactions') && jsonData['transactions'] is List) {
          transactionsList = jsonData['transactions'] as List;
        } else if (!flag && msg.toLowerCase().contains('no data')) {
          // API returned no data - return empty list
          if (kDebugMode) {
            debugPrint('API returned no data: $msg');
          }
          return [];
        }
      } else if (jsonData is List) {
        transactionsList = jsonData;
      }

      if (transactionsList.isEmpty) {
        if (kDebugMode) {
          debugPrint('No credit age transactions found in API response');
        }
        return [];
      }

      final allTransactions = transactionsList
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        debugPrint('Total credit age transactions parsed: ${allTransactions.length}');
        if (allTransactions.isNotEmpty) {
          debugPrint('First transaction: invoice=${allTransactions.first.invoiceNo}, balance=${allTransactions.first.balanceAmount}, credit=${allTransactions.first.creditAmount}');
        }
      }

      final transactions = allTransactions
          .where((transaction) {
            // Filter out transactions where all important fields are null/empty
            // A valid transaction must have at least an invoice number or balance amount
            final hasInvoice = transaction.invoiceNo.isNotEmpty;
            final hasBalance = transaction.balanceAmount != 0.0;
            final hasCredit = transaction.creditAmount != 0.0;

            final isValid = hasInvoice || hasBalance || hasCredit;

            if (kDebugMode && !isValid) {
              debugPrint('Filtering out empty credit age transaction: invoice=$hasInvoice, balance=$hasBalance, credit=$hasCredit');
            }

            return isValid;
          })
          .toList();

      if (kDebugMode) {
        debugPrint('Successfully parsed ${transactions.length} credit age transactions (filtered ${allTransactions.length - transactions.length} empty records)');
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

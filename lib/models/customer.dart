class Customer {
  final String id;
  final String name;
  final String areaName;
  final double balanceAmount;
  final List<String> mobileNumbers;
  final String? whatsappNumber;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool locationSet;

  Customer({
    required this.id,
    required this.name,
    required this.areaName,
    required this.balanceAmount,
    required this.mobileNumbers,
    this.whatsappNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.locationSet = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get string values from different possible keys
    String _getString(List<String> keys, [String defaultValue = '']) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          final value = json[key].toString();
          // Debug logging for customer ID extraction
          if (keys.contains('id') || keys.contains('customer_id') || keys.contains('custid')) {
            print('DEBUG: Found customer ID field "$key" with value "$value"');
          }
          return value;
        }
      }
      // Debug logging when no field is found
      if (keys.contains('id') || keys.contains('customer_id') || keys.contains('custid')) {
        print('DEBUG: No customer ID found in fields: $keys');
        print('DEBUG: Available JSON keys: ${json.keys.toList()}');
      }
      return defaultValue;
    }

    // Helper function to safely get double values
    double _getDouble(List<String> keys, [double defaultValue = 0.0]) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return double.tryParse(json[key].toString()) ?? defaultValue;
        }
      }
      return defaultValue;
    }

    // Helper function to split phone numbers that might be concatenated
    List<String> _splitPhoneNumbers(String phoneString) {
      if (phoneString.isEmpty) return [];

      // Remove all non-digit characters except spaces, commas, and hyphens
      final cleaned = phoneString.replaceAll(RegExp(r'[^\d\s,\-]'), '');

      // Split by common delimiters (space, comma, hyphen)
      final parts = cleaned.split(RegExp(r'[\s,\-]+'));

      // Filter out empty strings and numbers that are too short (less than 7 digits)
      return parts
          .where((part) => part.isNotEmpty && part.length >= 7)
          .toList();
    }

    // Helper function to get mobile numbers from various possible formats
    List<String> _getMobileNumbers() {
      final Set<String> numbers = {}; // Use Set to avoid duplicates

      // Check for array format
      if (json['mobileNumbers'] is List) {
        for (final num in json['mobileNumbers']) {
          final splits = _splitPhoneNumbers(num.toString());
          numbers.addAll(splits);
        }
      } else if (json['mobile_numbers'] is List) {
        for (final num in json['mobile_numbers']) {
          final splits = _splitPhoneNumbers(num.toString());
          numbers.addAll(splits);
        }
      } else if (json['phones'] is List) {
        for (final num in json['phones']) {
          final splits = _splitPhoneNumbers(num.toString());
          numbers.addAll(splits);
        }
      }

      // Check for single mobile number fields
      final singleMobile = _getString(['mobile', 'phone', 'mobileNumber', 'mobile_number', 'contact', 'mobileno']);
      if (singleMobile.isNotEmpty) {
        final splits = _splitPhoneNumbers(singleMobile);
        numbers.addAll(splits);
      }

      // Check for additional mobile fields (mobile1, mobile2, etc.)
      for (int i = 1; i <= 3; i++) {
        final mobile = _getString(['mobile$i', 'phone$i', 'contact$i', 'mobileno$i']);
        if (mobile.isNotEmpty) {
          final splits = _splitPhoneNumbers(mobile);
          numbers.addAll(splits);
        }
      }

      return numbers.toList();
    }

    return Customer(
      id: _getString(['id', 'customer_id', 'custid', 'customerId', 'customeraccountid']),
      name: _getString(['name', 'customer_name', 'custname', 'customerName', 'party_name']),
      areaName: _getString(['areaName', 'area_name', 'area', 'location', 'region', 'areas']),
      balanceAmount: _getDouble(['balanceAmount', 'balance_amount', 'balance', 'outstanding', 'due_amount', 'curbbalance', 'currbalance']),
      mobileNumbers: _getMobileNumbers(),
      whatsappNumber: _getString(['whatsappNumber', 'whatsapp_number', 'whatsapp', 'wa_number', 'whatsappno']),
      address: _getString(['address', 'full_address', 'location_address']),
      latitude: _getDouble(['latitude', 'lat']),
      longitude: _getDouble(['longitude', 'lng', 'lon']),
      locationSet: json['locationSet'] ?? json['location_set'] ?? (json['latitude'] != null && json['longitude'] != null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'areaName': areaName,
      'balanceAmount': balanceAmount,
      'mobileNumbers': mobileNumbers,
      'whatsappNumber': whatsappNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'locationSet': locationSet,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? areaName,
    double? balanceAmount,
    List<String>? mobileNumbers,
    String? whatsappNumber,
    String? address,
    double? latitude,
    double? longitude,
    bool? locationSet,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      areaName: areaName ?? this.areaName,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      mobileNumbers: mobileNumbers ?? this.mobileNumbers,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationSet: locationSet ?? this.locationSet,
    );
  }
}

class Transaction {
  final String id;
  final String customerId;
  final String invoiceNo;
  final DateTime date;
  final TransactionType type;
  final double creditAmount;
  final double receiptAmount;
  final double balanceAmount;
  final int noofdays; // Days outstanding from API
  final String? remarks;

  Transaction({
    required this.id,
    required this.customerId,
    required this.invoiceNo,
    required this.date,
    required this.type,
    required this.creditAmount,
    required this.receiptAmount,
    required this.balanceAmount,
    this.noofdays = 0,
    this.remarks,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get string values from different possible keys
    String getString(List<String> keys, [String defaultValue = '']) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key].toString();
        }
      }
      return defaultValue;
    }

    // Helper function to safely get double values
    double getDouble(List<String> keys, [double defaultValue = 0.0]) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return double.tryParse(json[key].toString()) ?? defaultValue;
        }
      }
      return defaultValue;
    }

    // Helper function to parse date from various formats
    DateTime parseDate(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          try {
            final dateStr = json[key].toString();
            // Try different date formats
            if (dateStr.contains('-')) {
              return DateTime.parse(dateStr);
            } else if (dateStr.contains('/')) {
              // Handle DD/MM/YYYY format
              final parts = dateStr.split('/');
              if (parts.length == 3) {
                return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
              }
            }
          } catch (e) {
            // Continue to next key if parsing fails
            continue;
          }
        }
      }
      return DateTime.now(); // Fallback to current date
    }

    // Helper function to safely get int values
    int getInt(List<String> keys, [int defaultValue = 0]) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return int.tryParse(json[key].toString()) ?? defaultValue;
        }
      }
      return defaultValue;
    }

    // Determine transaction type from alltype/alltypes field
    String typeStr = getString(['type', 'txn_type', 'transaction_type', 'alltype', 'alltypes']).toLowerCase();
    TransactionType txnType = TransactionType.sales;

    if (typeStr.contains('receipt')) {
      txnType = TransactionType.receipt;
    } else if (typeStr.contains('return')) {
      txnType = TransactionType.return_;
    } else if (typeStr.contains('journal')) {
      txnType = TransactionType.journal;
    } else if (typeStr.contains('opening') || typeStr.contains('old balance')) {
      txnType = TransactionType.openingBalance;
    } else if (typeStr.contains('sales') || typeStr.contains('sale')) {
      txnType = TransactionType.sales;
    }

    return Transaction(
      id: getString(['id', 'transaction_id', 'txn_id', 'invoiceid', 'expincId']),
      customerId: getString(['customerId', 'customer_id', 'custid', 'customeraccountid']),
      invoiceNo: getString(['invoiceNo', 'invoice_no', 'invoiceno', 'invoice', 'billno', 'pinvoice']),
      date: parseDate(['date', 'invoice_date', 'txn_date', 'pur_date', 'bill_date']),
      type: txnType,
      // For credit amount: use incout1/incout for sales, or totalamt/nettotal for credit age report
      creditAmount: getDouble(['creditAmount', 'credit_amount', 'credit', 'debit', 'amount', 'totalamt', 'nettotal', 'incout1', 'incout']),
      // For receipt amount: use incin1/incin for receipts
      receiptAmount: getDouble(['receiptAmount', 'receipt_amount', 'receipt', 'payment', 'incin1', 'incin']),
      // For balance: use ob (opening balance) from statement, or balamt from credit age report
      balanceAmount: getDouble(['balanceAmount', 'balance_amount', 'balance', 'outstanding', 'currbalance', 'balamt', 'ob']),
      noofdays: getInt(['noofdays', 'no_of_days', 'days_outstanding', 'daysold']),
      remarks: getString(['remarks', 'remark', 'description', 'narration', 'msg']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'invoiceNo': invoiceNo,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'creditAmount': creditAmount,
      'receiptAmount': receiptAmount,
      'balanceAmount': balanceAmount,
      'noofdays': noofdays,
      'remarks': remarks,
    };
  }
}

enum TransactionType {
  sales,
  return_,
  receipt,
  journal,
  openingBalance,
}

class CollectionEntry {
  final String id;
  final String customerId;
  final DateTime date;
  final double amount;
  final CollectionType type;
  final PaymentType paymentType;
  final String? chequeNo;
  final DateTime? chequeDate;
  final String? remarks;

  CollectionEntry({
    required this.id,
    required this.customerId,
    required this.date,
    required this.amount,
    required this.type,
    required this.paymentType,
    this.chequeNo,
    this.chequeDate,
    this.remarks,
  });

  factory CollectionEntry.fromJson(Map<String, dynamic> json) {
    return CollectionEntry(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      date: DateTime.parse(json['date']),
      amount: (json['amount'] ?? 0).toDouble(),
      type: CollectionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => CollectionType.cash,
      ),
      paymentType: PaymentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentType'],
        orElse: () => PaymentType.cash,
      ),
      chequeNo: json['chequeNo'],
      chequeDate: json['chequeDate'] != null ? DateTime.parse(json['chequeDate']) : null,
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'date': date.toIso8601String(),
      'amount': amount,
      'type': type.toString().split('.').last,
      'paymentType': paymentType.toString().split('.').last,
      'chequeNo': chequeNo,
      'chequeDate': chequeDate?.toIso8601String(),
      'remarks': remarks,
    };
  }
}

enum CollectionType {
  cash,
  bank,
}

enum PaymentType {
  cash,
  cheque,
  online,
  card,
}

class Stock {
  final String id;
  final String productId;
  final String productName;
  final String categoryId;
  final String category;
  final String brandId;
  final String brand;
  final String batchNo;
  final double mrp;
  final double estStock;
  final double stockQty;

  Stock({
    required this.id,
    required this.productId,
    required this.productName,
    required this.categoryId,
    required this.category,
    required this.brandId,
    required this.brand,
    required this.batchNo,
    required this.mrp,
    required this.estStock,
    required this.stockQty,
  });

  // Helper getter for backward compatibility
  int get stockCount => stockQty.toInt();

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['stockid']?.toString() ?? '',
      productId: json['productid']?.toString() ?? '',
      productName: json['productname']?.toString() ?? '',
      categoryId: json['categoryid']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      brandId: json['brandid']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      batchNo: json['batchno']?.toString() ?? '',
      mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0.0,
      estStock: double.tryParse(json['est_stock']?.toString() ?? '0') ?? 0.0,
      stockQty: double.tryParse(json['stockqty']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockid': id,
      'productid': productId,
      'productname': productName,
      'categoryid': categoryId,
      'category': category,
      'brandid': brandId,
      'brand': brand,
      'batchno': batchNo,
      'mrp': mrp.toString(),
      'est_stock': estStock.toString(),
      'stockqty': stockQty.toString(),
    };
  }
}

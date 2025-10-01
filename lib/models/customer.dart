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
          return json[key].toString();
        }
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

    // Helper function to get mobile numbers from various possible formats
    List<String> _getMobileNumbers() {
      final List<String> numbers = [];

      // Check for array format
      if (json['mobileNumbers'] is List) {
        numbers.addAll(List<String>.from(json['mobileNumbers']));
      } else if (json['mobile_numbers'] is List) {
        numbers.addAll(List<String>.from(json['mobile_numbers']));
      } else if (json['phones'] is List) {
        numbers.addAll(List<String>.from(json['phones']));
      }

      // Check for single mobile number fields
      final singleMobile = _getString(['mobile', 'phone', 'mobileNumber', 'mobile_number', 'contact', 'mobileno']);
      if (singleMobile.isNotEmpty && !numbers.contains(singleMobile)) {
        numbers.add(singleMobile);
      }

      // Check for additional mobile fields (mobile1, mobile2, etc.)
      for (int i = 1; i <= 3; i++) {
        final mobile = _getString(['mobile$i', 'phone$i', 'contact$i']);
        if (mobile.isNotEmpty && !numbers.contains(mobile)) {
          numbers.add(mobile);
        }
      }

      return numbers;
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
    this.remarks,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      invoiceNo: json['invoiceNo'] ?? '',
      date: DateTime.parse(json['date']),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.sales,
      ),
      creditAmount: (json['creditAmount'] ?? 0).toDouble(),
      receiptAmount: (json['receiptAmount'] ?? 0).toDouble(),
      balanceAmount: (json['balanceAmount'] ?? 0).toDouble(),
      remarks: json['remarks'],
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
  final String productName;
  final String category;
  final String brand;
  final double mrp;
  final int stockCount;

  Stock({
    required this.id,
    required this.productName,
    required this.category,
    required this.brand,
    required this.mrp,
    required this.stockCount,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'] ?? '',
      productName: json['productName'] ?? '',
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      mrp: (json['mrp'] ?? 0).toDouble(),
      stockCount: json['stockCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'category': category,
      'brand': brand,
      'mrp': mrp,
      'stockCount': stockCount,
    };
  }
}

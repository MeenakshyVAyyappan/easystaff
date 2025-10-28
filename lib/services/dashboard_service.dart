import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:eazystaff/services/logging_service.dart';

class DashboardData {
  final String displayName;           // user card
  final String designation;
  final String department;
  final String officeCode;
  final String savedLocation;         // from local storage (not server)
  final double monthCollections;      // summary
  final int monthCustomers;
  final int monthVisits;
  final double pendingAmount;         // pending amount from API
  final int salesOrderCount;          // sales order count from API
  final double salesOrderAmount;      // sales order amount from API
  final List<TodayTxn> todays;        // today’s transactions

  DashboardData({
    required this.displayName,
    required this.designation,
    required this.department,
    required this.officeCode,
    required this.savedLocation,
    required this.monthCollections,
    required this.monthCustomers,
    required this.monthVisits,
    required this.pendingAmount,
    required this.salesOrderCount,
    required this.salesOrderAmount,
    required this.todays,
  });

  // defensive factory; map your API keys here once you know them exactly
  factory DashboardData.fromJson(
    Map<String, dynamic> j, {
    String savedLocation = '',
  }) {
    // Handle the API response format: {flag:true, msg:"Success", userdashboard:{...}}
    final dashboard = (j['userdashboard'] is Map) ? j['userdashboard'] as Map : j;

    String _s(List keys, [String fallback = '']) {
      for (final k in keys) {
        if (dashboard[k] != null && dashboard[k].toString().trim().isNotEmpty) {
          return dashboard[k].toString();
        }
      }
      return fallback;
    }

    double _d(List keys) {
      for (final k in keys) {
        final v = dashboard[k];
        if (v == null) continue;
        if (v is num) return v.toDouble();
        final str = v.toString().replaceAll(RegExp(r'[^0-9\.\-]'), '');
        final p = double.tryParse(str);
        if (p != null) return p;
      }
      return 0.0;
    }

    int _i(List keys) {
      for (final k in keys) {
        final v = dashboard[k];
        if (v == null) continue;
        if (v is num) return v.toInt();
        final p = int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9\-]'), ''));
        if (p != null) return p;
      }
      return 0;
    }

    if (kDebugMode) {
      debugPrint('=== DASHBOARD DATA PARSING ===');
      debugPrint('Raw JSON keys: ${j.keys.toList()}');
      debugPrint('Dashboard keys: ${dashboard.keys.toList()}');
      debugPrint('Full dashboard data: $dashboard');

      // Check if API returned an error
      if (j['flag'] == false || j['msg'] == 'Failed') {
        debugPrint('⚠️ API ERROR: flag=${j['flag']}, msg=${j['msg']}');
        debugPrint('This means the API rejected the request.');
        debugPrint('Common causes:');
        debugPrint('  1. Invalid empid (should be numeric, not username)');
        debugPrint('  2. Employee not found in the system');
        debugPrint('  3. Invalid date range');
      }
    }

    // Look for today's transactions in both the merged JSON and dashboard object
    final today   = (j['today']   is List) ? j['today'] as List
                   : (j['todays'] is List) ? j['todays'] as List
                   : (j['transactions'] is List) ? j['transactions'] as List
                   : (dashboard['today']   is List) ? dashboard['today'] as List
                   : (dashboard['todays'] is List) ? dashboard['todays'] as List
                   : (dashboard['transactions'] is List) ? dashboard['transactions'] as List
                   : const [];

    // Based on your API response, the API returns:
    // collectioncnt: "300", collectionamt: "2235307.40", pendingamt: 0, salesordercnt: "0", salesorderamt: "0.00"
    final collections = _d(['collectionamt','month_collections','collections','total_collections']);
    final collectionCount = _i(['collectioncnt','month_collection_count','collection_count']);
    final customers = _i(['salesordercnt','customercnt','month_customers','customers','total_customers','customercount']);
    final visits = _i(['visitcnt','month_visits','visits','total_visits','visitcount']);
    final pendingAmount = _d(['pendingamt','pending_amount','pending']);
    final salesOrderAmount = _d(['salesorderamt','sales_order_amount','salesorder_amt']);

    // Ensure salesOrderCount is never null
    final salesOrderCount = _i(['salesordercnt','sales_order_count','salesorder_count']);

    if (kDebugMode) {
      debugPrint('Parsed dashboard values:');
      debugPrint('  collections=$collections (from collectionamt)');
      debugPrint('  collectionCount=$collectionCount (from collectioncnt)');
      debugPrint('  customers=$customers (from salesordercnt)');
      debugPrint('  visits=$visits (from visitcnt)');
      debugPrint('  pendingAmount=$pendingAmount (from pendingamt)');
      debugPrint('  salesOrderCount=$salesOrderCount (from salesordercnt)');
      debugPrint('  salesOrderAmount=$salesOrderAmount (from salesorderamt)');
      debugPrint('  today transactions count: ${today.length}');
      debugPrint('=== END DASHBOARD DATA PARSING ===');
    }

    return DashboardData(
      displayName  : _s(['employee_name','name','username','user']),
      designation  : _s(['designation','role','title']),
      department   : _s(['department','dept']),
      officeCode   : _s(['office_code','officecode','office']),
      savedLocation: savedLocation,
      monthCollections: collections.toDouble(),
      monthCustomers  : customers,
      monthVisits     : visits,
      pendingAmount   : pendingAmount,
      salesOrderCount : salesOrderCount, // Using sales order count from API
      salesOrderAmount: salesOrderAmount,
      todays: today.map((e) => TodayTxn.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class TodayTxn {
  final String party;
  final int amount;
  final String time; // “09:30 AM”, etc.

  TodayTxn({required this.party, required this.amount, required this.time});

  factory TodayTxn.fromJson(Map<String, dynamic> j) {
    String _s(List keys, [String fallback='']) {
      for (final k in keys) {
        if (j[k] != null && j[k].toString().trim().isNotEmpty) {
          return j[k].toString();
        }
      }
      return fallback;
    }
    int _i(List keys) {
      for (final k in keys) {
        final v = j[k];
        if (v == null) continue;
        if (v is num) return v.toInt();
        final p = int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9\-]'), ''));
        if (p != null) return p;
      }
      return 0;
    }

    return TodayTxn(
      party: _s(['party','customer','name','title'], 'Unknown'),
      amount: _i(['amount','amt','value','price']),
      time: _s(['time','txn_time','created_time']),
    );
  }
}

class DashboardService {
  static const _base = 'https://ezyerp.ezyplus.in/userdashbord.php';

  static String _fmt(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  static Future<Map<String, dynamic>> _postRange({
    required String empId,
    required DateTime sdate,
    required DateTime edate,
    required String officeCode,
    required String officeId,
    required String financialYearId,
  }) async {
    if (kDebugMode) {
      debugPrint('=== DASHBOARD API REQUEST ===');
      debugPrint('URL: $_base');
      debugPrint('empid: $empId (type: ${empId.runtimeType})');
      debugPrint('officecode: $officeCode, officeid: $officeId, financialyearid: $financialYearId');
      debugPrint('sdate: ${_fmt(sdate)}, edate: ${_fmt(edate)}');
    }

    final resp = await http.post(
      Uri.parse(_base),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
      },
      body: {
        'officecode': officeCode,
        'officeid': officeId,
        'financialyearid': financialYearId,
        'empid': empId,
        'sdate': _fmt(sdate),
        'edate': _fmt(edate),
      },
    ).timeout(const Duration(seconds: 25));

    if (kDebugMode) {
      debugPrint('Dashboard API Response Status: ${resp.statusCode}');
      debugPrint('Dashboard API Response Body: ${resp.body}');
    }

    if (resp.statusCode != 200) {
      throw Exception('Dashboard error ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    if (kDebugMode) {
      debugPrint('Dashboard API response keys: ${data.keys.toList()}');
      debugPrint('API flag: ${data['flag']}, msg: ${data['msg']}');
      if (data.containsKey('userdashboard')) {
        debugPrint('Found userdashboard: ${data['userdashboard']}');
      } else {
        debugPrint('⚠️ WARNING: userdashboard is null or missing!');
        debugPrint('This usually means the empid parameter is invalid.');
        debugPrint('Expected: numeric employee ID, Got: $empId');
      }
      debugPrint('=== END DASHBOARD API REQUEST ===');
    }

    return data;
  }

  /// Fetch monthly summary (first..last day of this month)
  static Future<Map<String, dynamic>> fetchMonthlyRaw({
    required String empId,
    required String officeCode,
    required String officeId,
    required String financialYearId,
  }) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final last  = DateTime(now.year, now.month + 1, 0);
    return _postRange(
      empId: empId,
      sdate: first,
      edate: last,
      officeCode: officeCode,
      officeId: officeId,
      financialYearId: financialYearId,
    );
  }

  /// Fetch today’s transactions (today..today)
  static Future<List<dynamic>> fetchTodayRaw({
    required String empId,
    required String officeCode,
    required String officeId,
    required String financialYearId,
  }) async {
    final today = DateTime.now();
    final raw = await _postRange(
      empId: empId,
      sdate: today,
      edate: today,
      officeCode: officeCode,
      officeId: officeId,
      financialYearId: financialYearId,
    );
    // return the list part; adapt to your API’s key
    if (raw['today'] is List) return raw['today'] as List;
    if (raw['todays'] is List) return raw['todays'] as List;
    if (raw['transactions'] is List) return raw['transactions'] as List;
    return const [];
  }

  /// One convenience call that merges both (2 requests, clearer semantics)
  static Future<DashboardData> fetchDashboard({
    required String empId,
    required String officeCode,
    required String officeId,
    required String financialYearId,
    String savedLocation = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final month = await fetchCustomRangeRaw(
      empId: empId,
      officeCode: officeCode,
      officeId: officeId,
      financialYearId: financialYearId,
      startDate: startDate,
      endDate: endDate,
    );
    final today = await fetchTodayRaw(
      empId: empId,
      officeCode: officeCode,
      officeId: officeId,
      financialYearId: financialYearId,
    );

    final merged = <String, dynamic>{...month, 'today': today};
    return DashboardData.fromJson(merged, savedLocation: savedLocation);
  }

  /// Fetch data for custom date range
  static Future<Map<String, dynamic>> fetchCustomRangeRaw({
    required String empId,
    required String officeCode,
    required String officeId,
    required String financialYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Use provided dates or default to current month
    final now = DateTime.now();
    final sdate = startDate ?? DateTime(now.year, now.month, 1);
    final edate = endDate ?? DateTime(now.year, now.month + 1, 0);

    return _postRange(
      empId: empId,
      sdate: sdate,
      edate: edate,
      officeCode: officeCode,
      officeId: officeId,
      financialYearId: financialYearId,
    );
  }
}

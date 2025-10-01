import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class DashboardData {
  final String displayName;           // user card
  final String designation;
  final String department;
  final String officeCode;
  final String savedLocation;         // from local storage (not server)
  final int monthCollections;         // summary
  final int monthCustomers;
  final int monthVisits;
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
    required this.todays,
  });

  // defensive factory; map your API keys here once you know them exactly
  factory DashboardData.fromJson(
    Map<String, dynamic> j, {
    String savedLocation = '',
  }) {
    String _s(List keys, [String fallback = '']) {
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

    // Try a few common shapes: {summary:{...}, user:{...}, today:[...]} or flat.
    final summary = (j['summary'] is Map) ? j['summary'] as Map : j;
    final user    = (j['user']    is Map) ? j['user']    as Map : j;
    final today   = (j['today']   is List) ? j['today'] as List
                   : (j['todays'] is List) ? j['todays'] as List
                   : (j['transactions'] is List) ? j['transactions'] as List
                   : const [];

    return DashboardData(
      displayName  : _s(['employee_name','name','username','user']),
      designation  : _s(['designation','role','title']),
      department   : _s(['department','dept']),
      officeCode   : _s(['office_code','officecode','office']),
      savedLocation: savedLocation,
      monthCollections: _i(['month_collections','collections','total_collections']),
      monthCustomers  : _i(['month_customers','customers','total_customers']),
      monthVisits     : _i(['month_visits','visits','total_visits']),
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

  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static Future<Map<String, dynamic>> _postRange({
    required String empId,
    required DateTime sdate,
    required DateTime edate,
  }) async {
    final resp = await http.post(
      Uri.parse(_base),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
      },
      body: {
        'empid': empId,
        'sdate': _fmt(sdate),
        'edate': _fmt(edate),
      },
    ).timeout(const Duration(seconds: 25));

    if (kDebugMode) {
      debugPrint('Dashboard ${resp.statusCode}: ${resp.body}');
    }

    if (resp.statusCode != 200) {
      throw Exception('Dashboard error ${resp.statusCode}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Fetch monthly summary (first..last day of this month)
  static Future<Map<String, dynamic>> fetchMonthlyRaw(String empId) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final last  = DateTime(now.year, now.month + 1, 0);
    return _postRange(empId: empId, sdate: first, edate: last);
  }

  /// Fetch today’s transactions (today..today)
  static Future<List<dynamic>> fetchTodayRaw(String empId) async {
    final today = DateTime.now();
    final raw = await _postRange(empId: empId, sdate: today, edate: today);
    // return the list part; adapt to your API’s key
    if (raw['today'] is List) return raw['today'] as List;
    if (raw['todays'] is List) return raw['todays'] as List;
    if (raw['transactions'] is List) return raw['transactions'] as List;
    return const [];
  }

  /// One convenience call that merges both (2 requests, clearer semantics)
  static Future<DashboardData> fetchDashboard({
    required String empId,
    String savedLocation = '',
  }) async {
    final month = await fetchMonthlyRaw(empId);
    final today = await fetchTodayRaw(empId);

    final merged = <String, dynamic>{...month, 'today': today};
    return DashboardData.fromJson(merged, savedLocation: savedLocation);
  }
}

// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

// ---- Add: AppUser model ----
class AppUser {
  final String name;
  final String username;
  final String employeeId;
  final String department;
  final String designation;
  final String officeCode;
  final String location;

  AppUser({
    required this.name,
    required this.username,
    required this.employeeId,
    required this.department,
    required this.designation,
    required this.officeCode,
    required this.location,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    // Map defensively: accept multiple possible PHP/JSON keys.
    String _s(List keys, [String fallback = '']) {
      for (final k in keys) {
        if (j[k] != null && j[k].toString().trim().isNotEmpty) {
          return j[k].toString();
        }
      }
      return fallback;
    }

    return AppUser(
      name:        _s(['name', 'full_name', 'employee_name'], 'User'),
      username:    _s(['username', 'user', 'uname'], ''),
      employeeId:  _s(['employee_id', 'emp_id', 'id'], ''),
      department:  _s(['department', 'dept'], ''),
      designation: _s(['designation', 'role', 'title'], ''),
      officeCode:  _s(['office_code', 'office', 'officecode'], ''),
      location:    _s(['location', 'branch', 'city'], ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'username': username,
    'employee_id': employeeId,
    'department': department,
    'designation': designation,
    'office_code': officeCode,
    'location': location,
  };
}

// ---- AuthService ----
class AuthService {
  static const _baseUrl = 'https://ezyerp.ezyplus.in';
  static const _loginPath = '/login.php';

  static const _storage = FlutterSecureStorage();

  // inside AuthService
static Future<void> saveLocation(String prettyAddress) async {
  await _storage.write(key: 'saved_location', value: prettyAddress);
}

static Future<String?> loadLocation() async {
  return await _storage.read(key: 'saved_location');
}


  // ---- Add: in-memory cache + getter ----
  static AppUser? _currentUserCache;
  static AppUser? get currentUser => _currentUserCache;

  // ---- Add: hydrate cached user at app start ----
  static Future<void> hydrate() async {
    final raw = await _storage.read(key: 'user');
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw);
        if (map is Map<String, dynamic>) {
          _currentUserCache = AppUser.fromJson(map);
        }
      } catch (_) {
        // ignore bad cache
      }
    }
  }

  // ---- existing login(...) — add the lines marked [NEW] where shown ----
  static Future<bool> login({
    required String officeCode,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl$_loginPath');

    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json, text/plain, */*',
    };

    final body = {
      'officecode': officeCode,
      'username': username,
      'password': password,
    };

    try {
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        debugPrint('Login status: ${resp.statusCode}');
        debugPrint('Content-Type: ${resp.headers['content-type']}');
        debugPrint('Response: ${resp.body}');
        debugPrint('Set-Cookie: ${resp.headers['set-cookie']}');
      }

      final setCookie = resp.headers['set-cookie'];
      if (setCookie != null) {
        final phpsessid = _extractCookieValue(setCookie, 'PHPSESSID');
        if (phpsessid != null) {
          await _storage.write(key: 'cookie', value: 'PHPSESSID=$phpsessid');
        }
      }

      final contentType = resp.headers['content-type'] ?? '';
      bool success = false;
      String? token;
      Map<String, dynamic>? userMap;

      if (contentType.contains('application/json')) {
        final data = jsonDecode(resp.body);
        success = _isSuccessJson(data);
        token = _extractToken(data);
        userMap = _extractUser(data);
      } else {
        final txt = resp.body.trim().toLowerCase();
        success = txt == 'success' ||
                  txt.contains('login success') ||
                  (resp.statusCode == 200 && setCookie != null);
      }

      if (!success) {
        throw ApiException(_friendlyError(resp));
      }

      if (token != null && token.isNotEmpty) {
        await _storage.write(key: 'token', value: token);
      }

      // ---- [NEW] persist & cache user if present ----
      if (userMap != null) {
        final user = AppUser.fromJson(userMap);
        _currentUserCache = user;
        await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
      } else {
        // If your API doesn't return a user object on login but you still
        // know some fields, you can build it from inputs:
        final fallback = AppUser(
          name: username, // or 'User'
          username: username,
          employeeId: '',
          department: '',
          designation: '',
          officeCode: officeCode,
          location: '',
        );
        _currentUserCache = fallback;
        await _storage.write(key: 'user', value: jsonEncode(fallback.toJson()));
      }

      return true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network or server error. ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    _currentUserCache = null; // <-- clear cache
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'cookie');
    await _storage.delete(key: 'user');
  }

  static Future<Map<String, String>> authHeaders() async {
    final headers = <String, String>{};
    final token = await _storage.read(key: 'token');
    final cookie = await _storage.read(key: 'cookie');
    if (token != null) headers['Authorization'] = 'Bearer $token';
    if (cookie != null) headers['Cookie'] = cookie;
    return headers;
  }

  // --- helpers (unchanged from your file) ---
  static bool _isSuccessJson(dynamic json) { /* ... same as before ... */ 
    if (json is Map<String, dynamic>) {
      final s = json['success'];
      final status = json['status'];
      final code = json['code'];
      if (s == true || s == 1) return true;
      if (status == 'ok' || status == 'success') return true;
      if (code == 200) return true;
      if (json['result'] is Map) {
        final r = json['result'] as Map;
        if (r['success'] == true || r['status'] == 'ok') return true;
      }
    }
    return false;
  }

  static String? _extractToken(Map<String, dynamic> json) { /* ... same ... */ 
    if (json['token'] is String) return json['token'];
    if (json['access_token'] is String) return json['access_token'];
    if (json['data'] is Map && (json['data']['token'] is String)) {
      return json['data']['token'];
    }
    return null;
  }

  static Map<String, dynamic>? _extractUser(Map<String, dynamic> json) { /* ... same ... */ 
    if (json['user'] is Map<String, dynamic>) return json['user'];
    if (json['data'] is Map && (json['data']['user'] is Map<String, dynamic>)) {
      return json['data']['user'];
    }
    return null;
  }

  static String _friendlyError(http.Response resp) { /* ... same ... */ 
    final ct = resp.headers['content-type'] ?? '';
    if (ct.contains('application/json')) {
      try {
        final j = jsonDecode(resp.body);
        return (j['message'] ?? j['error'] ?? j['detail'] ?? 'Invalid credentials. Please try again.').toString();
      } catch (_) {}
    }
    final txt = resp.body.trim();
    if (txt.isNotEmpty && txt.length < 200) return txt;
    if (resp.statusCode == 401) return 'Unauthorized (401). Check credentials.';
    if (resp.statusCode == 403) return 'Forbidden (403).';
    if (resp.statusCode == 404) return 'Endpoint not found (404).';
    if (resp.statusCode >= 500) return 'Server error (${resp.statusCode}).';
    return 'Invalid credentials. Please try again.';
  }

  static String? _extractCookieValue(String setCookie, String name) { /* ... same ... */ 
    final strict = RegExp('(?:^|, )$name=([^;]+)');
    final m1 = strict.firstMatch(setCookie);
    if (m1 != null) return m1.group(1);
    final loose = RegExp('$name=([^;]+)');
    return loose.firstMatch(setCookie)?.group(1);
  }
}

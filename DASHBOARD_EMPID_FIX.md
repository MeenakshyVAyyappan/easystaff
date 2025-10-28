# Dashboard Zero Values Fix - Employee ID Issue

## Problem Summary

The dashboard was showing **0 collections, 0 customers, and 0 visits** even though the Postman test showed the API returns valid data with `collectioncnt: "232"`.

### Root Cause

The API was returning `flag: false, msg: "Failed"` because:

1. **Login API doesn't return `employee_id`** - The login response doesn't include an `employee_id` field
2. **Fallback to username** - The code fell back to using `username` ("admin") as the employee ID
3. **API rejects non-numeric IDs** - The dashboard API only accepts numeric employee IDs, not usernames
4. **Request fails silently** - The API returned `flag: false` and `userdashboard: null`

### Evidence from Logs

**Bad logs (before fix):**
```
empid: admin (type: String), sdate: 2025-10-22, edate: 2025-10-22
Dashboard API Response Body: {"flag":false,"msg":"Failed","userdashboard":null}
API flag: false, msg: Failed
⚠️ WARNING: userdashboard is null or missing!
Expected: numeric employee ID, Got: admin
```

**Good logs (expected after fix):**
```
empid: 2 (type: String), sdate: 2025-10-22, edate: 2025-10-22
Dashboard API Response Body: {"flag":true,"msg":"Success","userdashboard":{...}}
API flag: true, msg: Success
Found userdashboard: {collectioncnt: 232, ...}
```

## Solution Implemented

### 1. Enhanced Employee ID Extraction (auth_service.dart)

Added more field name variations to extract employee ID from login response:

```dart
employeeId: _s(['employee_id', 'emp_id', 'empid', 'id', 'userid', 'user_id', 'eid'], ''),
```

Added debug logging to show what was extracted:
```dart
if (kDebugMode) {
  debugPrint('=== AppUser.fromJson DEBUG ===');
  debugPrint('Raw JSON keys: ${j.keys.toList()}');
  debugPrint('Extracted employeeId: "$empId"');
  debugPrint('Full user data: $j');
}
```

### 2. Improved Fallback Logic (dashboard.dart)

Changed the fallback chain from:
```dart
// OLD: Falls back to username (non-numeric)
final empId = (u.employeeId.isNotEmpty) ? u.employeeId : u.username;
```

To:
```dart
// NEW: Tries multiple numeric fields before falling back to username
String empId = '';
if (u.employeeId.isNotEmpty) {
  empId = u.employeeId;
} else if (u.officeId.isNotEmpty) {
  empId = u.officeId;
} else {
  empId = u.username;
}
```

### 3. Added Login Response Logging (auth_service.dart)

Added logging to show what the login API returns:
```dart
if (userMap != null) {
  debugPrint('=== LOGIN USER EXTRACTION ===');
  debugPrint('User data from API: $userMap');
  // ... extract user ...
  debugPrint('Cached user: name=${user.name}, empId=${user.employeeId}, username=${user.username}');
}
```

## Next Steps to Verify

### 1. Check Login Response in Postman

Test the login endpoint to see what fields it returns:

```
POST https://ezyerp.ezyplus.in/login.php
Content-Type: application/x-www-form-urlencoded

username=admin&password=<password>&officeCode=<code>
```

Look for numeric ID fields like:
- `employee_id`
- `emp_id`
- `empid`
- `id`
- `userid`
- `user_id`
- `eid`

### 2. Check Debug Logs

After running the app, look for:

```
=== LOGIN USER EXTRACTION ===
User data from API: {...}
Cached user: name=..., empId=..., username=...
=== END LOGIN USER EXTRACTION ===
```

And:

```
=== AppUser.fromJson DEBUG ===
Raw JSON keys: [...]
Extracted employeeId: "2"
Full user data: {...}
=== END AppUser.fromJson DEBUG ===
```

### 3. Verify Dashboard API Call

Check that the dashboard API is called with a numeric ID:

```
empid: 2 (type: String), sdate: 2025-10-22, edate: 2025-10-22
Dashboard API Response Status: 200
Dashboard API Response Body: {"flag":true,"msg":"Success","userdashboard":{...}}
```

## Files Modified

1. **lib/services/auth_service.dart**
   - Added `import 'package:flutter/foundation.dart'` for `kDebugMode`
   - Enhanced `AppUser.fromJson()` with more field name variations
   - Added debug logging for employee ID extraction
   - Added logging for login response handling

2. **lib/dashboard.dart**
   - Improved fallback logic in `_loadDashboard()` method
   - Now tries `employeeId` → `officeId` → `username` instead of just `employeeId` → `username`

## Expected Result

After the fix, the dashboard should display:
- **Collections**: 232 ✅ (from API response)
- **Customers**: 0 (from salesordercnt)
- **Visits**: 0 (not provided by API)

Instead of showing all zeros.


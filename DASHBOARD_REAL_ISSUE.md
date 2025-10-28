# Dashboard Issue - Root Cause Analysis

## What We Discovered

The dashboard is showing 0 for Collections, Customers, and Visits because **the API is rejecting the request**, not because of a parsing bug.

## Current Logs Show

```
empid: admin, sdate: 2025-10-22, edate: 2025-10-22
Dashboard API Response Status: 200
Dashboard API Response Body: {"flag":false,"msg":"Failed","userdashboard":null}
```

**Translation:** The API is saying "I don't recognize this employee ID."

## The Problem

### What's Being Sent
```
empid: admin
```

### What the API Expects
```
empid: 2  (or some numeric employee ID)
```

### Why This Happens

In `lib/dashboard.dart` line 40:
```dart
final empId = (u.employeeId.isNotEmpty) ? u.employeeId : u.username;
```

When the login API doesn't return an `employee_id`, the code falls back to `username` which is `"admin"`. But the dashboard API only accepts numeric employee IDs.

## The Solution

You need to ensure that when users login, the login API returns a numeric `employee_id` field.

### Step 1: Test Login API in Postman

```
POST https://ezyerp.ezyplus.in/login.php
Content-Type: application/x-www-form-urlencoded

username=admin&password=<your_password>&officeCode=<your_office_code>
```

**Look for in the response:**
```json
{
  "success": true,
  "user": {
    "employee_id": "2",
    "name": "Admin User",
    "username": "admin",
    "department": "IT"
  }
}
```

**Key:** The `employee_id` field should be numeric (e.g., "2", not "admin").

### Step 2: Check What Your API Returns

If your login API returns:
- ✅ `employee_id` field with numeric value → Go to Step 3
- ❌ No `employee_id` field → Contact backend team
- ❌ `employee_id` is empty → Contact backend team

### Step 3: Verify Field Extraction

Check if the app is correctly extracting the `employee_id`:

1. Run the app
2. Look for logs showing `empid: 2` (numeric)
3. If still showing `empid: admin`, update field mapping in `auth_service.dart`

### Step 4: Test Dashboard API

Once you have numeric empid, test the dashboard API:

```
POST https://ezyerp.ezyplus.in/userdashbord.php
Content-Type: application/x-www-form-urlencoded

empid=2&sdate=2025-10-22&edate=2025-10-22
```

**Expected response:**
```json
{
  "flag": true,
  "msg": "Success",
  "userdashboard": {
    "collectioncnt": "232",
    "collectionamt": "1542707.40",
    "pendingamt": 0,
    "salesordercnt": "0",
    "salesorderamt": "0.00"
  }
}
```

## What We Fixed

We added **better error logging** to help diagnose this issue:

### New Logs Show

```
empid: admin (type: String), sdate: 2025-10-22, edate: 2025-10-22
Dashboard API Response Status: 200
Dashboard API Response Body: {"flag":false,"msg":"Failed","userdashboard":null}
API flag: false, msg: Failed
⚠️ WARNING: userdashboard is null or missing!
This usually means the empid parameter is invalid.
Expected: numeric employee ID, Got: admin
```

This makes it clear that:
1. The API rejected the request
2. The empid is invalid (should be numeric)
3. The issue is not with parsing, but with the API call

## What You Need to Do

### Option A: Update Login API (Recommended)

Ask your backend team to ensure the login API returns a numeric `employee_id`:

```json
{
  "success": true,
  "user": {
    "employee_id": "2",
    "name": "Admin User",
    "username": "admin"
  }
}
```

### Option B: Update Field Mapping

If the login API returns the employee ID in a different field, update `auth_service.dart` line 52:

```dart
employeeId: _s(['employee_id', 'emp_id', 'empid', 'id', 'userid', 'emp_code'], ''),
```

Add more field name variations to try.

### Option C: Use Different Fallback

If the login API can't be changed, update `dashboard.dart` line 40:

```dart
// Instead of falling back to username, use a numeric value
final empId = (u.employeeId.isNotEmpty) ? u.employeeId : u.officeId;
```

Or hardcode a numeric value for testing:

```dart
final empId = (u.employeeId.isNotEmpty) ? u.employeeId : '2';
```

## Testing the Fix

1. **Update code** (if needed)
2. **Run app**
3. **Check logs** for `empid: 2` (numeric)
4. **Verify dashboard** shows collections, customers, visits
5. **No more "Failed" messages**

## Summary

| Issue | Cause | Solution |
|-------|-------|----------|
| Dashboard shows 0 | API rejects request | Use numeric empid |
| empid is "admin" | Login API doesn't return employee_id | Update login API or field mapping |
| API returns "Failed" | Invalid empid parameter | Ensure empid is numeric |
| Collections still 0 | API returns no data | Verify employee exists in system |

---

**Status:** Waiting for numeric employee ID from login API
**Action:** Check login API response and ensure it returns `employee_id` field
**Next Step:** Test with numeric empid in Postman


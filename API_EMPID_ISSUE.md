# Dashboard API Issue - Employee ID Problem

## Current Issue

The dashboard API is returning:
```json
{
  "flag": false,
  "msg": "Failed",
  "userdashboard": null
}
```

This means the API is **rejecting the request**, not that our parsing is broken.

## Root Cause

The API is being called with:
```
empid: admin
```

But the API expects:
```
empid: <numeric_employee_id>
```

## Why This Happens

In `lib/dashboard.dart` line 40:
```dart
final empId = (u.employeeId.isNotEmpty) ? u.employeeId : u.username;
```

When `employeeId` is empty, it falls back to `username` which is `"admin"`. But the API rejects non-numeric employee IDs.

## Solution

You need to ensure that the login API returns a valid numeric `employee_id`. Here's what to check:

### 1. Check Your Login API Response

When you login, the API should return something like:
```json
{
  "success": true,
  "user": {
    "employee_id": "2",
    "name": "Admin User",
    "username": "admin",
    "department": "IT",
    "designation": "Manager"
  }
}
```

**Key:** The `employee_id` field should be numeric (e.g., "2", not "admin").

### 2. Verify in Postman

Test your login endpoint:
```
POST https://ezyerp.ezyplus.in/login.php
Content-Type: application/x-www-form-urlencoded

username=admin&password=<password>&officeCode=<code>
```

Check the response:
- ✅ Should have `employee_id` field with numeric value
- ❌ Should NOT have empty `employee_id`

### 3. Test Dashboard API Directly

Once you have the numeric employee ID, test the dashboard API:
```
POST https://ezyerp.ezyplus.in/userdashbord.php
Content-Type: application/x-www-form-urlencoded

empid=2&sdate=2025-10-22&edate=2025-10-22
```

Expected response:
```json
{
  "flag": true,
  "msg": "Success",
  "userdashboard": {
    "collectioncnt": "232",
    "collectionamt": "1542707.40"
  }
}
```

## Debug Logs to Check

After running the app, look for these logs:

### Good Logs ✅
```
empid: 2 (type: String), sdate: 2025-10-22, edate: 2025-10-22
Dashboard API Response Status: 200
Dashboard API Response Body: {"flag":true,"msg":"Success","userdashboard":{...}}
API flag: true, msg: Success
Found userdashboard: {collectioncnt: 232, ...}
```

### Bad Logs ❌
```
empid: admin (type: String), sdate: 2025-10-22, edate: 2025-10-22
Dashboard API Response Status: 200
Dashboard API Response Body: {"flag":false,"msg":"Failed","userdashboard":null}
API flag: false, msg: Failed
⚠️ WARNING: userdashboard is null or missing!
Expected: numeric employee ID, Got: admin
```

## How to Fix

### Option 1: Update Login API Response (Recommended)

Ensure your login API returns `employee_id` as a numeric value:
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

### Option 2: Update Dashboard Service

If the login API can't be changed, update the dashboard service to handle the fallback better:

```dart
// In dashboard.dart, line 40
final empId = (u.employeeId.isNotEmpty) ? u.employeeId : u.officeId;
```

Use `officeId` instead of `username` as fallback (if it's numeric).

### Option 3: Add Employee ID Extraction

If the login API returns employee ID in a different field, update `AppUser.fromJson()`:

```dart
// In auth_service.dart, line 52
employeeId: _s(['employee_id', 'emp_id', 'empid', 'id', 'userid'], ''),
```

Add more field name variations to try.

## Testing Steps

1. **Check Login Response**
   - Use Postman to test login endpoint
   - Verify `employee_id` is numeric and not empty

2. **Check Dashboard Service**
   - Run the app
   - Check logs for `empid` value
   - Should be numeric (e.g., "2"), not "admin"

3. **Test Dashboard API**
   - Use Postman with numeric empid
   - Verify API returns `"flag": true`

4. **Verify in App**
   - Dashboard should show collections, customers, visits
   - No more "Failed" messages

## Common Issues

### Issue: empid is still "admin"
**Solution:** 
- Check if login API returns `employee_id`
- If not, ask backend team to add it
- Or use a different field as fallback

### Issue: empid is empty
**Solution:**
- Check if login API returns any ID field
- Update field mapping in `AppUser.fromJson()`
- Add more field name variations

### Issue: API still returns "Failed"
**Solution:**
- Verify empid is numeric
- Check if employee exists in the system
- Verify date range is valid
- Check API logs on server side

## Next Steps

1. ✅ Check your login API response in Postman
2. ✅ Verify `employee_id` field is present and numeric
3. ✅ Update code if needed
4. ✅ Test dashboard API with numeric empid
5. ✅ Run app and verify dashboard displays data

---

**Status:** Waiting for employee ID from login API
**Action Required:** Check login API response and ensure it returns numeric employee_id


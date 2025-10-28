# Dashboard Fix - Verification Steps

## Quick Start

### Step 1: Run Tests
```bash
cd eazystaff
flutter test test/auth_service_test.dart -v
flutter test test/dashboard_service_test.dart -v
```

**Expected Result:** All 24 tests pass ✅

### Step 2: Run the App
```bash
flutter run
```

### Step 3: Check Debug Logs

Look for these logs in the console:

#### Login Logs
```
=== LOGIN USER EXTRACTION ===
User data from API: {name: ..., username: admin, employee_id: 2, ...}
Cached user: name=..., empId=2, username=admin
=== END LOGIN USER EXTRACTION ===
```

#### Employee ID Extraction Logs
```
=== AppUser.fromJson DEBUG ===
Raw JSON keys: [name, username, employee_id, ...]
Extracted employeeId: "2"
Full user data: {...}
=== END AppUser.fromJson DEBUG ===
```

#### Dashboard API Logs
```
=== DASHBOARD API REQUEST ===
URL: https://ezyerp.ezyplus.in/userdashbord.php
empid: 2 (type: String), sdate: 2025-10-22, edate: 2025-10-22
Dashboard API Response Status: 200
Dashboard API Response Body: {"flag":true,"msg":"Success","userdashboard":{...}}
API flag: true, msg: Success
Found userdashboard: {collectioncnt: 232, ...}
=== END DASHBOARD API REQUEST ===
```

#### Dashboard Data Parsing Logs
```
=== DASHBOARD DATA PARSING ===
Raw JSON keys: [flag, msg, userdashboard]
Dashboard keys: [collectioncnt, collectionamt, ...]
Parsed dashboard values:
  collections=232 (from keys: month_collections, collections, ...)
  customers=0 (from keys: month_customers, customers, ...)
  visits=0 (from keys: month_visits, visits, ...)
=== END DASHBOARD DATA PARSING ===
```

## Detailed Verification

### Verify Employee ID Extraction

1. **Check if login API returns employee_id**
   - Use Postman to test login endpoint
   - Look for numeric ID fields in response

2. **Check if app extracts it correctly**
   - Look for `Extracted employeeId: "2"` in logs
   - If empty, check if field name is in the list: `employee_id`, `emp_id`, `empid`, `id`, `userid`, `user_id`, `eid`

3. **Check fallback logic**
   - If `employeeId` is empty, app tries `officeId`
   - If both empty, app uses `username` (last resort)

### Verify Dashboard API Call

1. **Check empid parameter**
   - Should be numeric (e.g., "2"), not "admin"
   - Look for: `empid: 2 (type: String)`

2. **Check API response**
   - Should have `flag: true` and `msg: Success`
   - Should have `userdashboard` object with data

3. **Check data parsing**
   - Collections should be 232 (not 0)
   - Customers should be 0 (from salesordercnt)
   - Visits should be 0 (not provided by API)

### Verify Dashboard Display

1. **Check Collections widget**
   - Should show 232 (not 0)
   - Should show "₹232" or similar format

2. **Check Customers widget**
   - Should show 0 (from salesordercnt)

3. **Check Visits widget**
   - Should show 0 (not provided by API)

## Troubleshooting

### Issue: Still showing 0 collections

**Check:**
1. Are the logs showing `empid: admin`?
   - Yes → Employee ID not extracted, check login response
   - No → Check if API is returning data

2. Are the logs showing `flag: false, msg: Failed`?
   - Yes → API rejected the request, check empid parameter
   - No → Check data parsing

3. Are the logs showing `collections=0`?
   - Yes → API returned no data or field name is different
   - No → Check dashboard display code

### Issue: Employee ID not extracted

**Check:**
1. Is login API returning a user object?
   - Look for: `User data from API: {...}`
   - If not, check `_extractUser()` method

2. Is the employee ID field in the response?
   - Look for: `Raw JSON keys: [...]`
   - Check if any of these fields are present: `employee_id`, `emp_id`, `empid`, `id`, `userid`, `user_id`, `eid`

3. Is the field value empty?
   - Look for: `Extracted employeeId: ""`
   - If empty, the field exists but has no value

### Issue: API returning flag: false

**Check:**
1. Is empid numeric?
   - Look for: `empid: 2` (good) vs `empid: admin` (bad)

2. Is the date range valid?
   - Look for: `sdate: 2025-10-22, edate: 2025-10-22`

3. Is the employee ID valid in the system?
   - Test in Postman with the same empid

## Files Changed

1. **lib/services/auth_service.dart**
   - Added import for `kDebugMode`
   - Enhanced employee ID extraction
   - Added debug logging

2. **lib/dashboard.dart**
   - Improved fallback logic for empid

3. **test/auth_service_test.dart** (NEW)
   - 13 comprehensive tests

## Rollback Instructions

If you need to revert the changes:

```bash
git checkout lib/services/auth_service.dart
git checkout lib/dashboard.dart
git rm test/auth_service_test.dart
```

## Support

If you encounter issues:

1. Check the debug logs first
2. Verify login API response in Postman
3. Verify dashboard API response in Postman with numeric empid
4. Check if field names match the expected variations
5. Contact backend team if employee ID field is missing from login response


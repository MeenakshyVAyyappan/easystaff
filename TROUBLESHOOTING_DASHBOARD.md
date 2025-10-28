# Dashboard Troubleshooting Guide

## Quick Diagnosis

### Step 1: Check the Logs

Run the app and look for this in the terminal:

```
=== DASHBOARD API REQUEST ===
empid: ???
```

**What you see determines the issue:**

| empid Value | Status | Action |
|-------------|--------|--------|
| `2` (numeric) | ✅ Good | Go to Step 2 |
| `admin` (text) | ❌ Bad | See "Fix: Invalid empid" |
| Empty | ❌ Bad | See "Fix: Missing empid" |

### Step 2: Check API Response

Look for:
```
Dashboard API Response Body: {"flag":???,"msg":"???","userdashboard":???}
```

**What you see determines the issue:**

| Response | Status | Action |
|----------|--------|--------|
| `"flag":true,"msg":"Success"` | ✅ Good | Go to Step 3 |
| `"flag":false,"msg":"Failed"` | ❌ Bad | See "Fix: API Rejected" |
| `"flag":false,"msg":"Invalid empid"` | ❌ Bad | See "Fix: Invalid empid" |

### Step 3: Check Parsed Values

Look for:
```
Parsed dashboard values:
  collections=???
  customers=???
  visits=???
```

**What you see determines the issue:**

| Values | Status | Action |
|--------|--------|--------|
| `collections=232` | ✅ Good | Dashboard should work! |
| `collections=0` | ❌ Bad | See "Fix: Zero Values" |

---

## Common Issues & Fixes

### Fix 1: Invalid empid (empid: admin)

**Problem:**
```
empid: admin
Dashboard API Response Body: {"flag":false,"msg":"Failed","userdashboard":null}
```

**Cause:** API expects numeric employee ID, not username.

**Solution:**

1. **Check Login API Response**
   - Open Postman
   - Test login endpoint
   - Look for `employee_id` field
   - Should be numeric (e.g., "2")

2. **If employee_id is present:**
   - Verify it's being extracted correctly
   - Check `AppUser.fromJson()` in `auth_service.dart`
   - Ensure field name matches API response

3. **If employee_id is missing:**
   - Contact backend team
   - Ask them to add `employee_id` to login response
   - Or use a different numeric field

4. **Temporary Workaround:**
   - Edit `dashboard.dart` line 40
   - Change fallback from `u.username` to a numeric value
   - Example: `final empId = u.employeeId.isNotEmpty ? u.employeeId : '2';`

### Fix 2: Missing empid (empid: empty)

**Problem:**
```
empid:  (empty)
Dashboard API Response Body: {"flag":false,"msg":"Failed","userdashboard":null}
```

**Cause:** Employee ID is not being extracted from login response.

**Solution:**

1. **Check Login Response**
   - Test login in Postman
   - Look for any ID field (employee_id, emp_id, id, userid, etc.)

2. **Update Field Mapping**
   - Edit `auth_service.dart` line 52
   - Add more field name variations
   - Example:
     ```dart
     employeeId: _s(['employee_id', 'emp_id', 'empid', 'id', 'userid', 'emp_code'], ''),
     ```

3. **Test Again**
   - Run app
   - Check logs for numeric empid
   - Should no longer be empty

### Fix 3: API Rejected (flag: false, msg: Failed)

**Problem:**
```
empid: 2
Dashboard API Response Body: {"flag":false,"msg":"Failed","userdashboard":null}
```

**Cause:** API rejected the request (even with numeric empid).

**Solution:**

1. **Check Employee Exists**
   - Verify employee ID "2" exists in the system
   - Check with backend team

2. **Check Date Range**
   - Verify date range is valid
   - Current date: 2025-10-22
   - Should have data for this date

3. **Check API Logs**
   - Ask backend team to check server logs
   - Look for error messages
   - May reveal the actual issue

4. **Test in Postman**
   - Use same empid, sdate, edate
   - See if API returns data
   - If not, issue is with API/data, not app

### Fix 4: Zero Values (collections=0)

**Problem:**
```
empid: 2
Dashboard API Response Body: {"flag":true,"msg":"Success","userdashboard":{...}}
collections=0
```

**Cause:** API returned data but parsing failed.

**Solution:**

1. **Check API Response**
   - Look at full response body
   - Verify `collectioncnt` field exists
   - Should have numeric value

2. **Check Field Names**
   - API might use different field names
   - Common variations:
     - `collectioncnt`, `collection_cnt`, `collections`
     - `customercnt`, `customer_cnt`, `customers`
     - `visitcnt`, `visit_cnt`, `visits`

3. **Update Field Mapping**
   - Edit `dashboard_service.dart` line 75-78
   - Add more field name variations
   - Example:
     ```dart
     final collections = _i(['month_collections','collections','total_collections','collectioncnt','collection_cnt','collectioncount']);
     ```

4. **Test Again**
   - Run app
   - Check logs for parsed values
   - Should show correct numbers

---

## Debug Checklist

- [ ] Check empid in logs (should be numeric)
- [ ] Check API response (should have flag: true)
- [ ] Check parsed values (should not be 0)
- [ ] Check API response body (look for field names)
- [ ] Check field mapping (add missing field names)
- [ ] Test in Postman (verify API works)
- [ ] Check backend logs (if API still fails)

---

## Useful Postman Tests

### Test 1: Login API
```
POST https://ezyerp.ezyplus.in/login.php
Content-Type: application/x-www-form-urlencoded

username=admin&password=<password>&officeCode=<code>
```

**Check:** Does response have `employee_id` field?

### Test 2: Dashboard API (with numeric empid)
```
POST https://ezyerp.ezyplus.in/userdashbord.php
Content-Type: application/x-www-form-urlencoded

empid=2&sdate=2025-10-22&edate=2025-10-22
```

**Check:** Does response have `flag: true` and `userdashboard` data?

### Test 3: Dashboard API (with username)
```
POST https://ezyerp.ezyplus.in/userdashbord.php
Content-Type: application/x-www-form-urlencoded

empid=admin&sdate=2025-10-22&edate=2025-10-22
```

**Check:** Does API reject with `flag: false`?

---

## Getting Help

If you're stuck:

1. **Check the logs** - Most issues are visible in debug logs
2. **Test in Postman** - Verify API works independently
3. **Check field names** - API might use different field names
4. **Contact backend team** - They can verify employee data exists
5. **Check API documentation** - Verify expected parameters and response format

---

**Last Updated:** 2025-10-22
**Status:** Ready for troubleshooting


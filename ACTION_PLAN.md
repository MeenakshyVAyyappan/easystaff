# Dashboard Issue - Action Plan

## Current Status

❌ **Dashboard showing 0 for Collections, Customers, Visits**

**Root Cause:** API is rejecting requests because `empid` is being sent as `"admin"` instead of a numeric employee ID.

**Evidence:**
```
API Response: {"flag":false,"msg":"Failed","userdashboard":null}
```

## What We've Done

✅ Added comprehensive error logging to identify the issue
✅ Created troubleshooting guides
✅ Identified the root cause (invalid empid)
✅ Documented the solution

## What You Need to Do

### Phase 1: Investigate (Today)

**Task 1.1: Test Login API**
- [ ] Open Postman
- [ ] Test login endpoint with your credentials
- [ ] Check if response includes `employee_id` field
- [ ] Note the value (should be numeric like "2")

**Task 1.2: Check Current empid**
- [ ] Run the app
- [ ] Look for logs showing `empid: ???`
- [ ] Is it numeric or "admin"?

**Task 1.3: Test Dashboard API**
- [ ] In Postman, test dashboard API with numeric empid
- [ ] Example: `empid=2&sdate=2025-10-22&edate=2025-10-22`
- [ ] Does it return `flag: true` and data?

### Phase 2: Fix (Based on Investigation)

**If login API returns numeric employee_id:**
- [ ] Verify field name matches `employee_id`
- [ ] Check if it's being extracted correctly
- [ ] Run app and verify empid is numeric in logs
- [ ] Dashboard should work!

**If login API doesn't return employee_id:**
- [ ] Contact backend team
- [ ] Ask them to add `employee_id` to login response
- [ ] Or ask for alternative numeric ID field

**If login API returns employee_id in different field:**
- [ ] Update `auth_service.dart` line 52
- [ ] Add field name to extraction list
- [ ] Example: `employeeId: _s(['employee_id', 'emp_id', 'empid', 'id', 'userid'], '')`

**If you need quick fix for testing:**
- [ ] Edit `dashboard.dart` line 40
- [ ] Change: `final empId = (u.employeeId.isNotEmpty) ? u.employeeId : u.username;`
- [ ] To: `final empId = (u.employeeId.isNotEmpty) ? u.employeeId : '2';`
- [ ] Replace '2' with actual numeric employee ID

### Phase 3: Verify (After Fix)

- [ ] Run app
- [ ] Check logs for `empid: 2` (numeric)
- [ ] Verify API response shows `flag: true`
- [ ] Check dashboard displays collections, customers, visits
- [ ] No more "Failed" messages

## Quick Reference

### Check These Logs

**Good Logs ✅**
```
empid: 2 (type: String)
Dashboard API Response Status: 200
Dashboard API Response Body: {"flag":true,"msg":"Success","userdashboard":{...}}
API flag: true, msg: Success
Found userdashboard: {collectioncnt: 232, ...}
Parsed dashboard values:
  collections=232
```

**Bad Logs ❌**
```
empid: admin (type: String)
Dashboard API Response Status: 200
Dashboard API Response Body: {"flag":false,"msg":"Failed","userdashboard":null}
API flag: false, msg: Failed
⚠️ WARNING: userdashboard is null or missing!
Expected: numeric employee ID, Got: admin
```

## Files to Reference

1. **API_EMPID_ISSUE.md** - Detailed explanation of the issue
2. **TROUBLESHOOTING_DASHBOARD.md** - Step-by-step troubleshooting
3. **DASHBOARD_REAL_ISSUE.md** - Root cause analysis
4. **ACTION_PLAN.md** - This file

## Timeline

| Phase | Task | Time | Status |
|-------|------|------|--------|
| 1 | Investigate login API | 15 min | ⏳ TODO |
| 1 | Check current empid | 5 min | ⏳ TODO |
| 1 | Test dashboard API | 10 min | ⏳ TODO |
| 2 | Fix code (if needed) | 10 min | ⏳ TODO |
| 3 | Verify fix | 5 min | ⏳ TODO |
| **Total** | | **45 min** | |

## Success Criteria

✅ Dashboard displays Collections: 232 (not 0)
✅ Dashboard displays Customers: 0 (or correct value)
✅ Dashboard displays Visits: 0 (or correct value)
✅ No "Failed" messages in logs
✅ API returns `flag: true`

## If You Get Stuck

1. **Check the logs** - Most issues are visible in debug output
2. **Test in Postman** - Verify API works independently
3. **Review troubleshooting guide** - See TROUBLESHOOTING_DASHBOARD.md
4. **Contact backend team** - They can verify employee data

## Next Steps

1. ⏳ Run the app and check the logs
2. ⏳ Test login API in Postman
3. ⏳ Test dashboard API with numeric empid
4. ⏳ Update code if needed
5. ⏳ Verify dashboard works

---

**Status:** Ready for investigation
**Action Required:** Check login API response
**Estimated Time:** 45 minutes


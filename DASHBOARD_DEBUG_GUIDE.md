# Dashboard Debug Guide

## Understanding the Fix

### The Bug (Before)
```dart
// ❌ WRONG: Helper functions looked in 'j' instead of 'dashboard'
final dashboard = (j['userdashboard'] is Map) ? j['userdashboard'] as Map : j;

int _i(List keys) {
  for (final k in keys) {
    final v = j[k];  // ❌ Looking in wrong object!
    ...
  }
}

// Result: All values defaulted to 0
// collections=0, customers=0, visits=0
```

### The Fix (After)
```dart
// ✅ CORRECT: Helper functions look in 'dashboard'
final dashboard = (j['userdashboard'] is Map) ? j['userdashboard'] as Map : j;

int _i(List keys) {
  for (final k in keys) {
    final v = dashboard[k];  // ✅ Looking in correct object!
    ...
  }
}

// Result: Values correctly extracted
// collections=232, customers=0, visits=0
```

## Debug Output Interpretation

### What You'll See in Logs

#### 1. API Request
```
=== DASHBOARD API REQUEST ===
URL: https://ezyerp.ezyplus.in/userdashbord.php
empid: 2, sdate: 2025-10-01, edate: 2025-10-31
Dashboard API Response Status: 200
Dashboard API Response Body: {"flag":true,"msg":"Success","userdashboard":{...}}
=== END DASHBOARD API REQUEST ===
```

#### 2. Data Parsing
```
=== DASHBOARD DATA PARSING ===
Raw JSON keys: [flag, msg, userdashboard]
Dashboard keys: [collectioncnt, collectionamt, pendingamt, salesordercnt, salesorderamt]
Full dashboard data: {collectioncnt: 232, collectionamt: 1542707.40, ...}
Parsed dashboard values:
  collections=232 (from keys: month_collections, collections, total_collections, collectioncnt, collectioncount)
  customers=0 (from keys: month_customers, customers, total_customers, customercnt, customercount)
  visits=0 (from keys: month_visits, visits, total_visits, visitcnt, visitcount)
  today transactions count: 0
=== END DASHBOARD DATA PARSING ===
```

### Key Indicators

✅ **Good Signs:**
- `collections=232` (not 0)
- `Dashboard keys: [collectioncnt, collectionamt, ...]` (shows extracted data)
- `Dashboard API Response Status: 200` (successful API call)

❌ **Bad Signs:**
- `collections=0` (data not extracted)
- `Dashboard keys: [flag, msg, userdashboard]` (not extracted from wrapper)
- `Dashboard API Response Status: 500` (API error)

## Testing the Fix

### Run Unit Tests
```bash
cd eazystaff
flutter test test/dashboard_service_test.dart -v
```

Expected output:
```
00:01 +11: All tests passed!
```

### Manual Testing Steps

1. **Start the app**
   ```bash
   flutter run
   ```

2. **Login with test credentials**
   - Username: (your test user)
   - Password: (your test password)

3. **Navigate to Dashboard**
   - Check the Collections widget
   - Should show 232 (not 0)

4. **Check Terminal Logs**
   - Look for `collections=232` in the output
   - Verify no errors in parsing

## Common Issues & Solutions

### Issue: Collections still showing 0
**Solution:**
1. Check API response in Postman
2. Verify `collectioncnt` field exists
3. Check terminal logs for parsing errors
4. Ensure API is returning data

### Issue: Customers showing 0
**Solution:**
1. API doesn't provide `customercnt` field
2. Check if `salesordercnt` is available
3. This is expected behavior if data not in API

### Issue: Visits showing 0
**Solution:**
1. API doesn't provide `visitcnt` field
2. This is expected - API doesn't track visits
3. May need separate API call for visits

## Field Mapping Reference

| Display Field | API Field Names (Priority Order) |
|---|---|
| Collections | `collectioncnt`, `month_collections`, `collections`, `total_collections`, `collectioncount` |
| Customers | `customercnt`, `month_customers`, `customers`, `total_customers`, `customercount`, `salesordercnt`, `salesordercount` |
| Visits | `visitcnt`, `month_visits`, `visits`, `total_visits`, `visitcount` |

## API Response Format

### Expected Format
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

### Alternative Formats Supported
```json
// Flat structure (no wrapper)
{
  "collectioncnt": "232",
  "collectionamt": "1542707.40"
}

// With today's transactions
{
  "userdashboard": {...},
  "today": [
    {"party": "ABC Corp", "amount": "5000", "time": "10:30 AM"}
  ]
}
```

## Performance Notes

- Dashboard loads in ~2-3 seconds
- API timeout: 25 seconds
- Logs are only printed in debug mode
- No performance impact from logging

## Next Steps

1. ✅ Verify dashboard displays correct values
2. ✅ Monitor logs for any issues
3. ✅ Test with different API responses
4. ✅ Verify UI updates correctly


# Credit Age Report - Issue Analysis & Fix

## What is a Credit Age Report?

A **Credit Age Report** is a financial document that shows:
- **Outstanding invoices** for a customer that haven't been fully paid
- **Age of receivables** - how long each invoice has been outstanding (30 days, 60 days, 90+ days)
- **Balance amounts** - how much is still owed on each invoice
- **Customer details** - customer name, contact info, address

This helps businesses track:
- Which customers owe money
- How overdue the payments are
- Which invoices need collection follow-up
- Cash flow and receivables aging

---

## The Problem

### What Was Showing in the Emulator
Your screenshot showed all fields displaying **₹ 0.00** for Balance and **0** for Days, even though the API was returning correct data.

### Root Causes

1. **Missing `balamt` field mapping**
   - API returns: `balamt: "23365.00"`
   - Code was looking for: `balance_amount`, `balance`, `outstanding`, `currbalance`
   - Result: Balance defaulted to 0.0

2. **Missing `noofdays` field**
   - API returns: `noofdays: "42"` (days outstanding)
   - Code wasn't parsing this field at all
   - Result: Days calculated from date instead of using API value

3. **Missing `nettotal` field mapping**
   - API returns: `nettotal: "23365.20"` (credit amount)
   - Code was looking for: `totalamt` (which was also present, but good to have backup)

---

## The Solution

### Changes Made

#### 1. **Updated Transaction Model** (`lib/models/customer.dart`)

Added a new field to store days outstanding from the API:

```dart
class Transaction {
  // ... existing fields ...
  final int noofdays; // Days outstanding from API
  
  Transaction({
    // ... existing parameters ...
    this.noofdays = 0,
    // ...
  });
}
```

#### 2. **Enhanced Field Mapping** (`lib/models/customer.dart`)

Updated `Transaction.fromJson()` to recognize all API field names:

```dart
// Added support for 'balamt' field
balanceAmount: getDouble(['balanceAmount', 'balance_amount', 'balance', 
                          'outstanding', 'currbalance', 'balamt']),

// Added support for 'nettotal' field
creditAmount: getDouble(['creditAmount', 'credit_amount', 'credit', 'debit', 
                         'amount', 'totalamt', 'nettotal']),

// Added parsing for 'noofdays' field
noofdays: getInt(['noofdays', 'no_of_days', 'days_outstanding', 'daysold']),
```

#### 3. **Updated UI Logic** (`lib/pages/credit_age_report_page.dart`)

Changed to use API's `noofdays` value instead of calculating from date:

```dart
// Use noofdays from API if available, otherwise calculate from date
final daysOld = transaction.noofdays > 0 ? transaction.noofdays : 
                _calculateDaysOld(transaction.date);
```

#### 4. **Updated Mock Data** (`lib/services/customer_service.dart`)

Added `noofdays` to all mock transaction objects for consistency.

#### 5. **Added Comprehensive Tests** (`test/url_launcher_test.dart`)

Added test case that validates the exact API response format:

```dart
test('Transaction.fromJson handles Credit Age Report API response', () {
  // Tests with actual API response structure
  expect(transaction.balanceAmount, 23365.00); // Validates 'balamt' parsing
  expect(transaction.noofdays, 42); // Validates 'noofdays' parsing
  expect(transaction.creditAmount, 23365.20); // Validates 'totalamt' parsing
});
```

---

## API Response Format

The Credit Age Report API returns data in this format:

```json
{
  "flag": true,
  "msg": "Customer List",
  "creditage": [
    {
      "invoice": "SE/25-26/1260",
      "invoiceno": "SE/25-26/1260",
      "totalamt": "23365.20",
      "netamount": "23365.20",
      "nettotal": "23365.20",
      "balamt": "23365.00",
      "noofdays": "42",
      "pur_date": "2025-09-10",
      "customer_name": "OPAL CERAMICS",
      "mobileno": "8943340757",
      "address": "Manathumangalam, Ooty Road"
    }
  ]
}
```

---

## Testing

All tests pass successfully:

```
✓ Transaction.fromJson handles various field names
✓ Transaction.fromJson handles alternative field names
✓ Transaction.fromJson handles date parsing
✓ Transaction.fromJson handles missing fields gracefully
✓ Transaction.fromJson handles Credit Age Report API response

All tests passed!
```

---

## Result

After these changes:
- ✅ Balance amounts display correctly (e.g., ₹ 23365.00)
- ✅ Days outstanding display correctly (e.g., 42 days)
- ✅ Color-coded badges work properly (yellow ≤30, green ≤60, orange ≤90, red >90)
- ✅ All three tabs (Statement, Credit Age, Collection) work correctly
- ✅ API data is properly mapped to UI fields
- ✅ Backward compatibility maintained with mock data


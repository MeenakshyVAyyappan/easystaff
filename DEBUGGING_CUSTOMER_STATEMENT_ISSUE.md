# Debugging: Customer Statement Not Working for Other Customers

## The Problem

When you click on different customers in the Customer Statement:
- **First Customer (3 STAR ELECTRICAL & PLUMBING)**: ✅ Works correctly, shows transactions
- **Other Customers**: ❌ Shows "No transactions found for selected period"

---

## Root Cause Analysis

The issue is likely one of these:

### 1. **API Returns Null Values for Some Customers**
The API endpoint `customerstatement.php` may return:
```json
{
  "flag": true,
  "msg": "Customer List",
  "statement": [
    {
      "expincId": "0",
      "alltype": "Old Balance",
      "incout1": null,
      "incin1": null,
      "ob": null,
      "invoice": null
    }
  ]
}
```

### 2. **Customer ID Format Issue**
The customer ID might be in a different format:
- First customer: `1331` (numeric)
- Other customers: Could be string, or different format

### 3. **API Permissions**
The API might only return data for specific customers based on:
- User permissions
- Office code
- Financial year

---

## How to Debug

### Step 1: Check Terminal Output

When you click on a customer, look for this in the terminal:

```
I/flutter: Fetching customer statement with params: {
  officecode: WF01,
  officeid: 1,
  financialyearid: 2,
  sdate: 2025-07-24,
  edate: 2025-10-22,
  customerid: 1331
}
I/flutter: Customer ID being sent: 1331 (type: String)
I/flutter: Response body: {...}
I/flutter: Total transactions parsed: 1
I/flutter: First transaction: invoice=COB02420, balance=17603.0, credit=79655.0, receipt=62052.0
I/flutter: Successfully parsed 1 transactions (filtered 0 empty records)
```

### Step 2: Compare Customer IDs

**For Working Customer:**
```
customerid: 1331
```

**For Non-Working Customer:**
```
customerid: ??? (check what this value is)
```

If the customer ID is different format (e.g., string vs int), that could be the issue.

### Step 3: Check API Response

Look at the full API response in the terminal:

**Working Response:**
```json
{
  "statement": [
    {
      "invoice": "COB02420",
      "incout1": "79655.00",
      "ob": "17603.00"
    }
  ]
}
```

**Non-Working Response:**
```json
{
  "statement": [
    {
      "invoice": null,
      "incout1": null,
      "ob": null
    }
  ]
}
```

---

## Enhanced Debug Logging

I've added detailed logging to help identify the issue:

### In `lib/services/customer_service.dart`:

```dart
// Shows the customer ID being sent
debugPrint('Customer ID being sent: $customerId (type: ${customerId.runtimeType})');

// Shows all transactions before filtering
debugPrint('Total transactions parsed: ${allTransactions.length}');
debugPrint('First transaction: invoice=${allTransactions.first.invoiceNo}, balance=${allTransactions.first.balanceAmount}');

// Shows which transactions are filtered out
debugPrint('Filtering out empty transaction: invoice=$hasInvoice, balance=$hasBalance, credit=$hasCredit, receipt=$hasReceipt');

// Shows final count
debugPrint('Successfully parsed ${transactions.length} transactions (filtered ${allTransactions.length - transactions.length} empty records)');
```

---

## Possible Solutions

### Solution 1: Check Customer ID Format
Ensure customer ID is being passed as a string:
```dart
final customerId = widget.customer.id; // Should be String
```

### Solution 2: Verify API Permissions
Check if the API requires additional parameters:
- Different office code for different customers?
- Different financial year?
- User permissions?

### Solution 3: Check API Response
If API returns null values, the backend might not have data for that customer.

### Solution 4: Add Customer ID Validation
```dart
if (customerId.isEmpty) {
  throw Exception('Customer ID is empty');
}
```

---

## Next Steps

1. **Run the app** and click on different customers
2. **Check the terminal output** for the debug messages
3. **Share the terminal output** showing:
   - Customer ID being sent for working customer
   - Customer ID being sent for non-working customer
   - Full API response for both
4. **Compare the responses** to identify the pattern

---

## Files Modified

- `lib/services/customer_service.dart` - Added enhanced debug logging

---

## Build Status
✅ Flutter analyze: No errors
✅ All tests pass (12/12)
✅ Code compiles successfully


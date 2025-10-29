# Customer Functionality Test Guide

## Overview
This guide helps you test the customer listing and customer statement functionality in the EazyStaff app.

## Test Steps

### 1. Test Customer Listing
1. **Open the app** and log in with valid credentials
2. **Navigate to Customers tab** in the bottom navigation bar
3. **Verify customer list loads** - you should see:
   - Customer names with avatars
   - Area/location information
   - Balance amounts (colored red for positive, green for negative)
   - Phone and WhatsApp action buttons

### 2. Test Customer Search and Filter
1. **Use the search box** to search for customers by name or area
2. **Use the area filter dropdown** to filter customers by specific areas
3. **Verify filtering works** correctly

### 3. Test Customer Statement Access
1. **Tap on any customer card** to open the customer options modal
2. **Tap "Customer Statement"** option
3. **Verify navigation** to the customer detail page with statement tab active
4. **Check for proper loading** indicators and error handling

### 4. Test Customer Statement Data
1. **In the customer statement page**, verify:
   - Date range picker works
   - Transactions load correctly
   - Transaction details show: invoice number, date, amounts, balance
   - Summary section shows totals
   - PDF sharing functionality works

### 5. Test Error Handling
1. **Test with poor network** connection
2. **Verify error messages** are user-friendly
3. **Check retry functionality** works

## API Endpoints Being Used

### Customer Listing API
- **URL**: `https://ezyerp.ezyplus.in/customers.php`
- **Method**: POST
- **Required Fields**:
  - `officeid`: Office ID from user authentication
  - `officecode`: Office code from user authentication  
  - `financialyearid`: Financial year ID from user authentication
  - `empid`: Employee ID from user authentication

### Customer Statement API
- **URL**: `https://ezyerp.ezyplus.in/customerstatement.php`
- **Method**: POST
- **Required Fields**:
  - `officecode`: Office code from user authentication
  - `officeid`: Office ID from user authentication
  - `customerid`: Customer ID from the customer list
  - `financialyearid`: Financial year ID from user authentication
  - `sdate`: Start date in YYYY-MM-DD format
  - `edate`: End date in YYYY-MM-DD format

## Expected Behavior

### Customer List
- Should load all customers from the API
- Should handle duplicate customers by keeping the one with higher ID
- Should show proper customer information (name, area, balance)
- Should provide search and filter functionality

### Customer Statement
- Should load transaction history for the selected customer
- Should handle different date ranges
- Should show proper transaction details
- Should calculate and display summary totals
- Should handle cases where no transactions are found
- Should provide PDF export functionality

## Troubleshooting

### If Customer List is Empty
1. Check network connection
2. Verify user authentication data (office code, office ID, etc.)
3. Check API response in debug logs
4. Ensure API parameters are correctly formatted

### If Customer Statement is Empty
1. Verify customer ID is not empty
2. Try expanding the date range
3. Check if customer has transactions in different financial years
4. Verify API parameters in debug logs

### Debug Information
The app provides extensive debug logging. Check the console/logs for:
- API request parameters
- API response data
- Customer ID validation
- Transaction parsing details
- Error messages and stack traces

## Success Criteria
✅ Customer list loads with real data from API
✅ Customer search and filtering works
✅ Customer statement opens correctly
✅ Transaction data displays properly
✅ Error handling provides user-friendly messages
✅ PDF export functionality works
✅ App handles network issues gracefully

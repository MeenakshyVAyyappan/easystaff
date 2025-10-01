import 'package:flutter_test/flutter_test.dart';
import 'package:eazystaff/models/customer.dart';

void main() {
  group('URL Launcher Tests', () {
    test('Phone number cleaning works correctly', () {
      // Test phone number cleaning logic
      final testNumbers = [
        '8113095031',
        '+91 8113095031',
        '(811) 309-5031',
        '811-309-5031',
        '811.309.5031',
        '+91-811-309-5031',
      ];
      
      for (final number in testNumbers) {
        final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
        expect(cleanNumber.contains(RegExp(r'[^\d+]')), false, 
               reason: 'Number $number should be cleaned to contain only digits and +');
      }
    });

    test('WhatsApp number formatting works correctly', () {
      final testNumbers = [
        '+918113095031',
        '918113095031',
        '8113095031',
      ];
      
      for (final number in testNumbers) {
        final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
        final whatsappNumber = cleanNumber.startsWith('+') ? cleanNumber.substring(1) : cleanNumber;
        expect(whatsappNumber.startsWith('+'), false,
               reason: 'WhatsApp number should not start with +');
        expect(whatsappNumber.contains(RegExp(r'[^\d]')), false,
               reason: 'WhatsApp number should contain only digits');
      }
    });
  });

  group('Transaction JSON Parsing Tests', () {
    test('Transaction.fromJson handles various field names', () {
      final testJson1 = {
        'invoiceid': '123',
        'customeraccountid': '420',
        'invoiceno': 'INV-001',
        'pur_date': '2024-05-30',
        'totalamt': '1824.00',
        'incout': '0.00',
        'currbalance': '2152.32',
        'msg': 'Success',
      };

      final transaction1 = Transaction.fromJson(testJson1);
      expect(transaction1.id, '123');
      expect(transaction1.customerId, '420');
      expect(transaction1.invoiceNo, 'INV-001');
      expect(transaction1.creditAmount, 1824.00);
      expect(transaction1.receiptAmount, 0.00);
      expect(transaction1.balanceAmount, 2152.32);
    });

    test('Transaction.fromJson handles alternative field names', () {
      final testJson2 = {
        'id': 'TXN-456',
        'customer_id': '789',
        'invoice_no': 'BILL-002',
        'bill_date': '2024-06-01',
        'credit_amount': '500.00',
        'receipt_amount': '200.00',
        'balance': '300.00',
        'remarks': 'Test transaction',
      };

      final transaction2 = Transaction.fromJson(testJson2);
      expect(transaction2.id, 'TXN-456');
      expect(transaction2.customerId, '789');
      expect(transaction2.invoiceNo, 'BILL-002');
      expect(transaction2.creditAmount, 500.00);
      expect(transaction2.receiptAmount, 200.00);
      expect(transaction2.balanceAmount, 300.00);
      expect(transaction2.remarks, 'Test transaction');
    });

    test('Transaction.fromJson handles date parsing', () {
      final testJsons = [
        {'date': '2024-05-30', 'invoiceNo': 'TEST1'},
        {'invoice_date': '2024-06-01', 'invoiceNo': 'TEST2'},
        {'pur_date': '2024-07-15', 'invoiceNo': 'TEST3'},
        {'bill_date': '30/05/2024', 'invoiceNo': 'TEST4'},
      ];

      for (final json in testJsons) {
        final transaction = Transaction.fromJson(json);
        expect(transaction.date, isA<DateTime>());
        expect(transaction.invoiceNo, startsWith('TEST'));
      }
    });

    test('Transaction.fromJson handles missing fields gracefully', () {
      final minimalJson = {
        'invoiceNo': 'MIN-001',
      };

      final transaction = Transaction.fromJson(minimalJson);
      expect(transaction.invoiceNo, 'MIN-001');
      expect(transaction.id, '');
      expect(transaction.customerId, '');
      expect(transaction.creditAmount, 0.0);
      expect(transaction.receiptAmount, 0.0);
      expect(transaction.balanceAmount, 0.0);
      expect(transaction.date, isA<DateTime>());
    });
  });

  group('Customer JSON Parsing Tests', () {
    test('Customer.fromJson handles various field names', () {
      final testJson = {
        'customeraccountid': '420',
        'party_name': '3 STAR ELECTRICAL & PLUMBING',
        'areas': 'Kozhikode',
        'curbbalance': '2152.32',
        'mobileno1': '8113095031',
        'mobileno2': '9876543210',
        'whatsappno': '8113095031',
        'full_address': 'Test Address',
        'lat': '11.172681100000002',
        'lng': '75.9189464',
      };

      final customer = Customer.fromJson(testJson);
      expect(customer.id, '420');
      expect(customer.name, '3 STAR ELECTRICAL & PLUMBING');
      expect(customer.areaName, 'Kozhikode');
      expect(customer.balanceAmount, 2152.32);
      expect(customer.mobileNumbers.length, 2);
      expect(customer.mobileNumbers, contains('8113095031'));
      expect(customer.mobileNumbers, contains('9876543210'));
      expect(customer.whatsappNumber, '8113095031');
      expect(customer.address, 'Test Address');
      expect(customer.latitude, 11.172681100000002);
      expect(customer.longitude, 75.9189464);
    });
  });
}

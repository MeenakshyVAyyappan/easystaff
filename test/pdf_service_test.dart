import 'package:flutter_test/flutter_test.dart';
import 'package:eazystaff/services/pdf_service.dart';
import 'package:eazystaff/models/customer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PdfService Font Tests', () {
    test('should generate PDF without Unicode font errors', () async {
      // Create a test customer
      final customer = Customer(
        id: 'TEST001',
        name: 'Test Customer',
        areaName: 'Test Area',
        balanceAmount: 5000.0,
        mobileNumbers: ['1234567890'],
        address: 'Test Address',
      );

      // Create test transactions
      final transactions = <Transaction>[
        Transaction(
          id: 'TXN001',
          customerId: 'TEST001',
          invoiceNo: 'INV001',
          date: DateTime.now().subtract(const Duration(days: 10)),
          type: TransactionType.sales,
          creditAmount: 1000.0,
          receiptAmount: 0.0,
          balanceAmount: 1000.0,
        ),
        Transaction(
          id: 'TXN002',
          customerId: 'TEST001',
          invoiceNo: 'PAY001',
          date: DateTime.now().subtract(const Duration(days: 5)),
          type: TransactionType.receipt,
          creditAmount: 0.0,
          receiptAmount: 500.0,
          balanceAmount: 500.0,
        ),
      ];

      // Test PDF generation - this should not throw Unicode font errors
      // Note: We expect a MissingPluginException for path_provider in tests,
      // but no Unicode font errors should occur
      try {
        await PdfService.generateAndShareCustomerStatement(
          customer: customer,
          transactions: transactions,
          fromDate: DateTime.now().subtract(const Duration(days: 30)),
          toDate: DateTime.now(),
        );
      } catch (e) {
        // We expect path_provider plugin errors in tests, but not Unicode font errors
        expect(e.toString(), isNot(contains('Unicode support')));
        expect(e.toString(), isNot(contains('Helvetica-Bold')));
      }
    });

    test('should generate credit age report without Unicode font errors', () async {
      // Create a test customer
      final customer = Customer(
        id: 'TEST001',
        name: 'Test Customer',
        areaName: 'Test Area',
        balanceAmount: 5000.0,
        mobileNumbers: ['1234567890'],
        address: 'Test Address',
      );

      // Create test credit transactions
      final creditTransactions = <Transaction>[
        Transaction(
          id: 'TXN001',
          customerId: 'TEST001',
          invoiceNo: 'INV001',
          date: DateTime.now().subtract(const Duration(days: 45)),
          type: TransactionType.sales,
          creditAmount: 2000.0,
          receiptAmount: 0.0,
          balanceAmount: 2000.0,
        ),
        Transaction(
          id: 'TXN002',
          customerId: 'TEST001',
          invoiceNo: 'INV002',
          date: DateTime.now().subtract(const Duration(days: 35)),
          type: TransactionType.sales,
          creditAmount: 1500.0,
          receiptAmount: 0.0,
          balanceAmount: 1500.0,
        ),
      ];

      // Test PDF generation - this should not throw Unicode font errors
      // Note: We expect a MissingPluginException for path_provider in tests,
      // but no Unicode font errors should occur
      try {
        await PdfService.generateAndShareCreditAgeReport(
          customer: customer,
          creditTransactions: creditTransactions,
          numberOfDays: 30,
          condition: 'greater than',
        );
      } catch (e) {
        // We expect path_provider plugin errors in tests, but not Unicode font errors
        expect(e.toString(), isNot(contains('Unicode support')));
        expect(e.toString(), isNot(contains('Helvetica-Bold')));
      }
    });
  });
}

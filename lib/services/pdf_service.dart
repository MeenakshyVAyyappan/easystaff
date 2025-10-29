import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:eazystaff/models/customer.dart';

class PdfService {
  static const String _companyName = "EazyStaff";
  static const String _companyAddress = "Business Management System";

  /// Initialize fonts for PDF generation with proper fallback support
  static Future<void> _initializeFonts() async {
    // No font initialization needed - we'll specify fonts in TextStyle
    // This avoids Unicode font warnings by using Times font
  }

  /// Format currency amount with Rs. prefix (avoids Rupee symbol font issues)
  static String _formatCurrency(double amount) {
    // Use "Rs." instead of "₹" to avoid font fallback issues in PDF
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  /// Create TextStyle with font fallback support
  static pw.TextStyle _createTextStyle({
    double fontSize = 10,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor color = PdfColors.black,
  }) {
    // Simulate bold text by increasing font size and using darker color
    // This avoids Unicode issues with bold font variants
    double adjustedFontSize = fontSize;
    PdfColor adjustedColor = color;

    if (fontWeight == pw.FontWeight.bold) {
      adjustedFontSize = fontSize + 1.5; // Slightly larger for emphasis
      adjustedColor = color == PdfColors.black ? PdfColors.black : color;
    }

    return pw.TextStyle(
      fontSize: adjustedFontSize,
      fontWeight: pw.FontWeight.normal, // Always use normal weight
      color: adjustedColor,
      font: pw.Font.times(), // Use Times font which has better Unicode support
    );
  }

  /// Generate and share Customer Statement PDF
  static Future<void> generateAndShareCustomerStatement({
    required Customer customer,
    required List<Transaction> transactions,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      // Initialize fonts
      await _initializeFonts();

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');
      
      // Calculate totals
      final totalCredit = transactions.fold<double>(
        0, (sum, transaction) => sum + transaction.creditAmount);
      final totalReceipt = transactions.fold<double>(
        0, (sum, transaction) => sum + transaction.receiptAmount);
      final balance = totalCredit - totalReceipt;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader('Customer Statement'),
              pw.SizedBox(height: 20),
              
              // Customer Info
              _buildCustomerInfo(customer, fromDate, toDate, dateFormat),
              pw.SizedBox(height: 20),
              
              // Transactions Table
              _buildTransactionsTable(transactions, dateFormat),
              pw.SizedBox(height: 20),
              
              // Summary
              _buildSummary(totalCredit, totalReceipt, balance),
            ];
          },
        ),
      );

      // Clean customer name for filename
      final cleanCustomerName = customer.name.replaceAll(RegExp(r'[<>:"/\\|?*&]'), '_');
      await _savePdfAndShare(
        pdf,
        'Customer_Statement_${cleanCustomerName}_${dateFormat.format(DateTime.now())}.pdf'
      );
    } catch (e) {
      throw Exception('Failed to generate customer statement PDF: $e');
    }
  }

  /// Generate and share Credit Age Report PDF
  static Future<void> generateAndShareCreditAgeReport({
    required Customer customer,
    required List<Transaction> creditTransactions,
    required int numberOfDays,
    required String condition,
  }) async {
    try {
      // Initialize fonts
      await _initializeFonts();

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');

      // Calculate total outstanding
      final totalOutstanding = creditTransactions.fold<double>(
        0, (sum, transaction) => sum + transaction.balanceAmount);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader('Credit Age Report'),
              pw.SizedBox(height: 20),

              // Customer Info
              _buildCreditAgeInfo(customer, numberOfDays, condition),
              pw.SizedBox(height: 20),

              // Credit Transactions Table
              _buildCreditTransactionsTable(creditTransactions, dateFormat),
              pw.SizedBox(height: 20),

              // Summary
              _buildCreditSummary(totalOutstanding, creditTransactions.length),
            ];
          },
        ),
      );

      // Clean customer name for filename
      final cleanCustomerName = customer.name.replaceAll(RegExp(r'[<>:"/\\|?*&]'), '_');
      await _savePdfAndShare(
        pdf,
        'Credit_Age_Report_${cleanCustomerName}_${dateFormat.format(DateTime.now())}.pdf'
      );
    } catch (e) {
      throw Exception('Failed to generate credit age report PDF: $e');
    }
  }

  /// Generate and share Collections Report PDF
  static Future<void> generateAndShareCollectionsReport({
    required List<CollectionEntry> collections,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      // Initialize fonts
      await _initializeFonts();

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');

      // Calculate total amount
      final totalAmount = collections.fold<double>(
        0, (sum, collection) => sum + collection.amount);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader('Collections Report'),
              pw.SizedBox(height: 20),

              // Report Info
              _buildCollectionsInfo(fromDate, toDate, dateFormat, totalAmount, collections.length),
              pw.SizedBox(height: 20),

              // Collections Table
              _buildCollectionsTable(collections, dateFormat),
              pw.SizedBox(height: 20),

              // Summary
              _buildCollectionsSummary(totalAmount, collections.length),
            ];
          },
        ),
      );

      await _savePdfAndShare(
        pdf,
        'Collections_Report_${dateFormat.format(DateTime.now())}.pdf'
      );
    } catch (e) {
      throw Exception('Failed to generate credit age report PDF: $e');
    }
  }

  /// Build PDF header
  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _companyName,
                  style: _createTextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.Text(
                  _companyAddress,
                  style: _createTextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Text(
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: _createTextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Text(
            title,
            style: _createTextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Build customer info section for statement
  static pw.Widget _buildCustomerInfo(
    Customer customer, 
    DateTime fromDate, 
    DateTime toDate, 
    DateFormat dateFormat
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer Name:', style: _createTextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customer.name),
                    pw.SizedBox(height: 8),
                    pw.Text('Customer ID:', style: _createTextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customer.id),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Period:', style: _createTextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${dateFormat.format(fromDate)} to ${dateFormat.format(toDate)}'),
                    pw.SizedBox(height: 8),
                    pw.Text('Area:', style: _createTextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customer.areaName),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build credit age info section
  static pw.Widget _buildCreditAgeInfo(
    Customer customer, 
    int numberOfDays, 
    String condition
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer Name:', style: _createTextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customer.name),
                    pw.SizedBox(height: 8),
                    pw.Text('Customer ID:', style: _createTextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customer.id),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Filter Criteria:', style: _createTextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('$condition $numberOfDays days'),
                    pw.SizedBox(height: 8),
                    pw.Text('Area:', style: _createTextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customer.areaName),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build transactions table for statement
  static pw.Widget _buildTransactionsTable(
    List<Transaction> transactions, 
    DateFormat dateFormat
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Invoice No', isHeader: true),
            _buildTableCell('Type', isHeader: true),
            _buildTableCell('Credit (Rs.)', isHeader: true),
            _buildTableCell('Receipt (Rs.)', isHeader: true),
            _buildTableCell('Balance (Rs.)', isHeader: true),
          ],
        ),
        // Data rows
        ...transactions.map((transaction) => pw.TableRow(
          children: [
            _buildTableCell(dateFormat.format(transaction.date)),
            _buildTableCell(transaction.invoiceNo),
            _buildTableCell(transaction.type.toString().split('.').last),
            _buildTableCell(_formatCurrency(transaction.creditAmount)),
            _buildTableCell(_formatCurrency(transaction.receiptAmount)),
            _buildTableCell(
              _formatCurrency(transaction.creditAmount - transaction.receiptAmount),
              textColor: (transaction.creditAmount - transaction.receiptAmount) > 0
                ? PdfColors.red : PdfColors.green,
            ),
          ],
        )),
      ],
    );
  }

  /// Build credit transactions table
  static pw.Widget _buildCreditTransactionsTable(
    List<Transaction> transactions, 
    DateFormat dateFormat
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Invoice No', isHeader: true),
            _buildTableCell('Days Old', isHeader: true),
            _buildTableCell('Outstanding (Rs.)', isHeader: true),
          ],
        ),
        // Data rows
        ...transactions.map((transaction) {
          final daysOld = transaction.noofdays > 0 
            ? transaction.noofdays 
            : DateTime.now().difference(transaction.date).inDays;
          
          return pw.TableRow(
            children: [
              _buildTableCell(dateFormat.format(transaction.date)),
              _buildTableCell(transaction.invoiceNo),
              _buildTableCell('$daysOld'),
              _buildTableCell(
                _formatCurrency(transaction.balanceAmount),
                textColor: transaction.balanceAmount > 0 ? PdfColors.red : PdfColors.green,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: _createTextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Build summary section for statement
  static pw.Widget _buildSummary(double totalCredit, double totalReceipt, double balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Summary',
            style: _createTextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Credit', _formatCurrency(totalCredit)),
              _buildSummaryItem('Total Receipt', _formatCurrency(totalReceipt)),
              _buildSummaryItem(
                'Balance',
                _formatCurrency(balance),
                textColor: balance > 0 ? PdfColors.red : PdfColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build summary section for credit age report
  static pw.Widget _buildCreditSummary(double totalOutstanding, int transactionCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        border: pw.Border.all(color: PdfColors.orange200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Summary',
            style: _createTextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Outstanding', _formatCurrency(totalOutstanding)),
              _buildSummaryItem('Total Invoices', '$transactionCount'),
            ],
          ),
        ],
      ),
    );
  }

  /// Build summary item
  static pw.Widget _buildSummaryItem(String label, String value, {PdfColor? textColor}) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: _createTextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: _createTextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: textColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// Build collections info section
  static pw.Widget _buildCollectionsInfo(
    DateTime fromDate,
    DateTime toDate,
    DateFormat dateFormat,
    double totalAmount,
    int totalCount
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Period: ${dateFormat.format(fromDate)} to ${dateFormat.format(toDate)}',
            style: _createTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Total Collections: ${_formatCurrency(totalAmount)}',
            style: _createTextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
          ),
          pw.Text(
            'Total Entries: $totalCount',
            style: _createTextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: _createTextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// Build collections table
  static pw.Widget _buildCollectionsTable(
    List<CollectionEntry> collections,
    DateFormat dateFormat
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Company', isHeader: true),
            _buildTableCell('Amount (Rs.)', isHeader: true),
            _buildTableCell('Type', isHeader: true),
            _buildTableCell('Payment', isHeader: true),
            _buildTableCell('Remarks', isHeader: true),
          ],
        ),
        // Data rows
        ...collections.map((collection) => pw.TableRow(
          children: [
            _buildTableCell(dateFormat.format(collection.date)),
            _buildTableCell(collection.customerName ?? 'N/A'),
            _buildTableCell(
              _formatCurrency(collection.amount),
              textColor: PdfColors.green700,
            ),
            _buildTableCell(collection.type.toString().split('.').last.toUpperCase()),
            _buildTableCell(collection.paymentType.toString().split('.').last.toUpperCase()),
            _buildTableCell(collection.remarks ?? ''),
          ],
        )),
      ],
    );
  }

  /// Build collections summary section
  static pw.Widget _buildCollectionsSummary(double totalAmount, int totalCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Summary',
                style: _createTextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Total Entries: $totalCount',
                style: _createTextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Total Amount',
                style: _createTextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Text(
                _formatCurrency(totalAmount),
                style: _createTextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Save PDF and share
  static Future<void> _savePdfAndShare(pw.Document pdf, String fileName) async {
    try {
      print('DEBUG: Starting PDF save and share process');
      final output = await getTemporaryDirectory();
      print('DEBUG: Temporary directory: ${output.path}');

      // Clean the filename to avoid path issues
      final cleanFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      print('DEBUG: Clean filename: $cleanFileName');

      final file = File('${output.path}/$cleanFileName');
      print('DEBUG: Full file path: ${file.path}');

      // Ensure the directory exists
      await file.parent.create(recursive: true);

      // Save the PDF
      print('DEBUG: Generating PDF bytes...');
      final pdfBytes = await pdf.save();
      print('DEBUG: PDF bytes generated: ${pdfBytes.length} bytes');

      print('DEBUG: Writing PDF to file...');
      await file.writeAsBytes(pdfBytes);
      print('DEBUG: PDF written to file successfully');

      // Verify file exists
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      print('DEBUG: File exists: $fileExists, Size: $fileSize bytes');

      // Use the new SharePlus API
      print('DEBUG: Sharing PDF file...');
      await Share.shareXFiles([XFile(file.path)]);
      print('DEBUG: PDF shared successfully');
    } catch (e) {
      print('DEBUG: Error in _savePdfAndShare: $e');
      throw Exception('Failed to save and share PDF: $e');
    }
  }
}

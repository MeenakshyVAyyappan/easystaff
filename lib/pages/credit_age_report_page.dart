import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';
import 'package:eazystaff/services/auth_service.dart';
import 'package:eazystaff/services/pdf_service.dart';
import 'package:intl/intl.dart';

class CreditAgeReportPage extends StatefulWidget {
  final Customer customer;

  const CreditAgeReportPage({super.key, required this.customer});

  @override
  State<CreditAgeReportPage> createState() => _CreditAgeReportPageState();
}

class _CreditAgeReportPageState extends State<CreditAgeReportPage> {
  List<Transaction> _creditTransactions = [];
  bool _isLoading = true;
  int _numberOfDays = 30;
  String _condition = 'greater_than';

  @override
  void initState() {
    super.initState();
    _loadCreditTransactions();
  }

  Future<void> _loadCreditTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== CREDIT AGE REPORT PAGE DEBUG ===');
      print('DEBUG: Customer object: ${widget.customer.name}');
      print('DEBUG: Customer ID: "${widget.customer.id}" (type: ${widget.customer.id.runtimeType}, length: ${widget.customer.id.length})');
      print('DEBUG: Customer ID isEmpty: ${widget.customer.id.isEmpty}');
      print('DEBUG: Parameters - Days: $_numberOfDays, Condition: $_condition');

      // Use real API with parameters and financial year fallback
      final transactions = await CustomerService.getCreditAgeReportWithFallback(
        customerId: widget.customer.id,
        numberOfDays: _numberOfDays,
        condition: _condition,
      );

      print('DEBUG: Loaded ${transactions.length} credit transactions');

      setState(() {
        _creditTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading credit age report: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading credit age report: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  int _calculateDaysOld(DateTime transactionDate) {
    return DateTime.now().difference(transactionDate).inDays;
  }

  Future<void> _shareCreditAgeReport() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate and share PDF
      await PdfService.generateAndShareCreditAgeReport(
        customer: widget.customer,
        creditTransactions: _creditTransactions,
        numberOfDays: _numberOfDays,
        condition: _condition,
      );

      // Hide loading indicator
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Hide loading indicator
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _creditTransactions.fold<double>(
      0, (sum, transaction) => sum + transaction.balanceAmount);

    return _buildCreditAgeTab(totalAmount);
  }

  Widget _buildCreditAgeTab(double totalAmount) {
    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Credit Age Report',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Outstanding invoices for ${widget.customer.name}',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              const SizedBox(height: 10),
              // Filter Section
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Days:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
                        const SizedBox(height: 4),
                        DropdownButton<int>(
                          value: _numberOfDays,
                          isExpanded: true,
                          underline: Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _numberOfDays = value;
                              });
                              _loadCreditTransactions();
                            }
                          },
                          items: [30, 60, 90, 120, 180, 365].map((days) {
                            return DropdownMenuItem<int>(
                              value: days,
                              child: Text('$days days', style: const TextStyle(fontSize: 11)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Condition:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
                        const SizedBox(height: 4),
                        DropdownButton<String>(
                          value: _condition,
                          isExpanded: true,
                          underline: Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _condition = value;
                              });
                              _loadCreditTransactions();
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'greater_than', child: Text('Greater than', style: TextStyle(fontSize: 11))),
                            DropdownMenuItem(value: 'less_than', child: Text('Less than', style: TextStyle(fontSize: 11))),
                            DropdownMenuItem(value: 'equal_to', child: Text('Equal to', style: TextStyle(fontSize: 11))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Outstanding:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Centered Share Button
              if (_creditTransactions.isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _shareCreditAgeReport,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Share as PDF', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Credit Transactions List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _creditTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No outstanding credit found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This customer has no outstanding\ncredit transactions for the selected criteria.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _numberOfDays = 0; // Show all transactions
                                _condition = 'greater_than';
                              });
                              _loadCreditTransactions();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Show All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCreditTransactions,
                      child: ListView.builder(
                        itemCount: _creditTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _creditTransactions[index];
                          return _buildCreditTransactionCard(transaction);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCreditTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    // Use noofdays from API if available, otherwise calculate from date
    final daysOld = transaction.noofdays > 0 ? transaction.noofdays : _calculateDaysOld(transaction.date);

    // Determine color based on age - matching your screenshot
    Color ageBgColor = Colors.yellow[100]!;
    Color ageTextColor = Colors.orange;

    if (daysOld <= 30) {
      ageBgColor = Colors.yellow[100]!;
      ageTextColor = Colors.orange;
    } else if (daysOld <= 60) {
      ageBgColor = Colors.green[100]!;
      ageTextColor = Colors.green;
    } else if (daysOld <= 90) {
      ageBgColor = Colors.orange[100]!;
      ageTextColor = Colors.orange[700]!;
    } else {
      ageBgColor = Colors.red[100]!;
      ageTextColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Invoice number and date on left, Days badge on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.invoiceNo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateFormat.format(transaction.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Days badge on the right
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ageBgColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No. of days',
                      style: TextStyle(
                        color: ageTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      '$daysOld',
                      style: TextStyle(
                        color: ageTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row: Type on left, Balance on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.type.toString().split('.').last,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹ ${transaction.balanceAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: transaction.balanceAmount > 0 ? Colors.red : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

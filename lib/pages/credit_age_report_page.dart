import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';
import 'package:share_plus/share_plus.dart';
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
      // Use real API with parameters
      final transactions = await CustomerService.getCreditAgeReport(
        customerId: widget.customer.id,
        financialYearId: '2', // Default financial year ID
        numberOfDays: _numberOfDays,
        condition: _condition,
      );
      setState(() {
        _creditTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading credit age report: $e')),
        );
      }
    }
  }

  int _calculateDaysOld(DateTime transactionDate) {
    return DateTime.now().difference(transactionDate).inDays;
  }

  void _shareCreditAgeReport() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalAmount = _creditTransactions.fold<double>(
      0, (sum, transaction) => sum + transaction.creditAmount);

    final content = StringBuffer();
    content.writeln('Credit Age Report');
    content.writeln('Customer: ${widget.customer.name}');
    content.writeln('Generated on: ${dateFormat.format(DateTime.now())}');
    content.writeln('');
    
    for (final transaction in _creditTransactions) {
      final daysOld = _calculateDaysOld(transaction.date);
      content.writeln('Invoice: ${transaction.invoiceNo}');
      content.writeln('Date: ${dateFormat.format(transaction.date)}');
      content.writeln('Type: ${transaction.type.toString().split('.').last}');
      content.writeln('Amount: ₹${transaction.creditAmount.toStringAsFixed(2)}');
      content.writeln('Days Old: $daysOld');
      content.writeln('---');
    }
    
    content.writeln('');
    content.writeln('Total Amount: ₹${totalAmount.toStringAsFixed(2)}');

    Share.share(content.toString(), subject: 'Credit Age Report - ${widget.customer.name}');
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _creditTransactions.fold<double>(
      0, (sum, transaction) => sum + transaction.creditAmount);

    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Credit Age Report',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Outstanding invoices for ${widget.customer.name}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                // Filter Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Days:', style: TextStyle(fontWeight: FontWeight.w500)),
                          DropdownButton<int>(
                            value: _numberOfDays,
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
                                child: Text('$days days'),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Condition:', style: TextStyle(fontWeight: FontWeight.w500)),
                          DropdownButton<String>(
                            value: _condition,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _condition = value;
                                });
                                _loadCreditTransactions();
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: 'greater_than', child: Text('Greater than')),
                              DropdownMenuItem(value: 'less_than', child: Text('Less than')),
                              DropdownMenuItem(value: 'equal_to', child: Text('Equal to')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Outstanding:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '₹${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
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
                    ? const Center(
                        child: Text(
                          'No outstanding credit found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
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
      ),
      floatingActionButton: _creditTransactions.isNotEmpty
          ? FloatingActionButton(
              onPressed: _shareCreditAgeReport,
              tooltip: 'Share Credit Age Report',
              child: const Icon(Icons.share),
            )
          : null,
    );
  }

  Widget _buildCreditTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final daysOld = _calculateDaysOld(transaction.date);
    
    // Determine color based on age
    Color ageColor = Colors.green;
    if (daysOld > 90) {
      ageColor = Colors.red;
    } else if (daysOld > 60) {
      ageColor = Colors.orange;
    } else if (daysOld > 30) {
      ageColor = Colors.yellow[700]!;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          transaction.invoiceNo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${dateFormat.format(transaction.date)}'),
            Text('Type: ${transaction.type.toString().split('.').last.toUpperCase()}'),
            Text(
              'Amount: ₹${transaction.creditAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ageColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ageColor),
          ),
          child: Text(
            '$daysOld days',
            style: TextStyle(
              color: ageColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

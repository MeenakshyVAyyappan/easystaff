import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class CustomerStatementPage extends StatefulWidget {
  final Customer customer;

  const CustomerStatementPage({super.key, required this.customer});

  @override
  State<CustomerStatementPage> createState() => _CustomerStatementPageState();
}

class _CustomerStatementPageState extends State<CustomerStatementPage> {
  DateTime _selectedFromDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _selectedToDate = DateTime.now();
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use real API with date range
      final transactions = await CustomerService.getCustomerStatement(
        customerId: widget.customer.id,
        financialYearId: '2', // Default financial year ID
        startDate: _selectedFromDate,
        endDate: _selectedToDate,
      );
      setState(() {
        _transactions = transactions;
        _filteredTransactions = _filterTransactionsByDate(transactions);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  List<Transaction> _filterTransactionsByDate(List<Transaction> transactions) {
    return transactions.where((transaction) {
      return transaction.date.isAfter(_selectedFromDate.subtract(const Duration(days: 1))) &&
             transaction.date.isBefore(_selectedToDate.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _selectedFromDate : _selectedToDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _selectedFromDate = picked;
        } else {
          _selectedToDate = picked;
        }
        _filteredTransactions = _filterTransactionsByDate(_transactions);
      });
    }
  }

  void _shareStatement() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalCredit = _filteredTransactions.fold<double>(
      0, (sum, transaction) => sum + transaction.creditAmount);
    final totalReceipt = _filteredTransactions.fold<double>(
      0, (sum, transaction) => sum + transaction.receiptAmount);
    final balance = totalCredit - totalReceipt;

    final content = StringBuffer();
    content.writeln('Customer Statement');
    content.writeln('Customer: ${widget.customer.name}');
    content.writeln('Period: ${dateFormat.format(_selectedFromDate)} to ${dateFormat.format(_selectedToDate)}');
    content.writeln('');
    
    for (final transaction in _filteredTransactions) {
      content.writeln('Date: ${dateFormat.format(transaction.date)}');
      content.writeln('Invoice: ${transaction.invoiceNo}');
      content.writeln('Type: ${transaction.type.toString().split('.').last}');
      if (transaction.creditAmount > 0) {
        content.writeln('Credit: ₹${transaction.creditAmount.toStringAsFixed(2)}');
      }
      if (transaction.receiptAmount > 0) {
        content.writeln('Receipt: ₹${transaction.receiptAmount.toStringAsFixed(2)}');
      }
      content.writeln('Balance: ₹${transaction.balanceAmount.toStringAsFixed(2)}');
      content.writeln('---');
    }
    
    content.writeln('');
    content.writeln('Summary:');
    content.writeln('Total Credit: ₹${totalCredit.toStringAsFixed(2)}');
    content.writeln('Total Receipt: ₹${totalReceipt.toStringAsFixed(2)}');
    content.writeln('Balance: ₹${balance.toStringAsFixed(2)}');

    Share.share(content.toString(), subject: 'Customer Statement - ${widget.customer.name}');
  }

  @override
  Widget build(BuildContext context) {
    final totalCredit = _filteredTransactions.fold<double>(
      0, (sum, transaction) => sum + transaction.creditAmount);
    final totalReceipt = _filteredTransactions.fold<double>(
      0, (sum, transaction) => sum + transaction.receiptAmount);
    final balance = totalCredit - totalReceipt;

    return Scaffold(
      body: Column(
        children: [
          // Date Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Date Range',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedFromDate),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('to'),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedToDate),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions found for selected period',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
          ),
          // Summary Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Credit:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '₹${totalCredit.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Receipt:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '₹${totalReceipt.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '₹${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: balance > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _filteredTransactions.isNotEmpty
          ? FloatingActionButton(
              onPressed: _shareStatement,
              tooltip: 'Share Statement',
              child: const Icon(Icons.share),
            )
          : null,
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final typeStr = transaction.type.toString().split('.').last;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice number and type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.invoiceNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(typeStr).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getTypeColor(typeStr)),
                  ),
                  child: Text(
                    typeStr.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getTypeColor(typeStr),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Date and remarks
            Text(
              dateFormat.format(transaction.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (transaction.remarks?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  transaction.remarks!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (transaction.creditAmount > 0)
                      Text(
                        '₹ ${transaction.creditAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                      ),
                    if (transaction.receiptAmount > 0)
                      Text(
                        '₹ ${transaction.receiptAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Balance:',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '₹ ${transaction.balanceAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transaction.balanceAmount > 0 ? Colors.red : Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'sales':
      case 'credit':
        return Colors.blue;
      case 'receipt':
      case 'payment':
        return Colors.green;
      case 'return':
      case 'return_':
        return Colors.orange;
      case 'journal':
        return Colors.purple;
      case 'openingbalance':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

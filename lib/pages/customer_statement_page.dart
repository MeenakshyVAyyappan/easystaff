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
      final transactions = await CustomerService.getCustomerTransactions(widget.customer.id);
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
              child: const Icon(Icons.share),
              tooltip: 'Share Statement',
            )
          : null,
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
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
            if (transaction.remarks?.isNotEmpty == true)
              Text('Remarks: ${transaction.remarks}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (transaction.creditAmount > 0)
              Text(
                '₹${transaction.creditAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            if (transaction.receiptAmount > 0)
              Text(
                '₹${transaction.receiptAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            Text(
              '₹${transaction.balanceAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.balanceAmount > 0 ? Colors.red : Colors.green,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

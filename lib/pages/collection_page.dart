import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  DateTime _selectedFromDate = DateTime.now().subtract(
    const Duration(days: 30),
  );
  DateTime _selectedToDate = DateTime.now();
  List<CollectionEntry> _collections = [];
  List<CollectionEntry> _filteredCollections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final collections = await CustomerService.getCollections();
      setState(() {
        _collections = collections;
        _filteredCollections = _filterCollectionsByDate(collections);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collections: $e')),
        );
      }
    }
  }

  List<CollectionEntry> _filterCollectionsByDate(
    List<CollectionEntry> collections,
  ) {
    return collections.where((collection) {
      return collection.date.isAfter(
            _selectedFromDate.subtract(const Duration(days: 1)),
          ) &&
          collection.date.isBefore(
            _selectedToDate.add(const Duration(days: 1)),
          );
    }).toList();
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
        _filteredCollections = _filterCollectionsByDate(_collections);
      });
    }
  }

  void _shareCollections() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalAmount = _filteredCollections.fold<double>(
      0,
      (sum, collection) => sum + collection.amount,
    );

    final content = StringBuffer();
    content.writeln('Collection Report');
    content.writeln(
      'Period: ${dateFormat.format(_selectedFromDate)} to ${dateFormat.format(_selectedToDate)}',
    );
    content.writeln('Total Collections: ₹${totalAmount.toStringAsFixed(2)}');
    content.writeln('');

    for (final collection in _filteredCollections) {
      content.writeln('Date: ${dateFormat.format(collection.date)}');
      content.writeln('Amount: ₹${collection.amount.toStringAsFixed(2)}');
      content.writeln('Type: ${collection.type.toString().split('.').last}');
      content.writeln(
        'Payment: ${collection.paymentType.toString().split('.').last}',
      );
      if (collection.remarks?.isNotEmpty == true) {
        content.writeln('Remarks: ${collection.remarks}');
      }
      content.writeln('---');
    }

    Share.share(content.toString(), subject: 'Collection Report');
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _filteredCollections.fold<double>(
      0,
      (sum, collection) => sum + collection.amount,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Date Filter Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedFromDate),
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
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedToDate),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Total Amount
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Collections:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Collections List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCollections.isEmpty
                  ? const Center(
                      child: Text(
                        'No collections found for selected period',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCollections,
                      child: ListView.builder(
                        itemCount: _filteredCollections.length,
                        itemBuilder: (context, index) {
                          final collection = _filteredCollections[index];
                          return _buildCollectionCard(collection);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _filteredCollections.isNotEmpty
          ? FloatingActionButton(
              onPressed: _shareCollections,
              tooltip: 'Share Collections',
              child: const Icon(Icons.share),
            )
          : null,
    );
  }

  Widget _buildCollectionCard(CollectionEntry collection) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: collection.type == CollectionType.cash
              ? Colors.green[100]
              : Colors.blue[100],
          child: Icon(
            collection.type == CollectionType.cash
                ? Icons.money
                : Icons.account_balance,
            color: collection.type == CollectionType.cash
                ? Colors.green[700]
                : Colors.blue[700],
          ),
        ),
        title: Text(
          '₹${collection.amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${dateFormat.format(collection.date)}'),
            Text(
              'Type: ${collection.type.toString().split('.').last.toUpperCase()}',
            ),
            Text(
              'Payment: ${collection.paymentType.toString().split('.').last.toUpperCase()}',
            ),
            if (collection.chequeNo?.isNotEmpty == true)
              Text('Cheque: ${collection.chequeNo}'),
            if (collection.remarks?.isNotEmpty == true)
              Text('Remarks: ${collection.remarks}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Collected',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

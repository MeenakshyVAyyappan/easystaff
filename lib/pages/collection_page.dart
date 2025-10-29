import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';
import 'package:eazystaff/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  DateTime _selectedFromDate = DateTime.now().subtract(
    const Duration(days: 365),  // Changed from 30 to 365 days for wider range
  );
  DateTime _selectedToDate = DateTime.now();
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
      // Pass the selected date range to the API call
      final collections = await CustomerService.getCollections(
        startDate: _selectedFromDate,
        endDate: _selectedToDate,
      );
      setState(() {
        // Since we're getting filtered data from API based on date range,
        // we can use the collections directly
        _filteredCollections = collections;
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
      });

      // Reload collections from API with new date range
      await _loadCollections();
    }
  }

  void _shareCollections() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share Collections Report'),
          content: const Text('Choose how you want to share the collections report:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareCollectionsAsText();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.text_fields),
                  SizedBox(width: 8),
                  Text('Text'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareCollectionsAsPdf();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf),
                  SizedBox(width: 8),
                  Text('PDF'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _shareCollectionsAsText() {
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
      if (collection.customerName?.isNotEmpty == true) {
        content.writeln('Company: ${collection.customerName}');
      }
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

    Share.share(content.toString());
  }

  Future<void> _shareCollectionsAsPdf() async {
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
      await PdfService.generateAndShareCollectionsReport(
        collections: _filteredCollections,
        fromDate: _selectedFromDate,
        toDate: _selectedToDate,
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
            if (collection.customerName?.isNotEmpty == true)
              Text(
                'Company: ${collection.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
              ),
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

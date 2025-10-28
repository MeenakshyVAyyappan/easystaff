import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';

class StocksPage extends StatefulWidget {
  const StocksPage({super.key});

  @override
  State<StocksPage> createState() => _StocksPageState();
}

class _StocksPageState extends State<StocksPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Stock> _stocks = [];
  List<Stock> _filteredStocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStocks();
    _searchController.addListener(_filterStocks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stocks = await CustomerService.getStocks();
      setState(() {
        _stocks = stocks;
        _filteredStocks = stocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stocks: $e')),
        );
      }
    }
  }

  void _filterStocks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStocks = _stocks.where((stock) {
        return stock.productName.toLowerCase().contains(query) ||
               stock.category.toLowerCase().contains(query) ||
               stock.brand.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stocks'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product name, category, or brand...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          // Stock List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStocks.isEmpty
                    ? const Center(
                        child: Text(
                          'No stocks found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStocks,
                        child: ListView.builder(
                          itemCount: _filteredStocks.length,
                          itemBuilder: (context, index) {
                            final stock = _filteredStocks[index];
                            return _buildStockCard(stock);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Stock stock) {
    // Determine stock status color
    Color stockColor = Colors.green;
    String stockStatus = 'In Stock';
    
    if (stock.stockCount == 0) {
      stockColor = Colors.red;
      stockStatus = 'Out of Stock';
    } else if (stock.stockCount < 10) {
      stockColor = Colors.orange;
      stockStatus = 'Low Stock';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stockColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.inventory,
            color: stockColor,
          ),
        ),
        title: Text(
          stock.productName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${stock.category}'),
            Text('Brand: ${stock.brand}'),
            Text('Batch: ${stock.batchNo}'),
            Text('MRP: ₹${stock.mrp.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              stock.stockQty.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: stockColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: stockColor),
              ),
              child: Text(
                stockStatus,
                style: TextStyle(
                  color: stockColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          _showStockDetails(stock);
        },
      ),
    );
  }

  void _showStockDetails(Stock stock) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(stock.productName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Product ID', stock.productId),
              _buildDetailRow('Category', stock.category),
              _buildDetailRow('Brand', stock.brand),
              _buildDetailRow('Batch No', stock.batchNo),
              _buildDetailRow('MRP', '₹${stock.mrp.toStringAsFixed(2)}'),
              _buildDetailRow('Est. Stock', '${stock.estStock.toStringAsFixed(1)} units'),
              _buildDetailRow('Current Stock', '${stock.stockQty.toStringAsFixed(1)} units'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

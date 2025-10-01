import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  List<OrderItem> _orderItems = [];
  List<Stock> _stocks = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await CustomerService.getCustomers();
      final stocks = await CustomerService.getStocks();
      
      setState(() {
        _customers = customers;
        _stocks = stocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _addOrderItem() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Stock? selectedStock;
        final quantityController = TextEditingController();
        final priceController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Product'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Stock>(
                    value: selectedStock,
                    decoration: const InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                    ),
                    items: _stocks.map((stock) {
                      return DropdownMenuItem(
                        value: stock,
                        child: Text('${stock.productName} (${stock.stockCount} available)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStock = value;
                        priceController.text = value?.mrp.toString() ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedStock != null &&
                        quantityController.text.isNotEmpty &&
                        priceController.text.isNotEmpty) {
                      final quantity = int.tryParse(quantityController.text) ?? 0;
                      final price = double.tryParse(priceController.text) ?? 0;
                      
                      if (quantity > 0 && price > 0) {
                        setState(() {
                          _orderItems.add(OrderItem(
                            stock: selectedStock!,
                            quantity: quantity,
                            unitPrice: price,
                          ));
                        });
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  double get _totalAmount {
    return _orderItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate() && _selectedCustomer != null && _orderItems.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate order submission
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales order placed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedCustomer = null;
          _orderItems.clear();
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select customer and add at least one product'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Order'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Customer Selection
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'Select Customer *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer,
                    child: Text('${customer.name} (${customer.areaName})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomer = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a customer';
                  }
                  return null;
                },
              ),
            ),
            // Order Items
            Expanded(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addOrderItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  ),
                  // Items List
                  Expanded(
                    child: _orderItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No products added yet\nTap "Add Product" to start',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _orderItems.length,
                            itemBuilder: (context, index) {
                              final item = _orderItems[index];
                              return _buildOrderItemCard(item, index);
                            },
                          ),
                  ),
                ],
              ),
            ),
            // Total and Submit
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
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          item.stock.productName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${item.quantity}'),
            Text('Unit Price: ₹${item.unitPrice.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeOrderItem(index),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderItem {
  final Stock stock;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.stock,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}

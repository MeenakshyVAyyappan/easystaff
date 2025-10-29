import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';

/// ---------- Responsive helpers ----------
extension ResponsiveX on BuildContext {
  double get sw => MediaQuery.of(this).size.width;
  double get sh => MediaQuery.of(this).size.height;

  bool get isTablet => sw >= 900;
  bool get isLargePhone => sw >= 600 && sw < 900;
  bool get isPhone => sw < 600;

  double r(double phone, {double? largePhone, double? tablet}) {
    if (isTablet) return tablet ?? largePhone ?? phone;
    if (isLargePhone) return largePhone ?? phone;
    return phone;
  }

  double get basePad => r(12, largePhone: 16, tablet: 24);
  double get fieldPadV => r(10, largePhone: 12, tablet: 14);
  double get fieldPadH => r(12, largePhone: 14, tablet: 16);
  double get corner => r(6, largePhone: 8, tablet: 10);
  double get actionBtnH => r(44, largePhone: 50, tablet: 54);
  double get titleSize => r(16, largePhone: 18, tablet: 20);
  double get labelSize => r(12, largePhone: 13, tablet: 14);
  double get bodySize => r(14, largePhone: 15, tablet: 16);
}

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
    setState(() => _isLoading = true);
    try {
      final customers = await CustomerService.getCustomers();
      final stocks = await CustomerService.getStocks();
      setState(() {
        _customers = customers;
        _stocks = stocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

void _addOrderItem() {
  // Guard: empty stock list
  if (_stocks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No products available. Please wait for data to load.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Declare variables outside showDialog so they persist
  Stock? selectedStock;
  final quantityController = TextEditingController();
  final priceController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      final media = MediaQuery.of(dialogCtx);
      final maxWidth  = media.size.width >= 600 ? 520.0 : media.size.width * 0.96;
      final maxHeight = (media.size.height - media.viewInsets.bottom) * 0.85;

      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isNarrow = MediaQuery.of(ctx).size.width < 360;

          return AlertDialog(
            title: const Text('Add Product'),
            scrollable: true, // <-- lets content scroll when tight
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Stock>(
                      value: selectedStock,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Product *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _stocks.map((stock) {
                        return DropdownMenuItem(
                          value: stock,
                          child: Text(
                            '${stock.productName} (${stock.stockCount} available)',
                            overflow: TextOverflow.ellipsis,
                          ),
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

                    // Qty / Price fields: stack on very narrow screens
                    if (isNarrow) ...[
                      TextFormField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Unit Price',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: false),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Unit Price',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedStock != null &&
                      quantityController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;

                    if (quantity > 0 && price > 0) {
                      Navigator.of(dialogCtx).pop();
                      setState(() {
                        _orderItems.add(OrderItem(
                          stock: selectedStock!,
                          quantity: quantity,
                          unitPrice: price,
                        ));
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid quantity and price'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    });
}


  void _removeOrderItem(int index) => setState(() => _orderItems.removeAt(index));

  double get _totalAmount =>
      _orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate() &&
        _selectedCustomer != null &&
        _orderItems.isNotEmpty) {
      setState(() => _isSubmitting = true);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sales order placed successfully'), backgroundColor: Colors.green),
      );
      setState(() {
        _selectedCustomer = null;
        _orderItems.clear();
      });
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Order'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Top section (Customer)
              Padding(
                padding: EdgeInsets.all(context.basePad),
                child: DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select Customer *',
                    labelStyle: TextStyle(fontSize: context.bodySize),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.fieldPadH, vertical: context.fieldPadV),
                  ),
                  items: _customers.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(
                        '${c.name} (${c.areaName})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.bodySize),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCustomer = v),
                  validator: (v) => v == null ? 'Please select a customer' : null,
                ),
              ),

              // Header row (Order Items + Add)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.basePad)
                    .copyWith(bottom: context.basePad * 0.5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: context.titleSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addOrderItem,
                      icon: const Icon(Icons.add, size: 16),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.basePad, vertical: context.basePad * 0.5),
                        minimumSize: const Size(0, 36),
                      ),
                      label: Text('Add', style: TextStyle(fontSize: context.labelSize)),
                    ),
                  ],
                ),
              ),

              // List (fills remaining space, always scrollable if needed)
              Expanded(
                child: _orderItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(context.basePad),
                          child: Text(
                            'No products added yet\nTap "Add" to start',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: context.bodySize, color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: context.basePad),
                        itemCount: _orderItems.length,
                        itemBuilder: (c, i) => _buildOrderItemCard(context, _orderItems[i], i),
                      ),
              ),

              // Bottom total + submit (fixed)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  context.basePad,
                  context.basePad * 0.75,
                  context.basePad,
                  context.basePad + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount:',
                            style: TextStyle(
                              fontSize: context.titleSize,
                              fontWeight: FontWeight.bold,
                            )),
                        Text(
                          '₹${_totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: context.titleSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.basePad * 0.75),
                    SizedBox(
                      width: double.infinity,
                      height: context.actionBtnH,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.corner),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : Text('Place Order',
                                style: TextStyle(
                                  fontSize: context.r(14, largePhone: 15, tablet: 16),
                                  fontWeight: FontWeight.w600,
                                )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(BuildContext context, OrderItem item, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: context.basePad * 0.5),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(context.basePad * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + delete
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.stock.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: context.r(14, largePhone: 15, tablet: 16),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => _removeOrderItem(index),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
            SizedBox(height: context.basePad * 0.5),
            // Qty / Unit / Total
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Wrap(
                    spacing: context.basePad * 0.75,
                    runSpacing: context.basePad * 0.25,
                    children: [
                      Text('Qty: ${item.quantity}',
                          style: TextStyle(color: Colors.grey[600], fontSize: context.labelSize)),
                      Text('Unit: ₹${item.unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: context.labelSize)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total',
                          style: TextStyle(fontSize: context.r(10, largePhone: 11, tablet: 12), color: Colors.grey)),
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.r(14, largePhone: 15, tablet: 16),
                          color: Colors.green,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
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

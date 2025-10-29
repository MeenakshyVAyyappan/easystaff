import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/customer_service.dart';
import 'models/customer.dart';

class DebugCustomerDataPage extends StatefulWidget {
  const DebugCustomerDataPage({Key? key}) : super(key: key);

  @override
  State<DebugCustomerDataPage> createState() => _DebugCustomerDataPageState();
}

class _DebugCustomerDataPageState extends State<DebugCustomerDataPage> {
  List<Customer> customers = [];
  bool isLoading = false;
  String debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      isLoading = true;
      debugInfo = 'Loading customers...';
    });

    try {
      final loadedCustomers = await CustomerService.getCustomers();
      
      String info = '=== ORIGINAL CUSTOMER DATA FROM API ===\n';
      info += 'Total customers loaded: ${loadedCustomers.length}\n';
      info += 'NO DEDUPLICATION - Showing exact API data\n\n';

      for (int i = 0; i < loadedCustomers.length && i < 15; i++) {
        final customer = loadedCustomers[i];
        info += 'Customer ${i + 1}:\n';
        info += '  Name: ${customer.name}\n';
        info += '  ID: "${customer.id}"\n';
        info += '  Balance: ₹${customer.balanceAmount.toStringAsFixed(2)}\n';
        info += '  Area: ${customer.areaName}\n';
        info += '\n';
      }
      
      if (loadedCustomers.length > 10) {
        info += '... and ${loadedCustomers.length - 10} more customers\n';
      }

      setState(() {
        customers = loadedCustomers;
        debugInfo = info;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        debugInfo = 'Error loading customers: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _testCustomerStatement(Customer customer) async {
    if (customer.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer ID is empty - cannot test statement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Testing statement for ${customer.name}...'),
          backgroundColor: Colors.blue,
        ),
      );

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      
      final transactions = await CustomerService.getCustomerStatement(
        customerId: customer.id,
        financialYearId: '2', // Use default financial year
        startDate: startDate,
        endDate: endDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${transactions.length} transactions for ${customer.name}'),
          backgroundColor: transactions.isEmpty ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing statement: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Customer Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug info section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug Information:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  Text(
                    debugInfo,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
              ],
            ),
          ),
          
          // Customer list section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : customers.isEmpty
                    ? const Center(child: Text('No customers found'))
                    : ListView.builder(
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          final hasValidId = customer.id.trim().isNotEmpty;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasValidId ? Colors.green : Colors.red,
                                child: Text(
                                  customer.name.isNotEmpty ? customer.name[0] : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(customer.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: "${customer.id}" (${customer.id.length} chars)'),
                                  Text('Area: ${customer.areaName}'),
                                  Text('Balance: ₹${customer.balanceAmount.toStringAsFixed(2)}'),
                                ],
                              ),
                              trailing: hasValidId
                                  ? ElevatedButton(
                                      onPressed: () => _testCustomerStatement(customer),
                                      child: const Text('Test'),
                                    )
                                  : const Icon(Icons.error, color: Colors.red),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

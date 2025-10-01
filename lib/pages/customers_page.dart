import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';
import 'package:eazystaff/pages/customer_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedArea = 'All Areas';
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  List<String> _areas = ['All Areas'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await CustomerService.getCustomers();
      final areas = customers.map((c) => c.areaName).toSet().toList();
      areas.sort();

      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _areas = ['All Areas', ...areas];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading customers: $e')));
      }
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        final matchesSearch =
            customer.name.toLowerCase().contains(query) ||
            customer.areaName.toLowerCase().contains(query);
        final matchesArea =
            _selectedArea == 'All Areas' || customer.areaName == _selectedArea;
        return matchesSearch && matchesArea;
      }).toList();
    });
  }

  void _onAreaChanged(String? area) {
    setState(() {
      _selectedArea = area ?? 'All Areas';
    });
    _filterCustomers();
  }

  Future<void> _makeCall(Customer customer) async {
    if (customer.mobileNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mobile number available')),
      );
      return;
    }

    if (customer.mobileNumbers.length == 1) {
      final url = Uri.parse('tel:${customer.mobileNumbers.first}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } else {
      _showMobileNumberDialog(customer);
    }
  }

  void _showMobileNumberDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Mobile Number for ${customer.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: customer.mobileNumbers.map((number) {
              return ListTile(
                leading: const Icon(Icons.phone),
                title: Text(number),
                onTap: () async {
                  Navigator.of(context).pop();
                  final url = Uri.parse('tel:$number');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openWhatsApp(Customer customer) async {
    final whatsappNumber =
        customer.whatsappNumber ??
        (customer.mobileNumbers.isNotEmpty
            ? customer.mobileNumbers.first
            : null);

    if (whatsappNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No WhatsApp number available')),
      );
      return;
    }

    // Pre-filled message for WhatsApp
    final message = Uri.encodeComponent(
      'Hello ${customer.name}, I am contacting you regarding your account. How can I assist you today?'
    );

    final url = Uri.parse('https://wa.me/$whatsappNumber?text=$message');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to basic WhatsApp URL without message
        final basicUrl = Uri.parse('https://wa.me/$whatsappNumber');
        if (await canLaunchUrl(basicUrl)) {
          await launchUrl(basicUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('WhatsApp is not installed on this device')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening WhatsApp: $e')),
        );
      }
    }
  }

  void _showCustomerOptions(Customer customer) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                customer.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location'),
                onTap: () {
                  Navigator.pop(context);
                  _handleLocation(customer);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Customer Statement'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerDetailPage(customer: customer, initialTab: 0),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Credit Age Report'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerDetailPage(customer: customer, initialTab: 1),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Collection Entry'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerDetailPage(customer: customer, initialTab: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLocation(Customer customer) {
    if (customer.locationSet) {
      // Show location on map
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening location for ${customer.name}'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // TODO: Open map with customer location
            },
          ),
        ),
      );
    } else {
      // Ask to set location
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Set Customer Location'),
            content: Text(
              'Location not set for ${customer.name}. Would you like to set it now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement location setting
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location setting feature coming soon'),
                    ),
                  );
                },
                child: const Text('Set Location'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[50]!, Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search and Filter Row
                Row(
                  children: [
                    // Search Box (Left)
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search customers...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.blue[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Area Filter (Right)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          DropdownButton<String>(
                            value: _selectedArea,
                            onChanged: _onAreaChanged,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            underline: Container(),
                            items: _areas.map((String area) {
                              return DropdownMenuItem<String>(
                                value: area,
                                child: Text(
                                  area.length > 8
                                      ? '${area.substring(0, 8)}...'
                                      : area,
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                ? const Center(
                    child: Text(
                      'No customers found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCustomers,
                    child: ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return _buildCustomerCard(customer);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return GestureDetector(
      onTap: () => _showCustomerOptions(customer),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Customer Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    customer.name
                        .split(' ')
                        .map((e) => e[0])
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Customer Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.areaName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: customer.balanceAmount > 0
                            ? Colors.red[100]
                            : Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Balance: ₹${customer.balanceAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: customer.balanceAmount > 0
                              ? Colors.red[700]
                              : Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => _makeCall(customer),
                      tooltip: 'Call',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chat,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => _openWhatsApp(customer),
                      tooltip: 'WhatsApp',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

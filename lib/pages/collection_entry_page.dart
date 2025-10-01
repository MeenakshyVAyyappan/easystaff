import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';
import 'package:intl/intl.dart';

class CollectionEntryPage extends StatefulWidget {
  final Customer customer;

  const CollectionEntryPage({super.key, required this.customer});

  @override
  State<CollectionEntryPage> createState() => _CollectionEntryPageState();
}

class _CollectionEntryPageState extends State<CollectionEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _chequeNoController = TextEditingController();
  final _remarksController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedChequeDate;
  CollectionType _selectedType = CollectionType.cash;
  PaymentType _selectedPaymentType = PaymentType.cash;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _chequeNoController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isChequeDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isChequeDate ? (_selectedChequeDate ?? DateTime.now()) : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isChequeDate) {
          _selectedChequeDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  Future<void> _submitCollection() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final collection = CollectionEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: widget.customer.id,
          date: _selectedDate,
          amount: double.parse(_amountController.text),
          type: _selectedType,
          paymentType: _selectedPaymentType,
          chequeNo: _chequeNoController.text.isNotEmpty ? _chequeNoController.text : null,
          chequeDate: _selectedChequeDate,
          remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
        );

        final success = await CustomerService.addCollectionEntry(collection);

        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Collection entry added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _resetForm();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add collection entry'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _resetForm() {
    _amountController.clear();
    _chequeNoController.clear();
    _remarksController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedChequeDate = null;
      _selectedType = CollectionType.cash;
      _selectedPaymentType = PaymentType.cash;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collection Entry for:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.customer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Balance: ₹${widget.customer.balanceAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: widget.customer.balanceAmount > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Collection Date
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collection Date',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Text(dateFormat.format(_selectedDate)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter valid amount';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Collection Type
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collection Type',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<CollectionType>(
                              title: const Text('Cash'),
                              value: CollectionType.cash,
                              groupValue: _selectedType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<CollectionType>(
                              title: const Text('Bank'),
                              value: CollectionType.bank,
                              groupValue: _selectedType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Type
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Type',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<PaymentType>(
                        value: _selectedPaymentType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: PaymentType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toString().split('.').last.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cheque Details (if payment type is cheque)
              if (_selectedPaymentType == PaymentType.cheque) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cheque Details',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _chequeNoController,
                          decoration: const InputDecoration(
                            labelText: 'Cheque Number',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_selectedPaymentType == PaymentType.cheque && 
                                (value == null || value.isEmpty)) {
                              return 'Please enter cheque number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedChequeDate != null
                                      ? 'Cheque Date: ${dateFormat.format(_selectedChequeDate!)}'
                                      : 'Select Cheque Date',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Remarks
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _remarksController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Remarks (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCollection,
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
                          'Add Collection Entry',
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
      ),
    );
  }
}

import 'package:flutter/material.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = List.generate(
      12,
      (i) => {
        'number': 'INV-${1000 + i}',
        'customer': 'Customer ${i + 1}',
        'amount': '₹${(i + 1) * 1200}',
        'status': i.isEven ? 'Paid' : 'Due',
      },
    );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final inv = invoices[i];
        final isPaid = inv['status'] == 'Paid';
        return Card(
          child: ListTile(
            title: Text('${inv['number']} • ${inv['customer']}'),
            subtitle: Text('${inv['status']} • ${inv['amount']}'),
            leading: CircleAvatar(
              backgroundColor: isPaid ? Colors.green : Colors.orange,
              child: Icon(
                isPaid ? Icons.check : Icons.schedule,
                color: Colors.white,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {},
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}

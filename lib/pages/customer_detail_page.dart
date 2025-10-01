import 'package:flutter/material.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/pages/customer_statement_page.dart';
import 'package:eazystaff/pages/credit_age_report_page.dart';
import 'package:eazystaff/pages/collection_entry_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  final int initialTab;

  const CustomerDetailPage({
    super.key,
    required this.customer,
    this.initialTab = 0,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Statement', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Credit Age', icon: Icon(Icons.schedule)),
            Tab(text: 'Collection', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CustomerStatementPage(customer: widget.customer),
          CreditAgeReportPage(customer: widget.customer),
          CollectionEntryPage(customer: widget.customer),
        ],
      ),
    );
  }
}

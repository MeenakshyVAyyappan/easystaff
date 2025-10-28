// lib/dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eazystaff/services/auth_service.dart';
import 'package:eazystaff/services/dashboard_service.dart';
import 'package:eazystaff/utilitis/location_helper.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardData? _data;
  bool _loading = true;
  String _location = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final saved = await AuthService.loadLocation() ?? '';
    setState(() => _location = saved);
    await _loadDashboard();
  }

  void _onDateRangeChanged(DateTime startDate, DateTime endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    _loadDashboard(); // Reload dashboard with new date range
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    final u = AuthService.currentUser;
    if (u == null) {
      setState(() => _loading = false);
      return;
    }

    // Based on your Postman example, use empid: 2
    // For WF-01 employee, the empid should be 2
    String empId = '2'; // Default for WF-01 employee

    // If you have a specific employee ID mapping, use it
    if (u.employeeId.isNotEmpty && u.employeeId != 'WF-01') {
      empId = u.employeeId;
    }

    if (kDebugMode) {
      debugPrint('=== DASHBOARD LOAD DEBUG ===');
      debugPrint('User: ${u.username}');
      debugPrint('Office Code: ${u.officeCode}');
      debugPrint('Office ID: ${u.officeId}');
      debugPrint('Financial Year ID: ${u.financialYearId}');
      debugPrint('Employee ID: $empId');
      debugPrint('=== END DASHBOARD LOAD DEBUG ===');
    }

    try {
      final d = await DashboardService.fetchDashboard(
        empId: empId,
        officeCode: u.officeCode,
        officeId: u.officeId,
        financialYearId: u.financialYearId,
        savedLocation: _location,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard: $e')),
      );
    }
  }

  Future<void> _onEnableLocation() async {
    final ok = await LocationHelper.ensurePermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied.')),
      );
      return;
    }
    try {
      final addr = await LocationHelper.getPrettyAddress();
      if (addr != null) {
        await AuthService.saveLocation(addr);
        setState(() {
          _location = addr;
          if (_data != null) {
            _data = DashboardData(
              displayName: _data!.displayName,
              designation: _data!.designation,
              department: _data!.department,
              officeCode: _data!.officeCode,
              savedLocation: addr,
              monthCollections: _data!.monthCollections,
              monthCustomers: _data!.monthCustomers,
              monthVisits: _data!.monthVisits,
              pendingAmount: _data!.pendingAmount,
              todays: _data!.todays,
            );
          }
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location saved: $addr')),
        );

        // If you later get a “save location” API, call it here.
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to get location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_data == null) {
      return const Center(child: Text('No data'));
    }

    final d = _data!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1) User card (purple gradient)
          _NewUserCard(
            name: d.displayName.isNotEmpty ? d.displayName : 'User',
            designation: d.designation,
            department: d.department,
            officeCode: d.officeCode,
          ),

          const SizedBox(height: 16),

          // 2) Enable location card (orange)
          _NewLocationCard(
            isEnabled: d.savedLocation.isNotEmpty,
            address: d.savedLocation,
            onEnable: _onEnableLocation,
          ),

          const SizedBox(height: 16),

          // 3) Date Range Filter
          _DateRangeFilter(
            startDate: _startDate,
            endDate: _endDate,
            onDateRangeChanged: _onDateRangeChanged,
          ),

          const SizedBox(height: 16),

          // 4) Current month summary (purple) - Collections and Pending Amount only
          _NewMonthSummary(
            collections: d.monthCollections,
            pendingAmount: d.pendingAmount,
          ),

          const SizedBox(height: 16),

          // 4) Today’s transactions (green)
          _NewTodayTransactions(list: d.todays),
        ],
      ),
    );
  }
}

// ------- New UI widgets matching the target design -------

class _DateRangeFilter extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const _DateRangeFilter({
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != startDate) {
      onDateRangeChanged(picked, endDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != endDate) {
      onDateRangeChanged(startDate, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectStartDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(startDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('to', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectEndDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(endDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewUserCard extends StatelessWidget {
  final String name, designation, department, officeCode;
  const _NewUserCard({
    required this.name,
    required this.designation,
    required this.department,
    required this.officeCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              _initials(name),
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (designation.isNotEmpty)
                  Text(
                    designation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    return ((parts.first[0]) + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}

class _NewLocationCard extends StatelessWidget {
  final bool isEnabled;
  final String address;
  final VoidCallback onEnable;
  const _NewLocationCard({required this.isEnabled, required this.address, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Location Access',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled ? address : 'Required for attendance tracking',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onEnable,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isEnabled ? 'Update' : 'Enable'),
          ),
        ],
      ),
    );
  }
}

class _NewMonthSummary extends StatelessWidget {
  final double collections;
  final double pendingAmount;
  const _NewMonthSummary({required this.collections, required this.pendingAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.purple.shade500,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('₹${collections.toStringAsFixed(2)}', 'Collections'),
          _buildStatColumn('₹${pendingAmount.toStringAsFixed(2)}', 'Pending Amount'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _NewTodayTransactions extends StatelessWidget {
  final List<TodayTxn> list;
  const _NewTodayTransactions({required this.list});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.teal.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Today\'s Transactions',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Text(
                'No transactions today',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            )
          else
            ...list.map((t) => Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(t.party),
                    subtitle: t.time.isNotEmpty ? Text(t.time) : null,
                    trailing: Text(
                      '₹${t.amount}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

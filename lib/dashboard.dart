// lib/dashboard.dart
import 'package:flutter/material.dart';
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

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    final u = AuthService.currentUser;
    if (u == null) {
      setState(() => _loading = false);
      return;
    }

    // API needs empid — use employeeId if you have it, else fallback to username
    final empId = (u.employeeId.isNotEmpty) ? u.employeeId : u.username;

    try {
      final d = await DashboardService.fetchDashboard(
        empId: empId,
        savedLocation: _location,
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
    // ---- Replace the hard-coded tiles with these dynamic values ----

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 1) User card (violet)
          _UserCard(
            name: d.displayName.isNotEmpty ? d.displayName : 'User',
            designation: d.designation,
            department: d.department,
            officeCode: d.officeCode,
            location: d.savedLocation, // show saved (local) location
          ),

          const SizedBox(height: 12),

          // 2) Enable location card (orange)
          _LocationCard(
            isEnabled: d.savedLocation.isNotEmpty,
            address: d.savedLocation,
            onEnable: _onEnableLocation,
          ),

          const SizedBox(height: 12),

          // 3) Current month summary (purple)
          _MonthSummary(
            collections: d.monthCollections,
            customers: d.monthCustomers,
            visits: d.monthVisits,
          ),

          const SizedBox(height: 12),

          // 4) Today’s transactions (green)
          _TodayTransactions(list: d.todays),
        ],
      ),
    );
  }
}

// ------- UI widgets (simple, bind to your existing design) -------

class _UserCard extends StatelessWidget {
  final String name, designation, department, officeCode, location;
  const _UserCard({
    required this.name,
    required this.designation,
    required this.department,
    required this.officeCode,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple.shade400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Text(
                _initials(name),
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (designation.isNotEmpty || department.isNotEmpty)
                      Text('${designation}${designation.isNotEmpty && department.isNotEmpty ? ' • ' : ''}${department}',
                          style: const TextStyle(color: Colors.white70)),
                    if (officeCode.isNotEmpty)
                      Text('Office: $officeCode', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Flexible(child: Text(location, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    return ((parts.first[0]) + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}

class _LocationCard extends StatelessWidget {
  final bool isEnabled;
  final String address;
  final VoidCallback onEnable;
  const _LocationCard({required this.isEnabled, required this.address, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(isEnabled ? 'Location Enabled' : 'Enable Location Access',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          isEnabled
              ? address
              : 'Required for attendance tracking',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: ElevatedButton(
          onPressed: onEnable,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.orange),
          child: Text(isEnabled ? 'Update' : 'Enable'),
        ),
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  final int collections, customers, visits;
  const _MonthSummary({required this.collections, required this.customers, required this.visits});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.purple.shade400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _pill('Collections', '₹$collections'),
            _pill('Customers', '$customers'),
            _pill('Visits', '$visits'),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _TodayTransactions extends StatelessWidget {
  final List<TodayTxn> list;
  const _TodayTransactions({required this.list});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.teal.shade400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const ListTile(
            title: Text('Today\'s Transactions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ...list.map((t) => Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(t.party),
                  subtitle: t.time.isNotEmpty ? Text(t.time) : null,
                  trailing: Text('₹${t.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('No transactions today', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
    );
  }
}

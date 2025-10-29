// lib/dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eazystaff/services/auth_service.dart';
import 'package:eazystaff/services/dashboard_service.dart';
import 'package:eazystaff/utilitis/location_helper.dart';
import 'package:eazystaff/pages/location_management_page.dart';


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

    // Based on your test data, use empid: 4 for collections
    // Use empid: 4 as fallback to match the test data
    String empId = u.employeeId.isNotEmpty ? u.employeeId : '4';

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
    // Navigate to the location management page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationManagementPage(),
      ),
    );
    
    // If location was updated, refresh the dashboard
    if (result == true) {
      final savedLocation = await AuthService.loadLocation() ?? '';
      setState(() => _location = savedLocation);
      await _loadDashboard();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: Colors.black54,
              size: isTablet ? 28 : 24,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: isLargeScreen
          ? _buildLargeScreenLayout(d)
          : _buildMobileLayout(d),
      ),
    );
  }

  Widget _buildMobileLayout(DashboardData d) {
    final u = AuthService.currentUser;
    return Column(
      children: [
        // 1) User card - Light purple with office tag
        _NewUserCard(
          name: u?.name.isNotEmpty == true ? u!.name : 'User',
          designation: u?.designation.isNotEmpty == true ? u!.designation : 'Employee',
          department: u?.department.isNotEmpty == true ? u!.department : 'Department',
          officeCode: u?.officeCode.isNotEmpty == true ? u!.officeCode : 'Office',
        ),

        const SizedBox(height: 16),

        // 2) Location card - White with green checkmark
        _NewLocationCard(
          isEnabled: d.savedLocation.isNotEmpty,
          address: d.savedLocation,
          onEnable: _onEnableLocation,
        ),

        const SizedBox(height: 16),

        // 3) Collection Summary Header
        _CollectionSummaryHeader(),

        const SizedBox(height: 16),

        // 4) Date Range Filter
        _DateRangeFilter(
          startDate: _startDate,
          endDate: _endDate,
          onDateRangeChanged: _onDateRangeChanged,
        ),

        const SizedBox(height: 16),

        // 5) Summary Cards - Collected and Pending
        _SummaryCards(
          collected: d.monthCollections,
          pending: d.pendingAmount,
        ),

        const SizedBox(height: 16),

        // 6) Recent Collections
        _RecentCollections(list: d.todays),
      ],
    );
  }

  Widget _buildLargeScreenLayout(DashboardData d) {
    final u = AuthService.currentUser;
    return Column(
      children: [
        // Top row: User card and Location card
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _NewUserCard(
                name: u?.name.isNotEmpty == true ? u!.name : 'User',
                designation: u?.designation.isNotEmpty == true ? u!.designation : 'Employee',
                department: u?.department.isNotEmpty == true ? u!.department : 'Department',
                officeCode: u?.officeCode.isNotEmpty == true ? u!.officeCode : 'Office',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _NewLocationCard(
                isEnabled: d.savedLocation.isNotEmpty,
                address: d.savedLocation,
                onEnable: _onEnableLocation,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Collection Summary Header
        _CollectionSummaryHeader(),

        const SizedBox(height: 16),

        // Middle row: Date filter and Summary cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _DateRangeFilter(
                startDate: _startDate,
                endDate: _endDate,
                onDateRangeChanged: _onDateRangeChanged,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _SummaryCards(
                collected: d.monthCollections,
                pending: d.pendingAmount,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Bottom: Recent Collections (full width)
        _RecentCollections(list: d.todays),
      ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: isTablet ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Date Range',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          isSmallScreen
            ? _buildVerticalDateInputs(context, isTablet)
            : _buildHorizontalDateInputs(context, isTablet),
        ],
      ),
    );
  }

  Widget _buildHorizontalDateInputs(BuildContext context, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _buildDateInput(
            context,
            startDate,
            () => _selectStartDate(context),
            isTablet,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
          child: Text(
            'to',
            style: TextStyle(
              color: Colors.grey,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ),
        Expanded(
          child: _buildDateInput(
            context,
            endDate,
            () => _selectEndDate(context),
            isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDateInputs(BuildContext context, bool isTablet) {
    return Column(
      children: [
        _buildDateInput(
          context,
          startDate,
          () => _selectStartDate(context),
          isTablet,
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          'to',
          style: TextStyle(
            color: Colors.grey,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        _buildDateInput(
          context,
          endDate,
          () => _selectEndDate(context),
          isTablet,
        ),
      ],
    );
  }

  Widget _buildDateInput(BuildContext context, DateTime date, VoidCallback onTap, bool isTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 12 : 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: isTablet ? 20 : 16,
              color: Colors.grey.shade600,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                _formatDate(date),
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
            ),
          ],
        ),
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

  // Helper function to generate initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E3F3), // Light purple/lavender background
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: isSmallScreen
        ? _buildVerticalLayout(isTablet)
        : _buildHorizontalLayout(isTablet),
    );
  }

  Widget _buildHorizontalLayout(bool isTablet) {
    return Row(
      children: [
        // Circular avatar with user initials
        Container(
          width: isTablet ? 64 : 48,
          height: isTablet ? 64 : 48,
          decoration: BoxDecoration(
            color: const Color(0xFF9C88D4), // Purple background for avatar
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getInitials(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 20 : 16,
              ),
            ),
          ),
        ),
        SizedBox(width: isTablet ? 20 : 16),
        Expanded(
          child: _buildUserInfo(isTablet),
        ),
        // User icon on the right
        Icon(
          Icons.person,
          color: const Color(0xFF9C88D4),
          size: isTablet ? 32 : 24,
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(bool isTablet) {
    return Column(
      children: [
        Row(
          children: [
            // Circular avatar with user initials
            Container(
              width: isTablet ? 64 : 48,
              height: isTablet ? 64 : 48,
              decoration: BoxDecoration(
                color: const Color(0xFF9C88D4), // Purple background for avatar
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(name),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 20 : 16,
                  ),
                ),
              ),
            ),
            const Spacer(),
            // User icon on the right
            Icon(
              Icons.person,
              color: const Color(0xFF9C88D4),
              size: isTablet ? 32 : 24,
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        _buildUserInfo(isTablet),
      ],
    );
  }

  Widget _buildUserInfo(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: Colors.black87,
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isTablet ? 4 : 2),
        Text(
          '$designation • $department',
          style: TextStyle(
            color: Colors.black54,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        SizedBox(height: isTablet ? 4 : 2),
        Text(
          'ID: $officeCode • bhg',
          style: TextStyle(
            color: Colors.black54,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        // Office tag
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50), // Green background
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white,
                size: isTablet ? 18 : 14,
              ),
              SizedBox(width: isTablet ? 6 : 4),
              Text(
                'BHG Office',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewLocationCard extends StatelessWidget {
  final bool isEnabled;
  final String address;
  final VoidCallback onEnable;
  const _NewLocationCard({required this.isEnabled, required this.address, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: isSmallScreen
        ? _buildVerticalLayout(isTablet)
        : _buildHorizontalLayout(isTablet),
    );
  }

  Widget _buildHorizontalLayout(bool isTablet) {
    return Row(
      children: [
        // Green location icon
        Container(
          width: isTablet ? 56 : 40,
          height: isTablet ? 56 : 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on,
            color: Colors.white,
            size: isTablet ? 28 : 20,
          ),
        ),
        SizedBox(width: isTablet ? 20 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationInfo(isTablet),
              SizedBox(height: isTablet ? 12 : 8),
              _buildLocationButton(isTablet),
            ],
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        // Status indicator
        Container(
          width: isTablet ? 40 : 32,
          height: isTablet ? 40 : 32,
          decoration: BoxDecoration(
            color: isEnabled ? const Color(0xFF4CAF50) : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isEnabled ? Icons.check : Icons.location_off,
            color: Colors.white,
            size: isTablet ? 22 : 18,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(bool isTablet) {
    return Column(
      children: [
        Row(
          children: [
            // Green location icon
            Container(
              width: isTablet ? 56 : 40,
              height: isTablet ? 56 : 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.white,
                size: isTablet ? 28 : 20,
              ),
            ),
            const Spacer(),
            // Green checkmark
            Container(
              width: isTablet ? 40 : 32,
              height: isTablet ? 40 : 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: isTablet ? 22 : 18,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        _buildLocationInfo(isTablet),
        SizedBox(height: isTablet ? 12 : 8),
        _buildLocationButton(isTablet),
      ],
    );
  }

  Widget _buildLocationButton(bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onEnable,
        icon: Icon(
          isEnabled ? Icons.edit_location : Icons.add_location,
          size: isTablet ? 18 : 16,
        ),
        label: Text(
          isEnabled ? 'Update Location' : 'Set Location',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 12 : 10,
            horizontal: isTablet ? 16 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnabled ? 'Location Access Enabled' : 'Location Access Disabled',
          style: TextStyle(
            color: isEnabled ? Colors.black87 : Colors.black54,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isTablet ? 6 : 4),
        Text(
          isEnabled
            ? (address.isNotEmpty
                ? 'Current: ${address.length > 50 ? '${address.substring(0, 50)}...' : address}'
                : 'Location tracking is active for attendance')
            : 'Tap to set your location for attendance tracking',
          style: TextStyle(
            color: Colors.black54,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

// Collection Summary Header
class _CollectionSummaryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3), // Blue background
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            ),
            child: Icon(
              Icons.folder,
              color: Colors.white,
              size: isTablet ? 28 : 20,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Text(
            'Collection Summary',
            style: TextStyle(
              color: const Color(0xFF2196F3),
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Summary Cards for Collected and Pending amounts
class _SummaryCards extends StatelessWidget {
  final double collected;
  final double pending;

  const _SummaryCards({
    required this.collected,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 500;

    return isSmallScreen
      ? _buildVerticalLayout(isTablet)
      : _buildHorizontalLayout(isTablet);
  }

  Widget _buildHorizontalLayout(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            collected,
            'Collected',
            const Color(0xFFE8F5E8), // Light green background
            const Color(0xFF4CAF50),
            Icons.check,
            isTablet,
          ),
        ),
        SizedBox(width: isTablet ? 20 : 16),
        Expanded(
          child: _buildSummaryCard(
            pending,
            'Pending',
            const Color(0xFFFFF3E0), // Light orange background
            const Color(0xFFFF9800),
            Icons.access_time,
            isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(bool isTablet) {
    return Column(
      children: [
        _buildSummaryCard(
          collected,
          'Collected',
          const Color(0xFFE8F5E8), // Light green background
          const Color(0xFF4CAF50),
          Icons.check,
          isTablet,
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _buildSummaryCard(
          pending,
          'Pending',
          const Color(0xFFFFF3E0), // Light orange background
          const Color(0xFFFF9800),
          Icons.access_time,
          isTablet,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    double amount,
    String label,
    Color backgroundColor,
    Color iconColor,
    IconData icon,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isTablet ? 64 : 48,
            height: isTablet ? 64 : 48,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isTablet ? 32 : 24,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.black87,
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Recent Collections component
class _RecentCollections extends StatelessWidget {
  final List<TodayTxn> list;
  const _RecentCollections({required this.list});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Text(
              'Recent Collections',
              style: TextStyle(
                color: Colors.black87,
                fontSize: isTablet ? 22 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                bottom: isTablet ? 24 : 20,
                left: isTablet ? 24 : 20,
                right: isTablet ? 24 : 20,
              ),
              child: Text(
                'No recent collections',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            )
          else
            ...list.map((t) => Container(
                  margin: EdgeInsets.fromLTRB(
                    isTablet ? 24 : 20,
                    0,
                    isTablet ? 24 : 20,
                    isTablet ? 16 : 12,
                  ),
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: isSmallScreen
                    ? _buildVerticalTransactionLayout(t, isTablet)
                    : _buildHorizontalTransactionLayout(t, isTablet),
                )),
          SizedBox(height: isTablet ? 12 : 8),
        ],
      ),
    );
  }

  Widget _buildHorizontalTransactionLayout(TodayTxn t, bool isTablet) {
    return Row(
      children: [
        // Green circle with checkmark
        Container(
          width: isTablet ? 40 : 32,
          height: isTablet ? 40 : 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: const Color(0xFF4CAF50),
            size: isTablet ? 20 : 16,
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.party.isNotEmpty ? t.party : 'ABC Corp',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: isTablet ? 4 : 2),
              Text(
                t.time.isNotEmpty ? t.time : '2024-01-15 • Cash',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${t.amount > 0 ? t.amount.toString() : "25000"}',
              style: TextStyle(
                color: Colors.black87,
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isTablet ? 4 : 2),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 4 : 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              ),
              child: Text(
                'Collected',
                style: TextStyle(
                  color: const Color(0xFF4CAF50),
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalTransactionLayout(TodayTxn t, bool isTablet) {
    return Column(
      children: [
        Row(
          children: [
            // Green circle with checkmark
            Container(
              width: isTablet ? 40 : 32,
              height: isTablet ? 40 : 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: const Color(0xFF4CAF50),
                size: isTablet ? 20 : 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 4 : 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              ),
              child: Text(
                'Collected',
                style: TextStyle(
                  color: const Color(0xFF4CAF50),
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.party.isNotEmpty ? t.party : 'ABC Corp',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isTablet ? 4 : 2),
                  Text(
                    t.time.isNotEmpty ? t.time : '2024-01-15 • Cash',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${t.amount > 0 ? t.amount.toString() : "25000"}',
              style: TextStyle(
                color: Colors.black87,
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

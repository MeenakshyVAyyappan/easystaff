import 'package:flutter/material.dart';
import 'package:eazystaff/services/auth_service.dart';
import 'package:eazystaff/services/dashboard_service.dart';
import 'package:eazystaff/pages/edit_profile_page.dart';
import 'package:eazystaff/pages/change_password_page.dart';
import 'package:eazystaff/pages/notification_settings_page.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = AuthService.currentUser;
    if (user == null) {
      setState(() {
        _error = 'No user data available';
        _isLoading = false;
      });
      return;
    }

    try {
      final savedLocation = await AuthService.loadLocation() ?? '';
      final empId = user.employeeId.isNotEmpty ? user.employeeId : '2';

      final dashboardData = await DashboardService.fetchDashboard(
        empId: empId,
        officeCode: user.officeCode,
        officeId: user.officeId,
        financialYearId: user.financialYearId,
        savedLocation: savedLocation,
      );

      setState(() {
        _dashboardData = dashboardData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user data available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadDashboardData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Header
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.indigo[100],
                                child: Text(
                                  user.name.split(' ').map((e) => e[0]).join(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo[800],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${user.designation} • ${user.department}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Performance Summary (if dashboard data available)
                      if (_dashboardData != null) ...[
                        Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Performance Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'Collections',
                                        value: '₹${NumberFormat('#,##,###.##').format(_dashboardData!.monthCollections)}',
                                        icon: Icons.account_balance_wallet,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'Pending',
                                        value: '₹${NumberFormat('#,##,###.##').format(_dashboardData!.pendingAmount)}',
                                        icon: Icons.pending_actions,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'Customers',
                                        value: '${_dashboardData!.monthCustomers}',
                                        icon: Icons.people,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'Today\'s Txns',
                                        value: '${_dashboardData!.todays.length}',
                                        icon: Icons.today,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

            // Profile Details
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Profile Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildProfileItem(
                    icon: Icons.badge,
                    label: 'Employee ID',
                    value: user.employeeId,
                  ),
                  _buildProfileItem(
                    icon: Icons.person,
                    label: 'Username',
                    value: user.username,
                  ),
                  _buildProfileItem(
                    icon: Icons.work,
                    label: 'Department',
                    value: user.department,
                  ),
                  _buildProfileItem(
                    icon: Icons.assignment_ind,
                    label: 'Designation',
                    value: user.designation,
                  ),
                  _buildProfileItem(
                    icon: Icons.business,
                    label: 'Office Code',
                    value: user.officeCode,
                  ),
                  _buildProfileItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: user.location,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Edit Profile'),
                    subtitle: const Text('Update your profile information'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );

                      // If profile was updated, refresh dashboard data
                      if (result == true) {
                        _loadDashboardData();
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock, color: Colors.orange),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your login password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.green),
                    title: const Text('Notification Settings'),
                    subtitle: const Text('Manage your notification preferences'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Info
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildProfileItem(
                    icon: Icons.info,
                    label: 'App Version',
                    value: '1.0.0',
                  ),
                  _buildProfileItem(
                    icon: Icons.build,
                    label: 'Build Number',
                    value: '1',
                  ),
                  ListTile(
                    leading: const Icon(Icons.help, color: Colors.purple),
                    title: const Text('Help & Support'),
                    subtitle: const Text('Get help and contact support'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Help & support feature coming soon'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip, color: Colors.teal),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('View our privacy policy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy policy feature coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Powered by Ecraftz
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Ecraftz',
                  style: TextStyle(
                    color: Colors.indigo[700],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

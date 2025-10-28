import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  static const _storage = FlutterSecureStorage();
  
  bool _isLoading = true;
  bool _hasChanges = false;
  
  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  
  // App-specific notifications
  bool _newCustomerNotifications = true;
  bool _paymentReminders = true;
  bool _taskAssignments = true;
  bool _systemUpdates = true;
  bool _marketingEmails = false;
  
  // Notification timing
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  bool _weekendNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Load settings from secure storage
      final pushNotifications = await _storage.read(key: 'push_notifications');
      final emailNotifications = await _storage.read(key: 'email_notifications');
      final smsNotifications = await _storage.read(key: 'sms_notifications');
      final newCustomerNotifications = await _storage.read(key: 'new_customer_notifications');
      final paymentReminders = await _storage.read(key: 'payment_reminders');
      final taskAssignments = await _storage.read(key: 'task_assignments');
      final systemUpdates = await _storage.read(key: 'system_updates');
      final marketingEmails = await _storage.read(key: 'marketing_emails');
      final quietHoursStart = await _storage.read(key: 'quiet_hours_start');
      final quietHoursEnd = await _storage.read(key: 'quiet_hours_end');
      final weekendNotifications = await _storage.read(key: 'weekend_notifications');

      setState(() {
        _pushNotifications = pushNotifications != 'false';
        _emailNotifications = emailNotifications != 'false';
        _smsNotifications = smsNotifications == 'true';
        _newCustomerNotifications = newCustomerNotifications != 'false';
        _paymentReminders = paymentReminders != 'false';
        _taskAssignments = taskAssignments != 'false';
        _systemUpdates = systemUpdates != 'false';
        _marketingEmails = marketingEmails == 'true';
        _quietHoursStart = quietHoursStart ?? '22:00';
        _quietHoursEnd = quietHoursEnd ?? '08:00';
        _weekendNotifications = weekendNotifications == 'true';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save settings to secure storage
      await _storage.write(key: 'push_notifications', value: _pushNotifications.toString());
      await _storage.write(key: 'email_notifications', value: _emailNotifications.toString());
      await _storage.write(key: 'sms_notifications', value: _smsNotifications.toString());
      await _storage.write(key: 'new_customer_notifications', value: _newCustomerNotifications.toString());
      await _storage.write(key: 'payment_reminders', value: _paymentReminders.toString());
      await _storage.write(key: 'task_assignments', value: _taskAssignments.toString());
      await _storage.write(key: 'system_updates', value: _systemUpdates.toString());
      await _storage.write(key: 'marketing_emails', value: _marketingEmails.toString());
      await _storage.write(key: 'quiet_hours_start', value: _quietHoursStart);
      await _storage.write(key: 'quiet_hours_end', value: _quietHoursEnd);
      await _storage.write(key: 'weekend_notifications', value: _weekendNotifications.toString());

      // TODO: Send settings to server API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      setState(() {
        _hasChanges = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSettingChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectTime(String currentTime, Function(String) onTimeSelected) async {
    final time = TimeOfDay.fromDateTime(
      DateTime.parse('2023-01-01 $currentTime:00'),
    );
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: time,
    );
    
    if (selectedTime != null) {
      final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      onTimeSelected(formattedTime);
      _onSettingChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'General Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive notifications on your device'),
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                      _onSettingChanged();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive notifications via email'),
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() {
                        _emailNotifications = value;
                      });
                      _onSettingChanged();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('SMS Notifications'),
                    subtitle: const Text('Receive notifications via SMS'),
                    value: _smsNotifications,
                    onChanged: (value) {
                      setState(() {
                        _smsNotifications = value;
                      });
                      _onSettingChanged();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // App-specific Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('New Customers'),
                    subtitle: const Text('When new customers are added'),
                    value: _newCustomerNotifications,
                    onChanged: (value) {
                      setState(() {
                        _newCustomerNotifications = value;
                      });
                      _onSettingChanged();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Payment Reminders'),
                    subtitle: const Text('Upcoming payment due dates'),
                    value: _paymentReminders,
                    onChanged: (value) {
                      setState(() {
                        _paymentReminders = value;
                      });
                      _onSettingChanged();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Task Assignments'),
                    subtitle: const Text('When tasks are assigned to you'),
                    value: _taskAssignments,
                    onChanged: (value) {
                      setState(() {
                        _taskAssignments = value;
                      });
                      _onSettingChanged();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('System Updates'),
                    subtitle: const Text('App updates and maintenance'),
                    value: _systemUpdates,
                    onChanged: (value) {
                      setState(() {
                        _systemUpdates = value;
                      });
                      _onSettingChanged();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Marketing Emails'),
                    subtitle: const Text('Promotional content and offers'),
                    value: _marketingEmails,
                    onChanged: (value) {
                      setState(() {
                        _marketingEmails = value;
                      });
                      _onSettingChanged();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notification Timing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Timing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Quiet Hours Start'),
                    subtitle: Text('No notifications after $_quietHoursStart'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(_quietHoursStart, (time) {
                      setState(() {
                        _quietHoursStart = time;
                      });
                    }),
                  ),
                  ListTile(
                    title: const Text('Quiet Hours End'),
                    subtitle: Text('Resume notifications at $_quietHoursEnd'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(_quietHoursEnd, (time) {
                      setState(() {
                        _quietHoursEnd = time;
                      });
                    }),
                  ),
                  SwitchListTile(
                    title: const Text('Weekend Notifications'),
                    subtitle: const Text('Receive notifications on weekends'),
                    value: _weekendNotifications,
                    onChanged: (value) {
                      setState(() {
                        _weekendNotifications = value;
                      });
                      _onSettingChanged();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          if (_hasChanges)
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Saving...'),
                      ],
                    )
                  : const Text(
                      'Save Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
    );
  }
}

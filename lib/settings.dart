import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          value: Theme.of(context).brightness == Brightness.dark,
          onChanged: (_) {
            // Hook up to a theme controller/provider for real apps.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Implement theme toggle logic')),
            );
          },
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.store),
          title: const Text('Business Profile'), 
          subtitle: const Text('Name, GSTIN, Address'),
          onTap: () {}, 
        ),
        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: const Text('Invoice Template'),
          subtitle: const Text('Branding, fields, logo'),
          onTap: () {},
        ),
      ],
    );
  }
}

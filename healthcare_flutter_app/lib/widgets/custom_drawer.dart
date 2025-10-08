import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme_config.dart';

/// PUBLIC_INTERFACE
class CustomDrawer extends StatelessWidget {
  final String role;
  const CustomDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            ListTile(
              title: const Text('Home'),
              leading: const Icon(Icons.home),
              onTap: () {
                if (role == 'doctor') {
                  context.go('/doctor');
                } else {
                  context.go('/patient');
                }
              },
            ),
            ListTile(
              title: const Text('Appointments'),
              leading: const Icon(Icons.calendar_month),
              onTap: () => context.go('/appointments'),
            ),
            ListTile(
              title: const Text('Medical Records'),
              leading: const Icon(Icons.folder_open),
              onTap: () => context.go('/records'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout, color: ThemeConfig.error),
              onTap: () => context.go('/login'), // Actual sign out triggered from screen actions
            ),
          ],
        ),
      ),
    );
  }
}

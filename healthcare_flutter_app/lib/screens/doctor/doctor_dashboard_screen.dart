import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_drawer.dart';

/// PUBLIC_INTERFACE
class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: const CustomAppBar(titleText: 'Doctor Dashboard'),
      drawer: CustomDrawer(role: auth.role),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Card(
              child: ListTile(
                leading: Icon(Icons.calendar_month),
                title: Text('Today\'s Appointments'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.people_alt),
                title: Text('My Patients'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

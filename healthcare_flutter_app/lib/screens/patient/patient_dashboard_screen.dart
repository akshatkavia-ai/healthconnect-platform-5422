import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/loading_indicator.dart';

/// PUBLIC_INTERFACE
class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();
    final user = auth.user;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    if (!patientProvider.loading && patientProvider.current == null) {
      // Trigger load without using BuildContext after an async gap
      final pid = user.id;
      Future.microtask(() => patientProvider.loadByUserId(pid));
    }

    return Scaffold(
      appBar: const CustomAppBar(titleText: 'Patient Dashboard'),
      drawer: CustomDrawer(role: auth.role),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: patientProvider.loading
            ? const LoadingIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${user.email}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (patientProvider.current == null)
                    Card(
                      child: ListTile(
                        title: const Text('Complete your registration'),
                        subtitle: const Text('Provide personal details to manage appointments and records.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/patient/register'),
                      ),
                    ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Appointments'),
                      onTap: () => context.go('/appointments'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.folder_open),
                      title: const Text('Medical Records'),
                      onTap: () => context.go('/records'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

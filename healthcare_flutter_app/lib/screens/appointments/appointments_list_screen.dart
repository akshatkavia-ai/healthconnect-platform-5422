import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/loading_indicator.dart';

/// PUBLIC_INTERFACE
class AppointmentsListScreen extends StatelessWidget {
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apptProvider = context.watch<AppointmentProvider>();
    final patientProvider = context.watch<PatientProvider>();

    final user = auth.user;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    // Trigger initial load
    if (!apptProvider.loading && apptProvider.items.isEmpty) {
      if (auth.role == 'doctor') {
        Future.microtask(() => context.read<AppointmentProvider>().loadForDoctor(user.id));
      } else {
        final pid = patientProvider.current?.id ?? user.id;
        Future.microtask(() => context.read<AppointmentProvider>().loadForPatient(pid));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: apptProvider.loading
          ? const LoadingIndicator()
          : ListView.builder(
              itemCount: apptProvider.items.length,
              itemBuilder: (ctx, i) {
                final a = apptProvider.items[i];
                return AppointmentCard(
                  appointment: a,
                  onTap: () => context.go('/appointments/${a.id}'),
                );
              },
            ),
      floatingActionButton: auth.role == 'patient'
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/appointments/book'),
              label: const Text('Book'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}

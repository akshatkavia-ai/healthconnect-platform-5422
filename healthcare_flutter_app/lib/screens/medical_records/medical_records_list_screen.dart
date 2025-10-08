import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/medical_record_provider.dart';
import '../../widgets/medical_record_card.dart';
import '../../widgets/loading_indicator.dart';

/// PUBLIC_INTERFACE
class MedicalRecordsListScreen extends StatelessWidget {
  const MedicalRecordsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final recProvider = context.watch<MedicalRecordProvider>();
    final patientProvider = context.watch<PatientProvider>();

    final user = auth.user;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    if (!recProvider.loading && recProvider.items.isEmpty) {
      final pid = patientProvider.current?.id ?? user.id;
      Future.microtask(() => context.read<MedicalRecordProvider>().loadForPatient(pid));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Records')),
      body: recProvider.loading
          ? const LoadingIndicator()
          : ListView.builder(
              itemCount: recProvider.items.length,
              itemBuilder: (ctx, i) {
                final r = recProvider.items[i];
                return MedicalRecordCard(
                  record: r,
                  onTap: () => context.go('/records/${r.id}'),
                );
              },
            ),
    );
  }
}

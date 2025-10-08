import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appointment_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/date_formatter.dart';

/// PUBLIC_INTERFACE
class AppointmentDetailScreen extends StatelessWidget {
  final String id;
  const AppointmentDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();

    if (!provider.loading && (provider.selected == null || provider.selected!.id != id)) {
      Future.microtask(() => context.read<AppointmentProvider>().getById(id));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Detail')),
      body: provider.loading || provider.selected == null
          ? const LoadingIndicator()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: ListTile(
                  title: Text('Status: ${provider.selected!.status}'),
                  subtitle: Text(
                    'Start: ${DateFormatter.formatDateTime(provider.selected!.startTime)}\n'
                    'Doctor: ${provider.selected!.doctorId}\n'
                    'Notes: ${provider.selected!.notes ?? '-'}',
                  ),
                ),
              ),
            ),
    );
  }
}

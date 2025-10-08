import 'package:flutter/material.dart';

import '../models/appointment_model.dart';
import '../utils/date_formatter.dart';

/// PUBLIC_INTERFACE
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const AppointmentCard({super.key, required this.appointment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dt = DateFormatter.formatDateTime(appointment.startTime);
    return Card(
      child: ListTile(
        title: Text('Appointment - ${appointment.status}'),
        subtitle: Text('Start: $dt\nDoctor: ${appointment.doctorId}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/appointment_model.dart';
import '../../widgets/custom_button.dart';

/// PUBLIC_INTERFACE
class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Future<void> _book(AppointmentProvider provider, String patientId) async {
    if (_selectedDay == null) return;
    final start = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, 10, 0);
    final appt = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: patientId,
      doctorId: 'doctor-1', // Example fixed doctor
      startTime: start,
      endTime: start.add(const Duration(minutes: 30)),
      status: 'scheduled',
      notes: 'Booked via app',
    );
    await provider.create(appt);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final apptProvider = context.watch<AppointmentProvider>();
    final patientProvider = context.watch<PatientProvider>();
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();
    final patientId = patientProvider.current?.id ?? user.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 1)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (sel, foc) {
                setState(() {
                  _selectedDay = sel;
                  _focusedDay = foc;
                });
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Book for selected day',
              onPressed: () => _book(apptProvider, patientId),
              loading: apptProvider.loading,
            )
          ],
        ),
      ),
    );
  }
}

import 'supabase_service.dart';
import '../models/appointment_model.dart';

/// PUBLIC_INTERFACE
class AppointmentService {
  static const String tableName = 'appointments';

  /// PUBLIC_INTERFACE
  Future<List<Appointment>> listForPatient(String patientId) async {
    final List<Map<String, dynamic>> rows = await SupabaseService.table(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('start_time');
    return rows.map(Appointment.fromMap).toList();
  }

  /// PUBLIC_INTERFACE
  Future<List<Appointment>> listForDoctor(String doctorId) async {
    final List<Map<String, dynamic>> rows = await SupabaseService.table(tableName)
        .select()
        .eq('doctor_id', doctorId)
        .order('start_time');
    return rows.map(Appointment.fromMap).toList();
  }

  /// PUBLIC_INTERFACE
  Future<Appointment?> getById(String id) async {
    final row = await SupabaseService.table(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Appointment.fromMap(row);
  }

  /// PUBLIC_INTERFACE
  Future<Appointment> create(Appointment a) async {
    final data = await SupabaseService.table(tableName)
        .insert(a.toMap())
        .select()
        .single();
    return Appointment.fromMap(data);
  }

  /// PUBLIC_INTERFACE
  Future<Appointment> update(Appointment a) async {
    final data = await SupabaseService.table(tableName)
        .update(a.toMap())
        .eq('id', a.id)
        .select()
        .single();
    return Appointment.fromMap(data as Map<String, dynamic>);
  }

  /// PUBLIC_INTERFACE
  Future<void> cancel(String id) async {
    await SupabaseService.table(tableName)
        .update({'status': 'cancelled'})
        .eq('id', id);
  }
}

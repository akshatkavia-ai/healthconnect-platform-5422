import 'supabase_service.dart';
import '../models/patient_model.dart';

/// PUBLIC_INTERFACE
class PatientService {
  static const String tableName = 'patients';

  /// PUBLIC_INTERFACE
  Future<Patient> upsertPatient(Patient patient) async {
    final data = await SupabaseService.table(tableName)
        .upsert(patient.toMap())
        .select()
        .single();
    return Patient.fromMap(data as Map<String, dynamic>);
  }

  /// PUBLIC_INTERFACE
  Future<Patient?> getPatientByUserId(String userId) async {
    final data = await SupabaseService.table(tableName)
        .eq('user_id', userId)
        .select()
        .maybeSingle();
    return data == null ? null : Patient.fromMap(data as Map<String, dynamic>);
  }

  /// PUBLIC_INTERFACE
  Future<List<Patient>> searchPatientsByName(String query) async {
    final rows = await SupabaseService.table(tableName)
        .ilike('name', '%$query%')
        .select();
    return (rows as List<dynamic>)
        .map((e) => Patient.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

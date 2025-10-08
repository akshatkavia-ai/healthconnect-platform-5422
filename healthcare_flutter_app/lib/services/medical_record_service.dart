import 'supabase_service.dart';
import '../models/medical_record_model.dart';

/// PUBLIC_INTERFACE
class MedicalRecordService {
  static const String tableName = 'medical_records';

  /// PUBLIC_INTERFACE
  Future<List<MedicalRecord>> listForPatient(String patientId) async {
    final rows = await SupabaseService.table(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => MedicalRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// PUBLIC_INTERFACE
  Future<MedicalRecord?> getById(String id) async {
    final row = await SupabaseService.table(tableName).select().eq('id', id).maybeSingle();
    return row == null ? null : MedicalRecord.fromMap(row);
  }

  /// PUBLIC_INTERFACE
  Future<MedicalRecord> create(MedicalRecord r) async {
    final data = await SupabaseService.table(tableName).insert(r.toMap()).select().single();
    return MedicalRecord.fromMap(data);
  }

  /// PUBLIC_INTERFACE
  Future<void> delete(String id) async {
    await SupabaseService.table(tableName).delete().eq('id', id);
  }
}

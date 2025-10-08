class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'scheduled','completed','cancelled'
  final String? notes;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.notes,
  });

  /// PUBLIC_INTERFACE
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'].toString(),
      patientId: map['patient_id']?.toString() ?? '',
      doctorId: map['doctor_id']?.toString() ?? '',
      startTime: DateTime.parse(map['start_time'].toString()),
      endTime: map['end_time'] != null ? DateTime.tryParse(map['end_time'].toString()) : null,
      status: map['status']?.toString() ?? 'scheduled',
      notes: map['notes']?.toString(),
    );
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}

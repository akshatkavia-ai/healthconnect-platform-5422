class MedicalRecord {
  final String id;
  final String patientId;
  final String title;
  final String description;
  final String? fileUrl;
  final DateTime createdAt;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    this.fileUrl,
    required this.createdAt,
  });

  /// PUBLIC_INTERFACE
  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'].toString(),
      patientId: map['patient_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      fileUrl: map['file_url']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

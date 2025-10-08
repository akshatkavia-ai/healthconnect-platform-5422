class Patient {
  final String id;
  final String userId;
  final String name;
  final DateTime? dob;
  final String gender;
  final String phone;
  final String address;
  final String? avatarUrl;

  Patient({
    required this.id,
    required this.userId,
    required this.name,
    this.dob,
    required this.gender,
    required this.phone,
    required this.address,
    this.avatarUrl,
  });

  /// PUBLIC_INTERFACE
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'].toString(),
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      dob: map['dob'] != null ? DateTime.tryParse(map['dob'].toString()) : null,
      gender: map['gender']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      avatarUrl: map['avatar_url']?.toString(),
    );
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'address': address,
      'avatar_url': avatarUrl,
    };
  }
}

/// User model representing an app user derived from Supabase auth profile.
class AppUser {
  final String id;
  final String email;
  final String role; // 'patient' | 'doctor' | 'admin'

  AppUser({
    required this.id,
    required this.email,
    required this.role,
  });

  /// PUBLIC_INTERFACE
  /// Create AppUser from map (e.g., Supabase 'profiles' row or user metadata).
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'patient',
    );
  }

  /// PUBLIC_INTERFACE
  /// Convert user to map for insertion/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
    };
  }
}

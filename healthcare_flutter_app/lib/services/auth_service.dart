import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'supabase_service.dart';

/// PUBLIC_INTERFACE
class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  /// PUBLIC_INTERFACE
  /// Sign in with email and password.
  Future<AuthResponse> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// PUBLIC_INTERFACE
  /// Sign up with email and password. Role defaults to 'patient'.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String role = 'patient',
  }) async {
    // Store role in user metadata for simplicity. For production, store in 'profiles' table.
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
      emailRedirectTo: null,
    );
  }

  /// PUBLIC_INTERFACE
  Future<void> signOut() => _client.auth.signOut();

  /// PUBLIC_INTERFACE
  /// Returns the authenticated user or null.
  User? get currentUser => _client.auth.currentUser;

  /// PUBLIC_INTERFACE
  /// Get role from user metadata or fallback to 'patient'.
  String get currentRole {
    final user = _client.auth.currentUser;
    final role = user?.userMetadata?['role']?.toString();
    return role == null || role.isEmpty ? 'patient' : role;
  }

  /// PUBLIC_INTERFACE
  /// Fetch profile role from 'profiles' table by user id. Optional.
  Future<String?> fetchRoleFromProfiles(String userId) async {
    final res = await _client.from('profiles').select('role').eq('id', userId).maybeSingle();
    return res != null ? res['role']?.toString() : null;
  }

  /// PUBLIC_INTERFACE
  /// Build AppUser instance from Supabase auth user, attempting to resolve role.
  Future<AppUser?> buildAppUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final metaRole = user.userMetadata?['role']?.toString();
    String role = metaRole ?? 'patient';
    try {
      final profRole = await fetchRoleFromProfiles(user.id);
      if (profRole != null && profRole.isNotEmpty) {
        role = profRole;
      }
    } catch (_) {}
    return AppUser(id: user.id, email: user.email ?? '', role: role);
  }
}

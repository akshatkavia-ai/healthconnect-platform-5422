import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'supabase_service.dart';

/// PUBLIC_INTERFACE
class AuthService {
  final SupabaseClient _client = SupabaseService.client;
  
  static const int _maxSignupRetries = 3;
  static const int _baseDelayMs = 1000;

  /// PUBLIC_INTERFACE
  /// Sign in with email and password.
  Future<AuthResponse> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// PUBLIC_INTERFACE
  /// Sign up with email and password. Role defaults to 'patient'.
  /// Uses SITE_URL from .env (if present) for the email confirmation redirect.
  /// Includes retry logic with exponential backoff.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String role = 'patient',
  }) async {
    AuthException? lastError;
    final redirect = dotenv.env['SITE_URL']?.trim();
    
    for (var attempt = 1; attempt <= _maxSignupRetries; attempt++) {
      try {
        if (kDebugMode && attempt > 1) {
          debugPrint('Signup attempt $attempt of $_maxSignupRetries...');
        }

        return await _client.auth.signUp(
          email: email,
          password: password,
          data: {'role': role},
          emailRedirectTo: (redirect != null && redirect.isNotEmpty) ? redirect : null,
        );
      } on AuthException catch (e) {
        // Don't retry if it's a validation error or user already exists
        final errorMsg = e.message.toLowerCase();
        if (errorMsg.contains('400') || errorMsg.contains('422') || 
            errorMsg.contains('already registered')) {
          rethrow;
        }
        
        lastError = e;
        if (attempt < _maxSignupRetries) {
          final delayMs = (_baseDelayMs * pow(2, attempt - 1)).toInt();
          debugPrint('Signup attempt $attempt failed, retrying in ${delayMs}ms: ${e.message}');
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }

    final msg = 'Registration failed after $_maxSignupRetries attempts. ${lastError?.message ?? 'Unknown error'}';
    throw AuthException(msg);
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
    return res?['role']?.toString();
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

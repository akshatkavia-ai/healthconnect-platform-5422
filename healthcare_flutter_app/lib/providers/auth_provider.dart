import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// PUBLIC_INTERFACE
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  late final StreamSubscription<AuthState> _sub;

  bool _loading = false;
  String? _error;
  AppUser? _user;

  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService() {
    // Subscribe to auth state changes
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      await _resolveUser();
    });
    _resolveUser();
  }

  bool get loading => _loading;
  String? get error => _error;
  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  String get role => _user?.role ?? 'patient';

  Future<void> _resolveUser() async {
    _setLoading(true);
    try {
      _user = await _authService.buildAppUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// PUBLIC_INTERFACE
  /// Perform login. Navigation must be handled in UI by listening to isAuthenticated.
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// PUBLIC_INTERFACE
  /// Perform registration with a role (default patient).
  Future<void> register(String email, String password, {String role = 'patient'}) async {
    _setLoading(true);
    try {
      await _authService.signUp(email: email, password: password, role: role);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// PUBLIC_INTERFACE
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

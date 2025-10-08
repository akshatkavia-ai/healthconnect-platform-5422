import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// PUBLIC_INTERFACE
/// Centralized Supabase configuration and client access.
/// Initializes the Supabase client using values provided at runtime (e.g., from .env).
class SupabaseConfig {
  /// Supabase client instance, set during initialize().
  static late final SupabaseClient client;

  // Internal state used by health check and diagnostics.
  static bool _initialized = false;
  static String _lastConnectionMessage = '';
  static String _effectiveUrl = '';

  /// PUBLIC_INTERFACE
  /// Initialize Supabase client once using the provided URL and anon/publishable key.
  /// Also records connection info for health checks and diagnostics.
  static Future<void> initialize({required String url, required String anonKey}) async {
    if (kDebugMode) {
      debugPrint('Initializing Supabase with URL=$url');
    }

    // Create client and assign to both our static field and Supabase.instance for global access.
    client = Supabase.instance.client = SupabaseClient(url, anonKey);

    // Track initialization state and diagnostics.
    _effectiveUrl = url.trim();
    _initialized = true;

    // Derive host for user-friendly message.
    String host = _effectiveUrl;
    try {
      final uri = Uri.parse(_effectiveUrl);
      if (uri.host.isNotEmpty) {
        host = uri.host;
      }
    } catch (_) {
      // keep raw url if parsing fails
    }
    _lastConnectionMessage = '[Supabase] Connected to $host';

    if (kDebugMode) {
      debugPrint(_lastConnectionMessage);
    }
  }

  /// PUBLIC_INTERFACE
  /// Access the initialized Supabase client (alias for [client]).
  static SupabaseClient get instanceClient => client;

  /// PUBLIC_INTERFACE
  /// Returns true after initialize() is successfully called.
  static bool get isInitialized => _initialized;

  /// PUBLIC_INTERFACE
  /// Returns the effective Supabase URL used for initialization.
  static String get effectiveSupabaseUrl => _effectiveUrl;

  /// PUBLIC_INTERFACE
  /// Returns the latest connection status message (success or failure details).
  static String get lastConnectionMessage => _lastConnectionMessage;

  /// Debug validation (optional)
  static void debugValidate() {
    // With `late final`, client will be non-null after initialize. This method can be used
    // to log a message if initialization hasn't occurred yet in a guarded context.
    try {
      // access to ensure it's initialized
      // ignore: unnecessary_statements
      client;
    } catch (_) {
      if (kDebugMode) debugPrint('Supabase client not yet initialized.');
    }
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PUBLIC_INTERFACE
class SupabaseConfig {
  /// Hardcoded Supabase configuration (development/demo)
  /// Replace with your actual project URL and anon/public key.
  static const String supabaseUrl = 'https://dzrdewhocvijofmcmxeu.supabase.co';
  static const String supabaseKey = 'public-anon-key-hardcoded';

  static String? _effectiveUrl;
  static String _lastConnectionMessage = '';
  static bool _initialized = false;
  static Completer<void>? _initCompleter;

  /// Normalize and validate a Supabase URL
  static String _normalizeUrl(String url) {
    var normalized = url.trim();

    // Ensure https:// prefix
    if (!normalized.startsWith('https://')) {
      normalized = 'https://${normalized.replaceAll('http://', '')}';
    }

    // Remove trailing slashes
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// Validate URL format and return list of issues
  static List<String> _validateUrl(String url) {
    final errors = <String>[];

    if (!url.startsWith('https://')) {
      errors.add('must start with "https://"');
    }

    if (!url.contains('.supabase.co')) {
      errors.add('must contain ".supabase.co"');
    }

    if (url.contains('supabase co')) {
      errors.add('contains "supabase co" (with a space) which is invalid; use ".supabase.co"');
    }

    Uri? parsed;
    try {
      parsed = Uri.parse(url);
      if (parsed.host.isEmpty) {
        errors.add('host is empty');
      }
    } catch (_) {
      errors.add('not a valid URI');
    }

    return errors;
  }

  /// PUBLIC_INTERFACE
  /// Initialize Supabase client using the hardcoded constants in this file.
  ///
  /// - No .env dependency
  /// - No pre-connectivity blocker (Supabase.initialize itself is fast and local)
  /// - Idempotent and safe to call multiple times concurrently.
  /// Connection status messages are available via [lastConnectionMessage].
  static Future<void> initialize() async {
    // Idempotent guard: if already initialized, return immediately.
    if (_initialized) return;

    // If an initialization is already in progress, wait for it.
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      final rawUrl = _normalizeUrl(supabaseUrl);
      final key = supabaseKey.trim();

      // Basic validation for presence
      if (rawUrl.isEmpty || key.isEmpty) {
        final msg =
            'Supabase configuration constants are missing. Ensure supabaseUrl and supabaseKey are set in lib/config/supabase_config.dart.';
        _lastConnectionMessage =
            '[Supabase] Initialization failed: Missing configuration constants';
        if (kDebugMode) {
          debugPrint(msg);
        }
        throw StateError(msg);
      }

      // Validate URL format
      final errors = _validateUrl(rawUrl);
      if (errors.isNotEmpty) {
        final msg =
            'Invalid Supabase URL in lib/config/supabase_config.dart: "$rawUrl". Issues: ${errors.join('; ')}.\n'
            'Example of a valid URL: https://dzrdewhocvijofmcmxeu.supabase.co';
        _lastConnectionMessage =
            '[Supabase] Initialization failed: Invalid URL format (${errors.join(', ')})';
        if (kDebugMode) {
          debugPrint(msg);
        }
        throw StateError(msg);
      }

      // Initialize Supabase once (no pre-connectivity guard)
      await Supabase.initialize(
        url: rawUrl,
        anonKey: key,
        debug: kDebugMode,
      );

      _effectiveUrl = rawUrl;

      // Extract host from URL for connection message
      String host = rawUrl;
      try {
        final uri = Uri.parse(rawUrl);
        host = uri.host.isNotEmpty ? uri.host : rawUrl;
      } catch (_) {
        // Keep rawUrl if parsing fails
      }

      _lastConnectionMessage = '[Supabase] Connected to $host';
      if (kDebugMode) {
        debugPrint(_lastConnectionMessage);
      }

      _initialized = true;
      _initCompleter!.complete();
      return; // Success
    } catch (e) {
      // Friendly message and propagate error so the app can surface a configuration screen if truly invalid.
      _lastConnectionMessage = '[Supabase] Initialization failed: $e';
      if (kDebugMode) {
        debugPrint(_lastConnectionMessage);
      }
      if (!(_initCompleter?.isCompleted ?? true)) {
        _initCompleter!.completeError(e);
      }
      rethrow;
    }
  }

  /// PUBLIC_INTERFACE
  /// Returns the current Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// PUBLIC_INTERFACE
  /// Returns the effective Supabase URL used after initialization, or empty string if not initialized yet.
  static String get effectiveSupabaseUrl => _effectiveUrl ?? '';

  /// PUBLIC_INTERFACE
  /// Returns the last connection message, indicating success or failure status.
  /// On success: '[Supabase] Connected to {host}'
  /// On failure: '[Supabase] Initialization failed: {reason}'
  static String get lastConnectionMessage => _lastConnectionMessage;

  /// PUBLIC_INTERFACE
  /// Whether Supabase.initialize has successfully completed.
  static bool get isInitialized => _initialized;
}

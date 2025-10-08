import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  /// Maximum retries for initialization
  static const int _maxInitRetries = 3;

  /// Base delay for exponential backoff (milliseconds)
  static const int _baseDelayMs = 1000;

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

  /// Check basic connectivity to Supabase URL
  static Future<bool> _checkConnectivity(String url) async {
    try {
      final uri = Uri.parse('$url/auth/v1/');
      final response = await http.head(uri);
      // Accept any response that isn't a server error
      return response.statusCode < 500;
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      return false;
    }
  }

  /// PUBLIC_INTERFACE
  /// Initialize Supabase client using the hardcoded constants in this file.
  ///
  /// This is idempotent and safe to call multiple times concurrently.
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
      var rawUrl = _normalizeUrl(supabaseUrl);
      final key = supabaseKey.trim();

      // Basic validation for presence
      if (rawUrl.isEmpty || key.isEmpty) {
        final msg =
            'Supabase configuration constants are missing. Ensure supabaseUrl and supabaseKey are set in lib/config/supabase_config.dart.';
        _lastConnectionMessage = '[Supabase] Initialization failed: Missing configuration constants';
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
        _lastConnectionMessage = '[Supabase] Initialization failed: Invalid URL format (${errors.join(', ')})';
        if (kDebugMode) {
          debugPrint(msg);
        }
        throw StateError(msg);
      }

      // Initialize with retries
      Exception? lastError;
      for (var attempt = 1; attempt <= _maxInitRetries; attempt++) {
        try {
          if (kDebugMode) {
            debugPrint('Supabase initialization attempt $attempt of $_maxInitRetries...');
          }

          // Check connectivity first
          final isConnected = await _checkConnectivity(rawUrl);
          if (!isConnected) {
            throw StateError('Failed to connect to Supabase URL: $rawUrl');
          }

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
          lastError = e is Exception ? e : Exception(e.toString());
          if (attempt < _maxInitRetries) {
            // Exponential backoff
            final delayMs = (_baseDelayMs * pow(2, attempt - 1)).toInt();
            if (kDebugMode) {
              debugPrint('Initialization attempt $attempt failed, retrying in ${delayMs}ms: $e');
            }
            await Future.delayed(Duration(milliseconds: delayMs));
          }
        }
      }

      // If we get here, all retries failed
      final msg = 'Failed to initialize Supabase after $_maxInitRetries attempts. Last error: $lastError';
      _lastConnectionMessage = '[Supabase] Initialization failed: $lastError';
      debugPrint(msg);
      throw StateError(msg);
    } catch (e) {
      // Ensure any waiters see the error
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
}

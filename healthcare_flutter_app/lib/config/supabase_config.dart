import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// PUBLIC_INTERFACE
class SupabaseConfig {
  static String? _effectiveUrl;
  
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
      return response.statusCode < 500; // Accept any response that isn't a server error
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      return false;
    }
  }

  /// PUBLIC_INTERFACE
  /// Initialize Supabase client using environment variables.
  ///
  /// Expects SUPABASE_URL and SUPABASE_KEY in .env.
  /// For backward compatibility, also supports SUPABASE_ANON_KEY if SUPABASE_KEY is not present.
  /// This method does NOT load dotenv; ensure dotenv is loaded before calling this.
  static Future<void> initialize() async {
    // Read env vars (dotenv must be loaded already)
    var rawUrl = dotenv.env['SUPABASE_URL'];
    final key = (dotenv.env['SUPABASE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'])?.trim();

    if (rawUrl == null || rawUrl.isEmpty || key == null || key.isEmpty) {
      final msg =
          'Supabase environment variables are missing. Ensure SUPABASE_URL and SUPABASE_KEY are set in .env '
          '(SUPABASE_ANON_KEY is supported as a fallback).';
      if (kDebugMode) {
        debugPrint(msg);
      }
      throw StateError(msg);
    }

    // Normalize URL
    rawUrl = _normalizeUrl(rawUrl);
    
    // Validate URL format
    final errors = _validateUrl(rawUrl);
    if (errors.isNotEmpty) {
      final msg =
          'Invalid SUPABASE_URL detected in .env: "$rawUrl". Issues: ${errors.join('; ')}.\n'
          'Example of a valid URL: https://dzrdewhocvijofmcmxeu.supabase.co';
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
        if (kDebugMode) {
          debugPrint('Supabase initialized successfully on attempt $attempt');
        }
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
    debugPrint(msg);
    throw StateError(msg);
  }

  /// PUBLIC_INTERFACE
  /// Returns the current Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// PUBLIC_INTERFACE
  /// Returns the effective Supabase URL used after initialization, or empty string if not initialized yet.
  static String get effectiveSupabaseUrl => _effectiveUrl ?? '';
}

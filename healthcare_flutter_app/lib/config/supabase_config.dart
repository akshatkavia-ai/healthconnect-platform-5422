import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PUBLIC_INTERFACE
class SupabaseConfig {
  static String? _effectiveUrl;

  /// PUBLIC_INTERFACE
  /// Initialize Supabase client using environment variables.
  ///
  /// Expects SUPABASE_URL and SUPABASE_KEY in .env.
  /// For backward compatibility, also supports SUPABASE_ANON_KEY if SUPABASE_KEY is not present.
  /// This method does NOT load dotenv; ensure dotenv is loaded before calling this.
  static Future<void> initialize() async {
    // Read env vars (dotenv must be loaded already)
    final rawUrl = dotenv.env['SUPABASE_URL']?.trim();
    final key = (dotenv.env['SUPABASE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'])?.trim();

    if (rawUrl == null || rawUrl.isEmpty || key == null || key.isEmpty) {
      final msg =
          'Supabase environment variables are missing. Ensure SUPABASE_URL and SUPABASE_KEY are set in .env '
          '(SUPABASE_ANON_KEY is supported as a fallback).';
      if (kDebugMode) {
        debugPrint(msg);
      }
      // Throw to allow caller to present a friendly error UI.
      throw StateError(msg);
    }

    // Validate URL format and common mistakes explicitly
    final errors = <String>[];
    if (!rawUrl.startsWith('https://')) {
      errors.add('must start with "https://"');
    }
    if (!rawUrl.contains('.supabase.co')) {
      errors.add('must contain ".supabase.co"');
    }
    if (rawUrl.contains('supabase co')) {
      errors.add('contains "supabase co" (with a space) which is invalid; use ".supabase.co"');
    }

    Uri? parsed;
    try {
      parsed = Uri.parse(rawUrl);
      if (parsed.host.isEmpty) {
        errors.add('host is empty');
      }
    } catch (_) {
      errors.add('not a valid URI');
    }

    if (errors.isNotEmpty) {
      final msg =
          'Invalid SUPABASE_URL detected in .env: "$rawUrl". Issues: ${errors.join('; ')}.\n'
          'Example of a valid URL: https://dzrdewhocvijofmcmxeu.supabase.co';
      if (kDebugMode) {
        debugPrint(msg);
      }
      throw StateError(msg);
    }

    if (kDebugMode) {
      debugPrint('Using SUPABASE_URL: $rawUrl'
          '${parsed != null && parsed.host.isNotEmpty ? ' (host: ${parsed.host})' : ''}');
    }

    await Supabase.initialize(
      url: rawUrl,
      anonKey: key,
      debug: kDebugMode,
    );

    _effectiveUrl = rawUrl;
    if (kDebugMode) {
      debugPrint('Supabase initialized successfully.');
    }
  }

  /// PUBLIC_INTERFACE
  /// Returns the current Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// PUBLIC_INTERFACE
  /// Returns the effective Supabase URL used after initialization, or empty string if not initialized yet.
  static String get effectiveSupabaseUrl => _effectiveUrl ?? '';
}

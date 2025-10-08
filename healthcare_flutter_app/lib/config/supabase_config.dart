import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PUBLIC_INTERFACE
class SupabaseConfig {
  /// PUBLIC_INTERFACE
  /// Initialize Supabase client using environment variables.
  ///
  /// Expects SUPABASE_URL and SUPABASE_KEY in .env.
  /// For backward compatibility, also supports SUPABASE_ANON_KEY if SUPABASE_KEY is not present.
  /// This method does NOT load dotenv; ensure dotenv is loaded before calling this.
  static Future<void> initialize() async {
    // Read env vars (dotenv must be loaded already)
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      final msg =
          'Supabase environment variables are missing. Ensure SUPABASE_URL and SUPABASE_KEY are set in .env '
          '(SUPABASE_ANON_KEY is supported as a fallback).';
      if (kDebugMode) {
        debugPrint(msg);
      }
      // Throw to allow caller to present a friendly error UI.
      throw StateError(msg);
    }

    await Supabase.initialize(
      url: url,
      anonKey: key,
      debug: kDebugMode,
    );
  }

  /// PUBLIC_INTERFACE
  /// Returns the current Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;
}

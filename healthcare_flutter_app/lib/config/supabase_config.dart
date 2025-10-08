import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PUBLIC_INTERFACE
class SupabaseConfig {
  /// Initialize dotenv and Supabase client early in app startup.
  ///
  /// Loads SUPABASE_URL and SUPABASE_ANON_KEY from .env and initializes
  /// SupabaseFlutter. Call this before runApp.
  static Future<void> initialize() async {
    // Load environment variables
    await dotenv.load(fileName: '.env', fallback: true);

    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'Supabase environment variables are missing. '
          'Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in .env',
        );
      }
      // We still attempt to initialize with empty strings to avoid null errors in debug,
      // but most features will not work without proper configuration.
    }

    await Supabase.initialize(
      url: url ?? '',
      anonKey: key ?? '',
      debug: kDebugMode,
      authFlowType: AuthFlowType.pkce,
    );
  }

  /// PUBLIC_INTERFACE
  /// Returns the current Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;
}

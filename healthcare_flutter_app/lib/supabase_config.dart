import 'package:flutter/foundation.dart';

/// PUBLIC_INTERFACE
class SupabaseConfig {
  /// URL of your Supabase project.
  /// Uses --dart-define if provided, with a safe sample fallback for development.
  ///
  /// To override at runtime:
  /// flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dzrdewhocvijofmcmxeu.supabase.co',
  );

  /// Public anon key for your Supabase project.
  /// Uses --dart-define if provided, with a safe sample fallback for development.
  ///
  /// To override at runtime:
  /// flutter run --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable__tDARO-1A0W6jojhlIcM2g_V7fRrHK0',
  );

  /// PUBLIC_INTERFACE
  /// Returns a brief description of effective config (redacted key).
  static String describe() {
    final redacted = anonKey.isEmpty
        ? '(empty)'
        : '${anonKey.substring(0, anonKey.length > 6 ? 6 : anonKey.length)}•••';
    return 'SupabaseConfig(url: $url, anonKey: $redacted)';
  }

  /// PUBLIC_INTERFACE
  /// Basic validation to help catch misconfigurations in debug.
  static void debugValidate() {
    if (!kDebugMode) return;
    if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
      debugPrint(
        '[SupabaseConfig] Warning: URL seems invalid. Expected https://xxxx.supabase.co, got: $url',
      );
    }
    if (anonKey.isEmpty) {
      debugPrint('[SupabaseConfig] Warning: Anon key is empty.');
    }
  }
}

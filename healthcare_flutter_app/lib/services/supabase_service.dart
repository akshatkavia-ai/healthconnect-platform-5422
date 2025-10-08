import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// PUBLIC_INTERFACE
class SupabaseService {
  /// Returns the Supabase client instance.
  static SupabaseClient get client => SupabaseConfig.client;

  /// PUBLIC_INTERFACE
  /// Convenience method to get a query builder for a table.
  /// Returns SupabaseQueryBuilder to support insert/update/upsert/delete and filters.
  static SupabaseQueryBuilder table(String table) => client.from(table);
}

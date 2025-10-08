import 'package:intl/intl.dart';

/// PUBLIC_INTERFACE
class DateFormatter {
  /// Format a DateTime to a human-readable string like "Jan 10, 2025 4:30 PM".
  static String formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy h:mm a').format(dt);
  }
}

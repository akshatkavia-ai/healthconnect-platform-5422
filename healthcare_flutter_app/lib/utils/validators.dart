/// PUBLIC_INTERFACE
class Validators {
  /// Simple email validation.
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    // Valid simple pattern for general emails (not exhaustive by RFC).
    final regex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  /// Simple password validation.
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  /// Required field.
  static String? requiredField(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }
}

import 'package:flutter/material.dart';
import '../config/theme_config.dart';

/// PUBLIC_INTERFACE
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? ThemeConfig.primary,
        minimumSize: const Size(double.infinity, 48),
      ),
      child: loading
          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

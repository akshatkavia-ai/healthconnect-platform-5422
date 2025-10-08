import 'package:flutter/material.dart';

/// PUBLIC_INTERFACE
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? inputType;
  final bool obscure;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.inputType,
    this.obscure = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

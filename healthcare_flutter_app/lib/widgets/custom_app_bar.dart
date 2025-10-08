import 'package:flutter/material.dart';
import '../config/theme_config.dart';

/// PUBLIC_INTERFACE
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.titleText, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: ThemeConfig.surface,
      surfaceTintColor: Colors.transparent,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

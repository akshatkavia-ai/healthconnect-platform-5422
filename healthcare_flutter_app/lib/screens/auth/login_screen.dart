import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/validators.dart';
import '../../config/theme_config.dart';

/// PUBLIC_INTERFACE
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (_form.currentState?.validate() != true) return;
    // Do not use context after await (Flutter Async Context rule)
    final email = _email.text.trim();
    final pwd = _password.text;
    await auth.login(email, pwd);
    // Navigation is handled in build via state flags.
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        // In build: handle navigation based on state flags
        if (auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final role = auth.role;
            if (role == 'doctor') {
              context.go('/doctor');
            } else {
              context.go('/patient');
            }
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Welcome Back')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: auth.loading
                    ? const LoadingIndicator(message: 'Signing in...')
                    : Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'HealthConnect',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: ThemeConfig.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _email,
                              label: 'Email',
                              inputType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _password,
                              label: 'Password',
                              obscure: true,
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 20),
                            if (auth.error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(color: ThemeConfig.error),
                                ),
                              ),
                            CustomButton(
                              label: 'Login',
                              onPressed: () => _submit(auth),
                              loading: auth.loading,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go('/register'),
                              child: const Text("Don't have an account? Register"),
                            )
                          ],
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

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
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'patient';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (_form.currentState?.validate() != true) return;
    final email = _email.text.trim();
    final pwd = _password.text;
    final role = _role;
    await auth.register(email, pwd, role: role);
    // Navigation handled in build based on state.
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
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
          appBar: AppBar(title: const Text('Create Account')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: auth.loading
                    ? const LoadingIndicator(message: 'Creating account...')
                    : Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Join HealthConnect',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: ThemeConfig.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _role,
                              decoration: const InputDecoration(labelText: 'Role'),
                              items: const [
                                DropdownMenuItem(value: 'patient', child: Text('Patient')),
                                DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                              ],
                              onChanged: (v) => setState(() => _role = v ?? 'patient'),
                            ),
                            const SizedBox(height: 12),
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
                              label: 'Register',
                              onPressed: () => _submit(auth),
                              loading: auth.loading,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Already have an account? Login'),
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

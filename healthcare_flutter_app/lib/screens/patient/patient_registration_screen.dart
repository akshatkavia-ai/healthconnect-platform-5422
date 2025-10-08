import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/patient_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';

/// PUBLIC_INTERFACE
class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _gender = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _gender.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save(PatientProvider provider, String userId) async {
    if (_form.currentState?.validate() != true) return;
    final patient = Patient(
      id: userId, // Often id equals user id in simple schemas
      userId: userId,
      name: _name.text.trim(),
      dob: null,
      gender: _gender.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      avatarUrl: null,
    );
    await provider.registerOrUpdate(patient);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<PatientProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Registration')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(controller: _name, label: 'Full Name', validator: Validators.requiredField),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _gender, label: 'Gender', validator: Validators.requiredField),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _phone, label: 'Phone', validator: Validators.requiredField),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _address, label: 'Address', validator: Validators.requiredField),
                  const SizedBox(height: 20),
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
                    ),
                  CustomButton(
                    label: 'Save',
                    onPressed: () => _save(provider, user.id),
                    loading: provider.loading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

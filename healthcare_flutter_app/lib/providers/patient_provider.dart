import 'package:flutter/foundation.dart';

import '../models/patient_model.dart';
import '../services/patient_service.dart';

/// PUBLIC_INTERFACE
class PatientProvider extends ChangeNotifier {
  final PatientService _service;

  Patient? _current;
  bool _loading = false;
  String? _error;

  PatientProvider({PatientService? service}) : _service = service ?? PatientService();

  Patient? get current => _current;
  bool get loading => _loading;
  String? get error => _error;

  /// PUBLIC_INTERFACE
  Future<void> loadByUserId(String userId) async {
    _setLoading(true);
    try {
      _current = await _service.getPatientByUserId(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// PUBLIC_INTERFACE
  Future<void> registerOrUpdate(Patient patient) async {
    _setLoading(true);
    try {
      _current = await _service.upsertPatient(patient);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}

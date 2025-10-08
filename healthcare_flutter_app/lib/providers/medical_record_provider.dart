import 'package:flutter/foundation.dart';

import '../models/medical_record_model.dart';
import '../services/medical_record_service.dart';

/// PUBLIC_INTERFACE
class MedicalRecordProvider extends ChangeNotifier {
  final MedicalRecordService _service;

  List<MedicalRecord> _items = [];
  MedicalRecord? _selected;
  bool _loading = false;
  String? _error;

  MedicalRecordProvider({MedicalRecordService? service}) : _service = service ?? MedicalRecordService();

  List<MedicalRecord> get items => _items;
  MedicalRecord? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  /// PUBLIC_INTERFACE
  Future<void> loadForPatient(String patientId) async {
    _setLoading(true);
    try {
      _items = await _service.listForPatient(patientId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// PUBLIC_INTERFACE
  Future<void> getById(String id) async {
    _setLoading(true);
    try {
      _selected = await _service.getById(id);
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

import 'package:flutter/foundation.dart';

import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

/// PUBLIC_INTERFACE
class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _service;

  List<Appointment> _items = [];
  Appointment? _selected;
  bool _loading = false;
  String? _error;

  AppointmentProvider({AppointmentService? service}) : _service = service ?? AppointmentService();

  List<Appointment> get items => _items;
  Appointment? get selected => _selected;
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
  Future<void> loadForDoctor(String doctorId) async {
    _setLoading(true);
    try {
      _items = await _service.listForDoctor(doctorId);
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

  /// PUBLIC_INTERFACE
  Future<void> create(Appointment a) async {
    _setLoading(true);
    try {
      final created = await _service.create(a);
      _items = [..._items, created];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// PUBLIC_INTERFACE
  Future<void> cancel(String id) async {
    _setLoading(true);
    try {
      await _service.cancel(id);
      _items = _items.map((e) => e.id == id ? Appointment(
        id: e.id,
        patientId: e.patientId,
        doctorId: e.doctorId,
        startTime: e.startTime,
        endTime: e.endTime,
        status: 'cancelled',
        notes: e.notes,
      ) : e).toList();
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

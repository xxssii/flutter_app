// lib/state/app_state.dart

import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isMeasuring = false; // State for sleep measurement
  bool get isMeasuring => _isMeasuring;

  void toggleMeasurement() {
    _isMeasuring = !_isMeasuring;
    notifyListeners();
  }

  // TODO: Add other app-wide states here, e.g., connected device status
}

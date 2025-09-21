// lib/state/sleep_data_state.dart

import 'package:flutter/material.dart';

class SleepDataState extends ChangeNotifier {
  String _selectedPeriod = '최근 30일';

  String get selectedPeriod => _selectedPeriod;

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    // TODO: 실제로 선택된 기간에 맞는 데이터를 로드하는 로직을 추가해야 합니다.
    notifyListeners();
  }
}

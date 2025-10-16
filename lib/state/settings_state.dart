// lib/state/settings_state.dart

import 'package:flutter/material.dart';

class SettingsState extends ChangeNotifier {
  // 다크 모드 상태
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // 알림 상태
  bool _isReportOn = true;
  bool _isEfficiencyOn = true;
  bool _isSnoringOn = true;
  bool _isGoalOn = true;
  bool _isGuideOn = true;
  bool _isPopupOn = true;

  bool get isReportOn => _isReportOn;
  bool get isEfficiencyOn => _isEfficiencyOn;
  bool get isSnoringOn => _isSnoringOn;
  bool get isGoalOn => _isGoalOn;
  bool get isGuideOn => _isGuideOn;
  bool get isPopupOn => _isPopupOn;

  // ----------------------------------------------------
  // ✅ 알람 시간 설정 상태 추가
  // ----------------------------------------------------
  TimeOfDay? _alarmTime;
  TimeOfDay? get alarmTime => _alarmTime;

  // 알람 상태
  bool _isAlarmOn = true;
  bool _isSmartWakeUpOn = true;
  bool _isVibrationOn = true;
  bool _isSoundOn = true;
  bool _isPillowAdjustOn = true;
  // bool _isSnoozeOn = true; <-- 삭제됨
  // String _snoozeDuration = '10분'; <-- 삭제됨

  bool get isAlarmOn => _isAlarmOn;
  bool get isSmartWakeUpOn => _isSmartWakeUpOn;
  bool get isVibrationOn => _isVibrationOn;
  bool get isSoundOn => _isSoundOn;
  bool get isPillowAdjustOn => _isPillowAdjustOn;
  // bool get isSnoozeOn => _isSnoozeOn; <-- 삭제됨
  // String get snoozeDuration => _snoozeDuration; <-- 삭제됨

  // 자동 조절 상태 (유지)
  bool _isAutoAdjustOn = true;
  bool get isAutoAdjustOn => _isAutoAdjustOn;

  // 상태 변경 메서드
  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void toggleReport(bool value) {
    _isReportOn = value;
    notifyListeners();
  }

  void toggleEfficiency(bool value) {
    _isEfficiencyOn = value;
    notifyListeners();
  }

  void toggleSnoring(bool value) {
    _isSnoringOn = value;
    notifyListeners();
  }

  void toggleGoal(bool value) {
    _isGoalOn = value;
    notifyListeners();
  }

  void toggleGuide(bool value) {
    _isGuideOn = value;
    notifyListeners();
  }

  void togglePopup(bool value) {
    _isPopupOn = value;
    notifyListeners();
  }

  // ----------------------------------------------------
  // ✅ 알람 시간 설정 메서드 추가/수정
  // ----------------------------------------------------
  void setAlarmTime(TimeOfDay newTime) {
    _alarmTime = newTime;
    // 시간을 설정하면 자동으로 알람을 켭니다.
    if (!_isAlarmOn) {
      _isAlarmOn = true;
    }
    notifyListeners();
    // TODO: 알람 스케줄링 로직 호출
  }

  void toggleAlarm(bool value) {
    _isAlarmOn = value;
    // 알람을 켰는데 시간이 설정 안 되어 있으면, 현재 시간을 기본값으로 설정
    if (value && _alarmTime == null) {
      _alarmTime = TimeOfDay.now();
    }
    notifyListeners();
    // TODO: 알람 스케줄링/취소 로직 추가
  }

  void toggleSmartWakeUp(bool value) {
    _isSmartWakeUpOn = value;
    notifyListeners();
  }

  void toggleVibration(bool value) {
    _isVibrationOn = value;
    notifyListeners();
  }

  void toggleSound(bool value) {
    _isSoundOn = value;
    notifyListeners();
  }

  void togglePillowAdjust(bool value) {
    _isPillowAdjustOn = value;
    notifyListeners();
  }

  // void toggleSnooze(bool value) { /* ... */ } <-- 삭제됨
  // void setSnoozeDuration(String duration) { /* ... */ } <-- 삭제됨

  void toggleAutoAdjust(bool value) {
    _isAutoAdjustOn = value;
    notifyListeners();
  }
}

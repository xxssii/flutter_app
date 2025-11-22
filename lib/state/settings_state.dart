// lib/state/settings_state.dart

import 'package:flutter/material.dart';
import '../services/notification_service.dart'; // 알림 서비스 임포트

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

  bool get isReportOn => _isReportOn;
  bool get isEfficiencyOn => _isEfficiencyOn;
  bool get isSnoringOn => _isSnoringOn;
  bool get isGoalOn => _isGoalOn;
  bool get isGuideOn => _isGuideOn;

  // 알람 시간 설정 상태
  TimeOfDay? _alarmTime;
  TimeOfDay? get alarmTime => _alarmTime;

  // 알람 상태
  bool _isAlarmOn = true;
  bool _isSmartWakeUpOn = true;
  bool _isSmartVibrationOn = true;
  bool _isSmartPillowAdjustOn = true;
  bool _isExactTimeAlarmOn = true;

  bool get isAlarmOn => _isAlarmOn;
  bool get isSmartWakeUpOn => _isSmartWakeUpOn;
  bool get isSmartVibrationOn => _isSmartVibrationOn;
  bool get isSmartPillowAdjustOn => _isSmartPillowAdjustOn;
  bool get isExactTimeAlarmOn => _isExactTimeAlarmOn;

  // 자동 조절 상태
  bool _isAutoAdjustOn = true;
  bool get isAutoAdjustOn => _isAutoAdjustOn;

  // --- 상태 변경 메서드 ---

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

  void toggleGuide(bool value) async {
    _isGuideOn = value; // 1. UI 상태 즉시 변경

    try {
      if (_isGuideOn) {
        // 2. 알림 예약 시도
        await NotificationService.instance.scheduleDailySleepTip();
      } else {
        // 3. 알림 취소 시도
        await NotificationService.instance.cancelAllNotifications();
      }
    } catch (e) {
      // 4. 알림 예약/취소에 실패하더라도 에러를 출력하고 넘어감
      print("알림 설정 중 오류 발생: $e");
    } finally {
      // 5. 알림 예약이 성공하든 실패하든, UI는 무조건 갱신
      notifyListeners();
    }
  }

  // 알람 시간 설정 메서드
  void setAlarmTime(TimeOfDay newTime) {
    _alarmTime = newTime;
    if (!_isAlarmOn) {
      _isAlarmOn = true;
    }
    notifyListeners();
  }

  // ✅ --- toggleAlarm 함수 수정 ---
  void toggleAlarm(bool value) {
    _isAlarmOn = value;

    if (value) {
      // 알람을 켰을 때
      // 시간이 설정 안 되어 있으면, 현재 시간을 기본값으로 설정
      if (_alarmTime == null) {
        _alarmTime = TimeOfDay.now();
      }
    } else {
      // 알람을 껐을 때
      // 모든 하위 알람 설정을 강제로 끕니다.
      _isSmartWakeUpOn = false;
      _isExactTimeAlarmOn = false;
      _isSmartVibrationOn = false;
      _isSmartPillowAdjustOn = false;
    }

    notifyListeners();
    // TODO: 알람 스케줄링/취소 로직 추가
  }

  // ✅ --- toggleSmartWakeUp 함수 수정 ---
  void toggleSmartWakeUp(bool value) {
    _isSmartWakeUpOn = value;

    if (!value) {
      // 스마트 기상이 꺼지면 하위 옵션(진동, 베개)도 끕니다.
      _isSmartVibrationOn = false;
      _isSmartPillowAdjustOn = false;
    }
    notifyListeners();
  }

  void toggleExactTimeAlarm(bool value) {
    _isExactTimeAlarmOn = value;
    notifyListeners();
  }

  void toggleSmartVibration(bool value) {
    _isSmartVibrationOn = value;
    notifyListeners();
  }

  void toggleSmartPillowAdjust(bool value) {
    _isSmartPillowAdjustOn = value;
    notifyListeners();
  }

  void toggleAutoAdjust(bool value) {
    _isAutoAdjustOn = value;
    notifyListeners();
  }
}

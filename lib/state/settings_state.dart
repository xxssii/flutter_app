// lib/state/settings_state.dart
// ✅ [최종 수정] isSmartAlarmOn 호환성 추가 및 Firestore 연동

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/notification_service.dart';

class SettingsState extends ChangeNotifier {
  // ========================================
  // 📦 상태 변수들
  // ========================================

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
  
  // ✅ [호환성 추가] AppState에서 사용하는 isSmartAlarmOn Getter
  bool get isSmartAlarmOn => _isSmartWakeUpOn; 

  // 자동 조절 상태
  bool _isAutoAdjustOn = true;
  bool get isAutoAdjustOn => _isAutoAdjustOn;
  
  // 진동 세기 상태 (0: 약하게, 1: 강하게)
  int _vibrationStrength = 1;
  int get vibrationStrength => _vibrationStrength;

  // ========================================
  // 🔧 초기화
  // ========================================

  SettingsState() {
    _loadSettings();
  }

  /// SharedPreferences에서 설정 불러오기
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 다크 모드
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;

      // 알림 설정
      _isReportOn = prefs.getBool('isReportOn') ?? true;
      _isEfficiencyOn = prefs.getBool('isEfficiencyOn') ?? true;
      _isSnoringOn = prefs.getBool('isSnoringOn') ?? true;
      _isGoalOn = prefs.getBool('isGoalOn') ?? true;
      _isGuideOn = prefs.getBool('isGuideOn') ?? true;

      // 알람 설정
      _isAlarmOn = prefs.getBool('isAlarmOn') ?? true;
      final hour = prefs.getInt('alarmHour') ?? 7;
      final minute = prefs.getInt('alarmMinute') ?? 0;
      _alarmTime = TimeOfDay(hour: hour, minute: minute);

      _isSmartWakeUpOn = prefs.getBool('isSmartWakeUpOn') ?? true;
      _isSmartVibrationOn = prefs.getBool('isSmartVibrationOn') ?? true;
      _isSmartPillowAdjustOn = prefs.getBool('isSmartPillowAdjustOn') ?? true;
      _isExactTimeAlarmOn = prefs.getBool('isExactTimeAlarmOn') ?? true;

      // 자동 조절
      _isAutoAdjustOn = prefs.getBool('isAutoAdjustOn') ?? true;
      
      // 진동 세기
      _vibrationStrength = prefs.getInt('vibrationStrength') ?? 1;

      notifyListeners();
      debugPrint('✅ 설정 불러오기 완료');
    } catch (e) {
      debugPrint('⚠️ 설정 불러오기 실패: $e');
    }
  }

  // ========================================
  // 🎨 다크 모드
  // ========================================

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  // ========================================
  // 🔔 알림 설정 (Firestore 연동)
  // ========================================

  Future<void> toggleReport(bool value) async {
    _isReportOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isReportOn', value);
    await _updateFirestoreNotificationSetting('sleepReport', value);
  }

  Future<void> toggleEfficiency(bool value) async {
    _isEfficiencyOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEfficiencyOn', value);
    await _updateFirestoreNotificationSetting('sleepScore', value);
  }

  Future<void> toggleSnoring(bool value) async {
    _isSnoringOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSnoringOn', value);
    await _updateFirestoreNotificationSetting('snoring', value);
  }

  Future<void> toggleGoal(bool value) async {
    _isGoalOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGoalOn', value);
    await _updateFirestoreNotificationSetting('goal', value);
  }

  Future<void> toggleGuide(bool value) async {
    _isGuideOn = value;

    try {
      if (_isGuideOn) {
        await NotificationService.instance.scheduleDailySleepTip();
      } else {
        await NotificationService.instance.cancelAllNotifications();
      }
    } catch (e) {
      debugPrint('⚠️ 알림 설정 중 오류 발생: $e');
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuideOn', value);
    await _updateFirestoreNotificationSetting('guide', value);
  }

  // ========================================
  // 📲 Firestore 업데이트 헬퍼 함수
  // ========================================

  Future<void> _updateFirestoreNotificationSetting(
    String settingType,
    bool enabled,
  ) async {
    try {
      const userId = 'demoUser';

      await NotificationService.instance.updateNotificationSettings(
        userId: userId,
        settingType: settingType,
        enabled: enabled,
      );

      debugPrint('✅ Firestore 알림 설정 업데이트: $settingType = $enabled');
    } catch (e) {
      debugPrint('❌ Firestore 업데이트 실패: $e');
    }
  }

  // ========================================
  // ⏰ 알람 설정
  // ========================================

  Future<void> setAlarmTime(TimeOfDay newTime) async {
    _alarmTime = newTime;

    if (!_isAlarmOn) {
      _isAlarmOn = true;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alarmHour', newTime.hour);
    await prefs.setInt('alarmMinute', newTime.minute);
    await prefs.setBool('isAlarmOn', true);
  }

  Future<void> toggleAlarm(bool value) async {
    _isAlarmOn = value;

    if (value) {
      if (_alarmTime == null) {
        _alarmTime = TimeOfDay.now();
      }
    } else {
      _isSmartWakeUpOn = false;
      _isExactTimeAlarmOn = false;
      _isSmartVibrationOn = false;
      _isSmartPillowAdjustOn = false;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAlarmOn', value);
  }

  Future<void> toggleSmartWakeUp(bool value) async {
    _isSmartWakeUpOn = value;

    if (!value) {
      _isSmartVibrationOn = false;
      _isSmartPillowAdjustOn = false;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSmartWakeUpOn', value);
  }
  
  // ✅ [호환성 추가] AppState에서 호출하는 메서드 연결
  void toggleSmartAlarm(bool value) {
      toggleSmartWakeUp(value);
  }

  Future<void> toggleExactTimeAlarm(bool value) async {
    _isExactTimeAlarmOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isExactTimeAlarmOn', value);
  }

  Future<void> toggleSmartVibration(bool value) async {
    _isSmartVibrationOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSmartVibrationOn', value);
  }

  Future<void> toggleSmartPillowAdjust(bool value) async {
    _isSmartPillowAdjustOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSmartPillowAdjustOn', value);
  }

  // ========================================
  // 🛏️ 자동 조절
  // ========================================

  Future<void> toggleAutoAdjust(bool value) async {
    _isAutoAdjustOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoAdjustOn', value);
  }

  // ========================================
  // 🔊 진동 세기
  // ========================================

  Future<void> setVibrationStrength(int value) async {
    _vibrationStrength = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vibrationStrength', value);
  }
}
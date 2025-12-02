// lib/state/settings_state.dart
// lib/state/settings_state.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ 추가!
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

  // 진동 세기 (0: 약하게, 1: 강하게)
  int _vibrationStrength = 1;
  int get vibrationStrength => _vibrationStrength;

  // 자동 조절 상태
  bool _isAutoAdjustOn = true;
  bool get isAutoAdjustOn => _isAutoAdjustOn;

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

      // 진동 세기 (0: 약하게, 1: 강하게) - 기본값: 강하게(1)
      _vibrationStrength = prefs.getInt('vibrationStrength') ?? 1;

      // 자동 조절
      _isAutoAdjustOn = prefs.getBool('isAutoAdjustOn') ?? true;

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

    // 1. SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isReportOn', value);

    // 2. ✅ Firestore에도 저장!
    await _updateFirestoreNotificationSetting('sleepReport', value);
  }

  Future<void> toggleEfficiency(bool value) async {
    _isEfficiencyOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEfficiencyOn', value);

    // ✅ Firestore 저장
    await _updateFirestoreNotificationSetting('sleepScore', value);
  }

  Future<void> toggleSnoring(bool value) async {
    _isSnoringOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSnoringOn', value);

    // ✅ Firestore 저장
    await _updateFirestoreNotificationSetting('snoring', value);
  }

  Future<void> toggleGoal(bool value) async {
    _isGoalOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGoalOn', value);

    // ✅ Firestore 저장 (goal 추가)
    await _updateFirestoreNotificationSetting('goal', value);
  }

  Future<void> toggleGuide(bool value) async {
    _isGuideOn = value;

    try {
      if (_isGuideOn) {
        // 알림 예약 시도
        await NotificationService.instance.scheduleDailySleepTip();
      } else {
        // 알림 취소 시도
        await NotificationService.instance.cancelAllNotifications();
      }
    } catch (e) {
      debugPrint('⚠️ 알림 설정 중 오류 발생: $e');
    }

    notifyListeners();

    // SharedPreferences 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuideOn', value);

    // ✅ Firestore 저장
    await _updateFirestoreNotificationSetting('guide', value);
  }

  // ========================================
  // 📲 Firestore 업데이트 헬퍼 함수
  // ========================================

  /// Firestore에 알림 설정 저장
  Future<void> _updateFirestoreNotificationSetting(
    String settingType,
    bool enabled,
  ) async {
    try {
      // TODO: 실제 로그인한 사용자 ID로 변경!
      const userId = 'demoUser';

      // NotificationService를 통해 Firestore 업데이트
      await NotificationService.instance.updateNotificationSettings(
        userId: userId,
        settingType: settingType,
        enabled: enabled,
      );

      debugPrint('✅ Firestore 알림 설정 업데이트: $settingType = $enabled');
    } catch (e) {
      debugPrint('❌ Firestore 업데이트 실패: $e');
      // 실패해도 앱 사용에는 문제없으므로 계속 진행
    }
  }

  // ========================================
  // ⏰ 알람 설정
  // ========================================

  /// 알람 시간 설정
  Future<void> setAlarmTime(TimeOfDay newTime) async {
    _alarmTime = newTime;

    // 시간을 설정하면 알람도 자동으로 켜짐
    if (!_isAlarmOn) {
      _isAlarmOn = true;
    }

    notifyListeners();

    // SharedPreferences 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alarmHour', newTime.hour);
    await prefs.setInt('alarmMinute', newTime.minute);
    await prefs.setBool('isAlarmOn', true);
  }

  /// 알람 ON/OFF
  Future<void> toggleAlarm(bool value) async {
    _isAlarmOn = value;

    if (value) {
      // 알람을 켰을 때: 시간이 없으면 현재 시간으로 설정
      if (_alarmTime == null) {
        _alarmTime = TimeOfDay.now();
      }
    } else {
      // 알람을 껐을 때: 모든 하위 설정도 끄기
      _isSmartWakeUpOn = false;
      _isExactTimeAlarmOn = false;
      _isSmartVibrationOn = false;
      _isSmartPillowAdjustOn = false;
    }

    notifyListeners();

    // SharedPreferences 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAlarmOn', value);

    // TODO: 알람 스케줄링/취소 로직 추가
  }

  /// 스마트 기상 ON/OFF
  Future<void> toggleSmartWakeUp(bool value) async {
    _isSmartWakeUpOn = value;

    if (!value) {
      // 스마트 기상 끄면 하위 옵션도 끄기
      _isSmartVibrationOn = false;
      _isSmartPillowAdjustOn = false;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSmartWakeUpOn', value);
  }

  /// 정확한 시간 알람 ON/OFF
  Future<void> toggleExactTimeAlarm(bool value) async {
    _isExactTimeAlarmOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isExactTimeAlarmOn', value);
  }

  /// 스마트 진동 ON/OFF
  Future<void> toggleSmartVibration(bool value) async {
    _isSmartVibrationOn = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSmartVibrationOn', value);
  }

  /// 진동 세기 설정 (0: 약하게, 1: 강하게)
  Future<void> setVibrationStrength(int value) async {
    _vibrationStrength = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vibrationStrength', value);
  }

  /// 스마트 베개 조절 ON/OFF
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
}

// lib/state/app_state.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/sleep_apnea_detector.dart';
import '../utils/sleep_score_analyzer.dart';
import '../services/notification_service.dart';
import '../widgets/apnea_warning_dialog.dart';
import '../widgets/apnea_report_dialog.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/ble_service.dart';
import '../state/settings_state.dart';
import '../screens/sleep_report_screen.dart'; // ✅ 1. SleepReportScreen 임포트 확인

// ✅ 2. 시연용으로 사용할 고정 ID 정의
const String DEMO_USER_ID = "capstone_demo_session_01";

// ✅ 3. 친구가 만든 Firebase 저장 함수 (수정)
Future<void> saveFakeSensorData({
  required double pressure,
  required bool snoring,
  required DateTime timestamp,
}) async {
  await FirebaseFirestore.instance.collection('raw_sensor_data').add({
    'pressure': pressure,
    'snoring': snoring,
    'timestamp': timestamp,
    'device_id': 'ESP32_Pillow',
    'user_id': DEMO_USER_ID, // ✅ 4. 하드코딩된 ID를 함께 저장
  });
  print('Firebase에 데이터 저장 완료: (사용자: $DEMO_USER_ID)');
}

class AppState extends ChangeNotifier {
  bool _isMeasuring = false;
  final List<String> _apneaEvents = [];

  BleService? _bleService;
  SettingsState? _settingsState;
  Timer? _sensorDataTimer; // 1초 타이머 (알람 확인용)

  // UI 표시를 위한 실시간 데이터 변수
  double _currentHeartRate = 60.0;
  double _currentSpo2 = 97.0;
  double _currentMovementScore = 0.5;

  bool get isMeasuring => _isMeasuring;
  List<String> get apneaEvents => _apneaEvents;
  double get currentHeartRate => _currentHeartRate;
  double get currentSpo2 => _currentSpo2;
  double get currentMovementScore => _currentMovementScore;
  double get currentPressure => _bleService?.pressureValue ?? 0.0;
  bool get isSnoringNow => _bleService?.isSnoring ?? false;

  void updateStates(BleService bleService, SettingsState settingsState) {
    if (_bleService != bleService) {
      _bleService?.removeListener(_onBleDataReceived);
      _bleService = bleService;
      _bleService?.addListener(_onBleDataReceived);
    }
    _settingsState = settingsState;
  }

  // BLE 데이터 수신 시 호출될 콜백 함수
  void _onBleDataReceived() {
    if (!_isMeasuring) return;

    final pressure = _bleService!.pressureValue;
    final snoring = _bleService!.isSnoring;
    final timestamp = DateTime.now();

    saveFakeSensorData(
      pressure: pressure,
      snoring: snoring,
      timestamp: timestamp,
    );

    // TODO: BLE에서 실제 심박수/SpO2/움직임 데이터 받아와서 아래 변수 업데이트
    // _currentHeartRate = ...
    // _currentSpo2 = ...
    // _currentMovementScore = ...

    notifyListeners();
  }

  void toggleMeasurement(BuildContext context) {
    _isMeasuring = !_isMeasuring;
    if (_isMeasuring) {
      _apneaEvents.clear();
      Provider.of<BleService>(context, listen: false).startScan();
      _startMockDataStream(context); // 1초 타이머 시작
    } else {
      _stopMockDataStream(); // 1초 타이머 중지
      _generatePostSleepReport(context);
    }
    notifyListeners();
  }

  // Mock 데이터 + 알람 확인용 타이머
  void _startMockDataStream(BuildContext context) {
    _sensorDataTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 1. Mock 데이터 업데이트 (시연용으로 유지)
      _currentHeartRate = (60 + (DateTime.now().millisecond % 5)).toDouble();
      _currentSpo2 = (96 + (DateTime.now().millisecond % 2)).toDouble();
      _currentMovementScore = (0.5 + (DateTime.now().second % 3)).toDouble();

      // 2. 1초마다 알람 시간 확인 로직 추가
      _checkAlarmTrigger(context);

      notifyListeners();

      // 3. 무호흡 감지 로직 (임시 주석 처리)
      /*
      checkApneaStatus(
        context: context,
        respirationDuration: _mockRespirationDuration,
        heartRateChange: _mockHeartRateChange,
        spo2Level: _currentSpo2,
        chestAbdomenMovement: _mockChestAbdomenMovement,
        isSnoringStopped: false,
        isSuddenInhalation: false,
      );
      */
    });
  }

  void _checkAlarmTrigger(BuildContext context) {
    if (_settingsState == null ||
        !_settingsState!.isAlarmOn ||
        _settingsState!.alarmTime == null) {
      return;
    }

    final now = DateTime.now();
    final alarmTime = _settingsState!.alarmTime!;

    if (_settingsState!.isExactTimeAlarmOn &&
        now.hour == alarmTime.hour &&
        now.minute == alarmTime.minute &&
        now.second == 0) {
      print("알람 시간 도달! (정확한 시간) 팔찌로 진동 명령 전송.");
      Provider.of<BleService>(context, listen: false).sendVibrationCommand();
    }
  }

  void _stopMockDataStream() {
    _sensorDataTimer?.cancel();
  }

  void checkApneaStatus({
    required BuildContext context,
    required double respirationDuration,
    required double heartRateChange,
    required double spo2Level,
    required double chestAbdomenMovement,
    required bool isSnoringStopped,
    required bool isSuddenInhalation,
  }) {
    final apneaDetector = SleepApneaDetector();

    final String? warningMessage = apneaDetector.detectApnea(
      respirationDuration: respirationDuration,
      heartRateChange: heartRateChange,
      spo2Level: spo2Level,
      chestAbdomenMovement: chestAbdomenMovement,
      isSnoringStopped: isSnoringStopped,
      isSuddenInhalation: isSuddenInhalation,
    );

    if (warningMessage != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ApneaWarningDialog(message: warningMessage);
        },
      );
      _apneaEvents.add('${DateTime.now().toLocal()} - $warningMessage');
      notifyListeners();
    }
  }

  void _generatePostSleepReport(BuildContext context) {
    final apneaDetector = SleepApneaDetector();
    final analyzer = SleepScoreAnalyzer();

    if (_settingsState == null) {
      print("SettingsState가 AppState에 주입되지 않았습니다.");
      return;
    }
    final settings = _settingsState!;

    final List<String> reportDetails = [];

    // 1. 임시 데이터로 최종 결과 생성 (TODO: 실제 집계 데이터로 변경)
    double finalSleepEfficiency = 80.0;
    double finalRemRatio = 22.0;
    double finalDeepSleepRatio = 18.0;
    double finalSnoringDuration = 30.0;

    // 2. 점수 및 리포트 생성
    int score = analyzer.getSleepScore(
      finalSleepEfficiency,
      finalRemRatio,
      finalDeepSleepRatio,
    );
    String reportBody = analyzer.generateDailyReport(score);
    String reportTitle = "어젯밤 수면 점수는 ${score}점입니다.";

    // 3. 수면 리포트 알림 (토글 켜져 있으면)
    if (settings.isReportOn) {
      NotificationService.instance.scheduleDailyReportNotification(
        reportTitle,
        reportBody,
      );
    }

    // 4. 수면 효율 경고 (토글 켜져 있으면)
    if (settings.isEfficiencyOn) {
      String? efficiencyWarning = analyzer.getEfficiencyWarning(
        finalSleepEfficiency,
      );
      if (efficiencyWarning != null) {
        reportDetails.add("경고: $efficiencyWarning");
        NotificationService.instance.showImmediateWarning(
          2,
          "수면 효율 저하",
          efficiencyWarning,
        );
      }
    }

    // 5. 코골이 경고 (토글 켜져 있으면)
    if (settings.isSnoringOn) {
      String? snoringWarning = analyzer.getSnoringWarning(finalSnoringDuration);
      if (snoringWarning != null) {
        reportDetails.add("경고: $snoringWarning");
        NotificationService.instance.showImmediateWarning(
          3,
          "심한 코골이 감지",
          snoringWarning,
        );
      }
    }

    // 6. 무호흡 리포트 (기존 로직)
    if (_apneaEvents.isNotEmpty) {
      reportDetails.add('--- 무호흡 감지 ---');
      reportDetails.addAll(_apneaEvents);
    } else {
      reportDetails.add('수면 중 무호흡 증상이 감지되지 않았습니다.');
    }

    // 7. 최종 리포트 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ApneaReportDialog(
          reportDetails: reportDetails,
          apneaEvents: _apneaEvents,
          onClose: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          },
          onViewDetails: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    const SleepReportScreen(key: Key('sleepReportScreen')),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _bleService?.removeListener(_onBleDataReceived);
    _sensorDataTimer?.cancel();
    super.dispose();
  }
}

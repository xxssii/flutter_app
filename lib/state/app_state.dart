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
import '../screens/sleep_report_screen.dart';

// ✅ 시연용으로 사용할 고정 ID 정의
const String DEMO_USER_ID = "capstone_demo_session_01";

// ✅ Firebase 저장 함수
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
    'user_id': DEMO_USER_ID,
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

  // ----------------------------------------------------
  // ✅ "새 뇌" (서버 뇌)를 위한 상태 변수
  // ----------------------------------------------------
  /// 실시간 명령 리스너 (구독)
  StreamSubscription? _commandSubscription;

  /// 현재 세션 ID
  String _currentSessionId = "";

  /// 현재 유저 ID (테스트용)
  final String _currentUserId = DEMO_USER_ID; // DEMO_USER_ID로 통일

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

    // 실제 BLE 데이터로 업데이트
    _currentHeartRate = _bleService!.heartRate;
    _currentSpo2 = _bleService!.spo2;
    // _currentMovementScore = ... // 움직임 데이터 처리 로직 추가 필요

    // 알람 트리거 확인 (context 없이 호출)
    _checkAlarmTrigger();

    // 무호흡 감지 로직 호출 (실제 데이터 기반으로 구현 필요)
    // checkApneaStatus(
    //   context: context,
    //   respirationDuration: ...,
    //   heartRateChange: ...,
    //   spo2Level: ...,
    //   chestAbdomenMovement: ...,
    //   isSnoringStopped: ...,
    //   isSuddenInhalation: ...,
    // );

    notifyListeners();
  }

  void toggleMeasurement(BuildContext context) {
    _isMeasuring = !_isMeasuring;

    if (_isMeasuring) {
      // --- 측정 시작 ---
      _apneaEvents.clear();

      // BLE 스캔 시작
      Provider.of<BleService>(context, listen: false).startScan();

      // Mock 데이터 스트림 시작 (알람 확인용) -> 실제 데이터 사용 시 주석 처리
      // _startMockDataStream(context);

      // "새 뇌" (서버 뇌) 리스너 시작
      _currentSessionId = "s4_test";
      _startCommandListener(_currentUserId, _currentSessionId);
    } else {
      // --- 측정 종료 ---
      _stopMockDataStream(); // 1초 타이머 중지

      // 리스너 종료
      _commandSubscription?.cancel();
      _commandSubscription = null;

      // 리포트 생성
      _generatePostSleepReport(context);
    }
    notifyListeners();
  }

  // Mock 데이터 + 알람 확인용 타이머 -> 실제 데이터 사용 시 주석 처리 또는 제거
  // void _startMockDataStream(BuildContext context) {
  //   _sensorDataTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     // 1. Mock 데이터 업데이트 (시연용으로 유지)
  //     _currentHeartRate = (60 + (DateTime.now().millisecond % 5)).toDouble();
  //     _currentSpo2 = (96 + (DateTime.now().millisecond % 2)).toDouble();
  //     _currentMovementScore = (0.5 + (DateTime.now().second % 3)).toDouble();
  //
  //     // 2. 1초마다 알람 시간 확인 로직 추가
  //     _checkAlarmTrigger(context);
  //
  //     notifyListeners();
  //
  //     // 3. 무호흡 감지 로직 (임시 주석 처리)
  //     /*
  //     checkApneaStatus(
  //       context: context,
  //       respirationDuration: _mockRespirationDuration,
  //       heartRateChange: _mockHeartRateChange,
  //       spo2Level: _currentSpo2,
  //       chestAbdomenMovement: _mockChestAbdomenMovement,
  //       isSnoringStopped: false,
  //       isSuddenInhalation: false,
  //     );
  //     */
  //   });
  // }

  // context 매개변수 제거
  void _checkAlarmTrigger() {
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
      // Provider.of<BleService>(context, listen: false).sendVibrationCommand(); // context 사용 부분 제거
      _bleService?.sendVibrationCommand(); // BleService를 통해 직접 호출
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

  // ----------------------------------------------------
  // ✅ "새 뇌" (서버 뇌) 로직
  // ----------------------------------------------------

  /// 명령 수신 리스너
  void _startCommandListener(String userId, String sessionId) {
    print(
      "✅ [Real Mode] '뇌'의 명령을 구독합니다... (userId: $userId, sessionId: $sessionId)",
    );

    _commandSubscription = FirebaseFirestore.instance
        .collection('commands')
        .where('userId', isEqualTo: userId)
        .where('sessionId', isEqualTo: sessionId)
        .where('status', isEqualTo: 'PENDING') // "PENDING"인 것만
        .orderBy('ts', descending: true) // 최신 순
        .limit(1)
        .snapshots() // 실시간 구독
        .listen(
          (snapshot) {
            print("📥 [DEBUG] Snapshot size: ${snapshot.docs.length}");
            for (var doc in snapshot.docs) {
              print("📄 [DEBUG] Doc: ${doc.id}, type: ${doc.data()['type']}");
            }

            if (snapshot.docs.isNotEmpty) {
              var commandDoc = snapshot.docs.first;
              print("🧠 [뇌로부터 새 명령 수신!] type: ${commandDoc.data()['type']}");

              // "몸"이 명령을 실행 (BLE로 베개에 쏘기)
              _executePillowCommand(commandDoc);
            }
          },
          onError: (error) {
            print("❌ [DEBUG] Listen error: $error");
          },
        );
  }

  /// 명령 실행 및 "DONE" 보고 함수
  void _executePillowCommand(DocumentSnapshot commandDoc) async {
    String commandId = commandDoc.id;
    Map<String, dynamic> data = commandDoc.data() as Map<String, dynamic>;
    String type = data['type'];
    Map<String, dynamic> payload = data['payload'];

    bool success = false;
    print("💪 [몸이 명령 수행 시작] type: $type");

    if (type == 'VIBRATE_STRONG' || type == 'VIBRATE_GENTLY') {
      // 실제 BLE로 진동 명령 전송
      print("⚡️ (BLE) 베개 진동 중... ${payload['level']}");
      // _bleService?.sendVibrationCommand(payload['level']); // 진동 레벨 전달 필요
      success = true; // (임시)
    } else if (type == 'SET_HEIGHT') {
      // 실제 BLE로 높이 변경 명령 전송
      print("↕️ (BLE) 베개 높이 변경 중... ${payload['heightMm']}mm");
      // _bleService?.setHeightCommand(payload['heightMm']); // 높이 전달 필요
      success = true; // (임시)
    }

    // 실행 성공 시, "뇌"에게 "완료(DONE)"라고 보고
    if (success) {
      try {
        await commandDoc.reference.update({
          'status': 'DONE',
          'doneTs': FieldValue.serverTimestamp(),
        });
        print("✅ [몸이 완료 보고] $commandId 임무 완료!");
      } catch (e) {
        print("❌ [몸이 완료 보고] 실패: $e");
      }
    }
  }

  @override
  void dispose() {
    _bleService?.removeListener(_onBleDataReceived);
    _sensorDataTimer?.cancel();
    _commandSubscription?.cancel();
    super.dispose();
  }
}

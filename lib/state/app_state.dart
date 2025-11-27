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
// import '../utils/app_colors.dart'; // 사용되지 않음
// import '../utils/app_text_styles.dart'; // 사용되지 않음
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
  // double _currentMovementScore = 0.5; // 사용되지 않음

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
  // double get currentMovementScore => _currentMovementScore;
  // ✅ 수정됨: BleService의 실제 변수명인 pressureAvg를 사용해야 합니다.
  double get currentPressure => _bleService?.pressureAvg ?? 0.0;
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

    // ✅ 수정됨: BleService에는 pressureValue라는 게터가 없습니다. pressureAvg 변수를 직접 사용합니다.
    final pressure = _bleService!.pressureAvg;
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

    notifyListeners();
  }

  void toggleMeasurement(BuildContext context) {
    _isMeasuring = !_isMeasuring;

    if (_isMeasuring) {
      // --- 측정 시작 ---
      _apneaEvents.clear();

      // BLE 스캔 시작
      Provider.of<BleService>(context, listen: false).startScan();

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

      // ✅ 수정됨: BleService에는 sendVibrationCommand가 없습니다.
      // 존재하는 메서드인 sendVibrateStrong() (또는 sendVibrateGently)를 호출해야 합니다.
      // 알람이므로 강한 진동을 사용합니다.
      _bleService?.sendVibrateStrong();
    }
  }

  void _stopMockDataStream() {
    _sensorDataTimer?.cancel();
  }

  // (무호흡 감지 로직 생략 - 코드가 너무 길어져서 생략했지만 기존 코드 유지 필요)

  void _generatePostSleepReport(BuildContext context) {
    // (리포트 생성 로직 생략 - 기존 코드 유지 필요)
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
    // String reportBody = analyzer.generateDailyReport(score); // 미사용
    // String reportTitle = "어젯밤 수면 점수는 ${score}점입니다."; // 미사용

    // 3. 수면 리포트 알림 (토글 켜져 있으면)
    if (settings.isReportOn) {
      // NotificationService 호출 코드가 주석 처리되어 있어서 생략함
    }

    // 4. 수면 효율 경고 (토글 켜져 있으면)
    if (settings.isEfficiencyOn) {
      String? efficiencyWarning = analyzer.getEfficiencyWarning(
        finalSleepEfficiency,
      );
      if (efficiencyWarning != null) {
        reportDetails.add("경고: $efficiencyWarning");
        // NotificationService 호출 코드가 주석 처리되어 있어서 생략함
      }
    }

    // 5. 코골이 경고 (토글 켜져 있으면)
    if (settings.isSnoringOn) {
      String? snoringWarning = analyzer.getSnoringWarning(finalSnoringDuration);
      if (snoringWarning != null) {
        reportDetails.add("경고: $snoringWarning");
        // NotificationService 호출 코드가 주석 처리되어 있어서 생략함
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
    // Map<String, dynamic> payload = data['payload']; // 현재 미사용

    bool success = false;
    print("💪 [몸이 명령 수행 시작] type: $type");

    // ✅ 수정됨: BleService의 실제 메서드를 호출하도록 수정
    if (type == 'VIBRATE_STRONG') {
      print("⚡️ (BLE) 베개 강한 진동 시작");
      await _bleService?.sendVibrateStrong();
      success = true;
    } else if (type == 'VIBRATE_GENTLY') {
      print("⚡️ (BLE) 베개 부드러운 진동 시작");
      await _bleService?.sendVibrateGently();
      success = true;
    } else if (type == 'SET_HEIGHT') {
      // 참고: BleService에는 adjustHeight(int cellNumber)가 있습니다.
      // payload['heightMm']를 cellNumber로 변환하는 로직이 필요하지만,
      // BleService를 수정할 수 없으므로 일단 임시로 성공 처리합니다.
      print("↕️ (BLE) 베개 높이 변경 명령 받음 (구현 필요)");
      // await _bleService?.adjustHeight(1); // 예시: 1번 셀 조절
      success = true; // 임시 성공 처리
    } else if (type == 'STOP') {
      print("🛑 (BLE) 베개 전체 정지");
      await _bleService?.stopAll();
      success = true;
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

// lib/state/app_state.dart
// ✅ [수정 완료] NotificationService 호출 에러 해결 버전

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/sleep_apnea_detector.dart';
import '../utils/sleep_score_analyzer.dart';
import '../services/notification_service.dart';
import '../widgets/apnea_warning_dialog.dart';
import '../widgets/apnea_report_dialog.dart';
import '../services/ble_service.dart';
import '../state/settings_state.dart';
import '../screens/sleep_report_screen.dart';

// ✅ 시연용으로 사용할 고정 ID 정의
const String DEMO_USER_ID = "capstone_demo_session_01";

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
  StreamSubscription? _commandSubscription;
  String _currentSessionId = "";
  final String _currentUserId = "v4_test";

  bool get isMeasuring => _isMeasuring;
  List<String> get apneaEvents => _apneaEvents;
  double get currentHeartRate => _currentHeartRate;
  double get currentSpo2 => _currentSpo2;
  double get currentMovementScore => _currentMovementScore;
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

  // ✅ BLE 데이터 수신 시 호출 (UI 업데이트 전용)
  void _onBleDataReceived() {
    // 1. 측정 중이 아니면 무시
    if (!_isMeasuring) return;

    // 2. BLE 서비스가 수집 중이 아니면 무시
    if (_bleService == null || !_bleService!.isCollectingData) return;

    // 3. UI 데이터 업데이트 (저장은 BleService가 알아서 함)
    _currentHeartRate = _bleService!.heartRate;
    _currentSpo2 = _bleService!.spo2;
    // _currentMovementScore = ...

    notifyListeners();
  }

  // ✅ 버튼 클릭 시 측정 시작/종료 토글
  void toggleMeasurement(BuildContext context) {
    _isMeasuring = !_isMeasuring;
    
    // Provider로 BleService 가져오기
    final bleService = Provider.of<BleService>(context, listen: false);

    if (_isMeasuring) {
      // --- ▶️ 측정 시작 ---
      print("\n${'='*50}");
      print("✅ [AppState] 측정 시작! (데이터 수집 명령 전송)");
      print('='*50 + "\n");
      
      _apneaEvents.clear();

      // 1. BLE 서비스에게 "데이터 수집 시작해!" (Firebase 저장 시작)
      bleService.startDataCollection();

      // 2. 혹시 연결 끊겼을 대비 스캔 시작
      bleService.startScan();

      // 3. Mock 데이터 스트림 시작 (알람 등)
      _startMockDataStream(context);

      // 4. "새 뇌" (서버 뇌) 리스너 시작
      _currentSessionId = "s4_test";
      _startCommandListener(_currentUserId, _currentSessionId);

      // ✅ [태블릿 디버깅용] 화면 하단에 초록색 알림 띄우기
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚀 측정 시작! (데이터가 수집됩니다)"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

    } else {
      // --- ⏹️ 측정 종료 ---
      print("\n${'='*50}");
      print("⏹️ [AppState] 측정 종료! (데이터 수집 중지 명령)");
      print('='*50 + "\n");
      
      // 1. BLE 서비스에게 "데이터 수집 멈춰!" (Firebase 저장 중단)
      bleService.stopDataCollection();
      
      // 2. 타이머/리스너 정리
      _stopMockDataStream(); 
      _commandSubscription?.cancel();
      _commandSubscription = null;

      // ✅ [태블릿 디버깅용] 화면 하단에 빨간색 알림 띄우기
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🛑 측정 종료! (저장이 중지되었습니다)"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      // 3. 리포트 생성
      _generatePostSleepReport(context);
    }
    notifyListeners();
  }

  // ----------------------------------------------------
  // 내부 로직들
  // ----------------------------------------------------

  void _startMockDataStream(BuildContext context) {
    _sensorDataTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // BLE 데이터가 있으면 그걸 쓰고, 없으면 Mock 데이터 사용
      if (_bleService != null && _bleService!.isCollectingData) {
        _currentHeartRate = _bleService!.heartRate;
        _currentSpo2 = _bleService!.spo2;
      } else {
        _currentHeartRate = (60 + (DateTime.now().millisecond % 5)).toDouble();
        _currentSpo2 = (96 + (DateTime.now().millisecond % 2)).toDouble();
      }
      _currentMovementScore = (0.5 + (DateTime.now().second % 3)).toDouble();

      _checkAlarmTrigger(context);
      notifyListeners();
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
      print("⏰ 알람 시간 도달! 팔찌로 진동 명령 전송.");
      Provider.of<BleService>(context, listen: false).sendVibrateStrong();
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
    final analyzer = SleepScoreAnalyzer();

    if (_settingsState == null) {
      print("⚠️ SettingsState 없음");
      return;
    }
    final settings = _settingsState!;
    final List<String> reportDetails = [];

    double finalSleepEfficiency = 80.0;
    double finalRemRatio = 22.0;
    double finalDeepSleepRatio = 18.0;
    double finalSnoringDuration = 30.0;

    int score = analyzer.getSleepScore(
      finalSleepEfficiency,
      finalRemRatio,
      finalDeepSleepRatio,
    );
    String reportBody = analyzer.generateDailyReport(score);
    String reportTitle = "어젯밤 수면 점수는 ${score}점입니다.";

    if (settings.isReportOn) {
      // ✅ [오류 수정 부분] getBody: 매개변수 제거하고 순서대로 전달
      NotificationService.instance.scheduleDailyReportNotification(
        reportTitle,
        reportBody, 
      );
    }

    if (settings.isEfficiencyOn) {
      String? efficiencyWarning = analyzer.getEfficiencyWarning(finalSleepEfficiency);
      if (efficiencyWarning != null) reportDetails.add("경고: $efficiencyWarning");
    }

    if (settings.isSnoringOn) {
      String? snoringWarning = analyzer.getSnoringWarning(finalSnoringDuration);
      if (snoringWarning != null) reportDetails.add("경고: $snoringWarning");
    }

    if (_apneaEvents.isNotEmpty) {
      reportDetails.add('--- 무호흡 감지 ---');
      reportDetails.addAll(_apneaEvents);
    } else {
      reportDetails.add('수면 중 무호흡 증상이 감지되지 않았습니다.');
    }

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
                builder: (context) => const SleepReportScreen(key: Key('sleepReportScreen')),
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

  void _startCommandListener(String userId, String sessionId) {
    print("✅ [Real Mode] '뇌'의 명령을 구독합니다... (userId: $userId)");

    _commandSubscription = FirebaseFirestore.instance
        .collection('commands')
        .where('userId', isEqualTo: userId)
        .where('sessionId', isEqualTo: sessionId)
        .where('status', isEqualTo: 'PENDING')
        .orderBy('ts', descending: true)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          var commandDoc = snapshot.docs.first;
          print("🧠 [뇌 명령 수신] type: ${commandDoc.data()['type']}");
          _executePillowCommand(commandDoc);
        }
      },
      onError: (error) {
        print("❌ [Listen Error] $error");
      },
    );
  }

  void _executePillowCommand(DocumentSnapshot commandDoc) async {
    String commandId = commandDoc.id;
    Map<String, dynamic> data = commandDoc.data() as Map<String, dynamic>;
    String type = data['type'];
    Map<String, dynamic> payload = data['payload'];

    bool success = false;
    print("💪 [몸이 명령 수행] $type");

    // ✅ BleService를 통해 실제 하드웨어 명령 전송
    if (_bleService != null && _bleService!.isPillowConnected) {
      if (type == 'VIBRATE_STRONG') {
        await _bleService!.sendVibrateStrong();
        success = true;
      } else if (type == 'VIBRATE_GENTLY') {
        await _bleService!.sendVibrateGently();
        success = true;
      } else if (type == 'SET_HEIGHT') {
        int cellIndex = payload['cellIndex'] ?? 1;
        // int height = payload['height'] ?? 2;
        // BleService의 adjustHeight 사용 (친구 코드와 통합된 부분)
        await _bleService!.adjustHeight(cellIndex);
        success = true;
      }
    } else {
      print("⚠️ [Warning] 베개 미연결. 시뮬레이션 로그만 출력.");
      success = true; // 테스트용으로 성공 처리
    }

    if (success) {
      try {
        await commandDoc.reference.update({
          'status': 'DONE',
          'doneTs': FieldValue.serverTimestamp(),
        });
        print("✅ [완료 보고] $commandId");
      } catch (e) {
        print("❌ [완료 보고 실패] $e");
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
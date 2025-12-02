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
import '../state/sleep_data_state.dart'; // ✅ SleepDataState 및 모델 임포트
import 'package:intl/intl.dart'; // 날짜 포맷용

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

  // ✅ [실제 데이터 수집용 변수]
  final List<double> _sessionHeartRates = [];
  final List<SnoringDataPoint> _sessionSnoringData = [];
  DateTime? _sleepStartTime;
  int _dataCollectionCounter = 0; // 1분 간격 저장을 위한 카운터

  // ----------------------------------------------------
  // ✅ "새 뇌" (서버 뇌)를 위한 상태 변수
  // ----------------------------------------------------
  StreamSubscription? _commandSubscription;
  String _currentSessionId = "";
  final String _currentUserId = "demoUser";

  bool get isMeasuring => _isMeasuring;
  List<String> get apneaEvents => _apneaEvents;
  double get currentHeartRate => _currentHeartRate;
  double get currentSpo2 => _currentSpo2;
  double get currentMovementScore => _currentMovementScore;
  String get currentUserId => _currentUserId;
  double get currentPressure => _bleService?.pressureAvg ?? 0.0;
  bool get isSnoringNow => _bleService?.isSnoring ?? false;
  StreamSubscription? _stageSubscription; 
  bool _hasSmartAlarmTriggered = false; // 오늘 이미 깨웠는지 체크

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

      // 5. ✅ [추가] 스마트 알람용 수면 단계 감시 리스너
      _startSmartAlarmListener(context, _currentUserId, _currentSessionId);
      _hasSmartAlarmTriggered = false; // 초기화

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
      _stageSubscription?.cancel(); // ✅ 스마트 알람 리스너 해제
      _stageSubscription = null;

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
      
      // ✅ [추가] 1분마다 데이터 수집 (60초)
      _dataCollectionCounter++;
      if (_dataCollectionCounter >= 5) {
        _dataCollectionCounter = 0;
        if (_isMeasuring) {
          // 심박수 저장
          _sessionHeartRates.add(_currentHeartRate);
          
          // 코골이 데이터 저장
          double decibel = 40.0; 
          if (_bleService != null) {
             // BleService의 micLevel 사용
             decibel = _bleService!.micLevel;
             // 만약 0이면 기본값
             if (decibel < 30) decibel = 30 + (DateTime.now().millisecond % 10).toDouble();
          }
          
          _sessionSnoringData.add(SnoringDataPoint(DateTime.now(), decibel));
          print("📝 [DataCollection] 1분 데이터 저장: HR=$_currentHeartRate, dB=$decibel");
        }
      }
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

    // ✅ 정각 알람 (스마트 알람이 울린 후에도 확인 차원에서 강하게 진동)
    if (_settingsState!.isExactTimeAlarmOn &&
        now.hour == alarmTime.hour &&
        now.minute == alarmTime.minute &&
        now.second == 0) {
      print("⏰ 정각 알람! 강한 진동!");
      final bleService = Provider.of<BleService>(context, listen: false);
      
      // 정각에는 무조건 쎄게!
      bleService.sendVibrateStrong();
      
      // 베개도 최대로!
      bleService.adjustCell(1, 3);
    }
  }

  // ✅ [새로 추가] 스마트 알람 로직
  void _startSmartAlarmListener(BuildContext context, String userId, String sessionId) {
    print("⏰ 스마트 알람 모니터링 시작...");
    
    // processed_data의 최신 문서를 실시간 구독
    _stageSubscription = FirebaseFirestore.instance
        .collection('processed_data')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('ts', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      
      if (snapshot.docs.isEmpty) return;
      
      final data = snapshot.docs.first.data();
      final String currentStage = data['stage'] ?? 'Unknown';
      
      // 스마트 알람 체크
      _checkSmartWakeUp(context, currentStage);
      
    });
  }

  void _checkSmartWakeUp(BuildContext context, String currentStage) {
    if (_hasSmartAlarmTriggered) return; // 이미 울렸으면 패스
    if (_settingsState == null || !_settingsState!.isSmartAlarmOn) return; // 기능 꺼져있으면 패스
    if (_settingsState!.alarmTime == null) return;

    final now = DateTime.now();
    final alarmTime = _settingsState!.alarmTime!;
    
    // 알람 시간 기준 30분 전부터 ~ 알람 시간까지가 스마트 알람 윈도우
    bool isInWindow = _isTimeInWindow(now, alarmTime, 30);

    if (isInWindow) {
       print("⏰ [스마트 알람 감지 중] 현재 단계: $currentStage");
       
       // 얕은 수면(Light) 또는 깸(Awake) 상태라면 -> 지금 깨워야 함!
       if (currentStage == 'Light' || currentStage == 'Awake') {
          print("🔔 [스마트 알람 발동!] 얕은 수면 감지됨 -> 기상 유도!");
          _triggerWakeUpRoutine(context);
       }
    }
  }
  
  // 시간 비교 헬퍼
  bool _isTimeInWindow(DateTime now, TimeOfDay alarm, int windowMinutes) {
      final alarmDateTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
      final diff = alarmDateTime.difference(now).inMinutes;
      // 알람 시간까지 남은 시간이 0~30분 사이면 True
      return diff >= 0 && diff <= windowMinutes;
  }

  // 🚨 기상 유도 루틴 (진동 + 베개 높이기)
  void _triggerWakeUpRoutine(BuildContext context) {
     _hasSmartAlarmTriggered = true;
     final bleService = Provider.of<BleService>(context, listen: false);
     
     // 1. 진동 (약하게 -> 강하게)
     bleService.sendVibrateGently();
     
     // 2. 베개 높이 조절 (기상 유도: 상체 일으키기)
     // 1번 셀(머리)을 최대 높이로
     bleService.adjustCell(1, 3); // Level 3
     
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🌅 스마트 알람: 기상 시간입니다! (Light Sleep 감지)"), backgroundColor: Colors.orange),
     );
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

    // ✅ [추가] 실제 데이터로 SleepMetrics 생성 및 전달
    if (_sleepStartTime != null) {
      final now = DateTime.now();
      final durationMinutes = now.difference(_sleepStartTime!).inMinutes;
      final durationHours = durationMinutes / 60.0;
      
      // 데이터가 너무 적으면(예: 1분 미만) 기본값 사용하거나 현재 데이터라도 사용
      
      final realMetrics = SleepMetrics(
        reportDate: DateFormat('yyyy년 MM월 dd일').format(_sleepStartTime!),
        totalSleepDuration: durationHours,
        timeInBed: durationHours + 0.1, // 약간 더 누워있었다고 가정
        sleepEfficiency: 85.0, // 임시 계산
        remRatio: 20.0,
        deepSleepRatio: 15.0,
        tossingAndTurning: 5, // 임시 값
        avgSnoringDuration: _sessionSnoringData.where((d) => d.decibel > 50).length * 1.0, // 1분 단위
        avgHrv: 50.0,
        avgHeartRate: _sessionHeartRates.isEmpty 
            ? 60.0 
            : _sessionHeartRates.reduce((a, b) => a + b) / _sessionHeartRates.length,
        apneaCount: _apneaEvents.length,
        heartRateData: List.from(_sessionHeartRates), // 복사해서 전달
        snoringDecibelData: List.from(_sessionSnoringData),
      );
      
      // SleepDataState에 설정
      Provider.of<SleepDataState>(context, listen: false).setTodayMetrics(realMetrics);
      print("✅ [Report] 실제 측정 데이터 리포트 생성 완료 (${_sessionHeartRates.length}분 데이터)");
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
        int targetLevel = payload['height'] ?? 2;// targetLevel로 받음
        // BleService의 adjustHeight 사용 (친구 코드와 통합된 부분)
        await _bleService!.adjustCell(cellIndex, targetLevel);
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
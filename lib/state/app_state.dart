// lib/state/app_state.dart

import 'package:flutter/material.dart';
import 'dart:async'; // Timer 사용을 위해 추가
import '../utils/sleep_apnea_detector.dart';
import '../widgets/apnea_warning_dialog.dart';
import '../widgets/apnea_report_dialog.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class AppState extends ChangeNotifier {
  // <-- ChangeNotifier를 상속받아 notifyListeners 사용 가능하게 함
  bool _isMeasuring = false;

  final List<String> _apneaEvents = []; // <-- 클래스 멤버 변수로 올바르게 정의
  Timer? _sensorDataTimer;

  // Mock Data Variables (ESP32)
  double _currentHeartRate = 60.0;
  double _currentSpo2 = 97.0;
  double _currentMovementScore = 0.5;
  double _mockRespirationDuration = 3.0;
  double _mockHeartRateChange = 1.0;
  double _mockChestAbdomenMovement = 5.0;

  bool get isMeasuring => _isMeasuring;
  List<String> get apneaEvents => _apneaEvents;
  double get currentHeartRate => _currentHeartRate;
  double get currentSpo2 => _currentSpo2;
  double get currentMovementScore => _currentMovementScore;

  void toggleMeasurement(BuildContext context) {
    _isMeasuring = !_isMeasuring;
    if (_isMeasuring) {
      _apneaEvents.clear();
      _startMockDataStream(context);
    } else {
      // 측정 종료 시, 리포트 팝업을 띄우는 로직만 실행합니다.
      _stopMockDataStream();
      _generateApneaReport(context);
      // **화면을 닫는 Navigator.pop()은 여기서 제거합니다.**
    }
    notifyListeners();
  }

  void _startMockDataStream(BuildContext context) {
    _sensorDataTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Mock Data Updates
      _currentHeartRate = (60 + (DateTime.now().millisecond % 5)).toDouble();
      _currentSpo2 = (96 + (DateTime.now().millisecond % 2)).toDouble();
      _currentMovementScore = (0.5 + (DateTime.now().second % 3)).toDouble();

      if (DateTime.now().second % 15 == 0) {
        _mockRespirationDuration = 12.0;
        _mockHeartRateChange = 15.0;
      } else {
        _mockRespirationDuration = 3.0;
        _mockHeartRateChange = 1.0;
      }

      notifyListeners();

      checkApneaStatus(
        context: context,
        respirationDuration: _mockRespirationDuration,
        heartRateChange: _mockHeartRateChange,
        spo2Level: _currentSpo2,
        chestAbdomenMovement: _mockChestAbdomenMovement,
        isSnoringStopped: false,
        isSuddenInhalation: false,
      );
    });
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

  void _generateApneaReport(BuildContext context) {
    final apneaDetector = SleepApneaDetector();
    final List<String> reportDetails = [];

    reportDetails.add(apneaDetector.getSnoringWarning(25.0));
    reportDetails.add(apneaDetector.getHrvWarning(25.0));

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
            Navigator.of(dialogContext).pop(); // 1. 리포트 다이얼로그를 닫습니다.
            Navigator.of(context).pop(); // 2. 그 후, 뒤에 있던 SMainMoonScreen을 닫습니다.
          },
        );
      },
    );
  }
}

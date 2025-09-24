import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/sleep_apnea_detector.dart';
import '../widgets/apnea_warning_dialog.dart';
import '../widgets/apnea_report_dialog.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class AppState extends ChangeNotifier {
  bool _isMeasuring = false;

  final List<String> _apneaEvents = [];

  bool get isMeasuring => _isMeasuring;
  List<String> get apneaEvents => _apneaEvents;

  void toggleMeasurement(BuildContext context) {
    _isMeasuring = !_isMeasuring;
    if (_isMeasuring) {
      _apneaEvents.clear();
      // TODO: 실제 센서 데이터 수집 로직을 여기에 구현하세요.
    } else {
      _generateApneaReport(context);
    }
    notifyListeners();
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
    // 수면 종료 후 리포트 팝업을 보여주는 메서드
    final apneaDetector = SleepApneaDetector();
    final List<String> reportDetails = [];

    // 가상의 데이터로 코골이, HRV 경고를 생성합니다.
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
          apneaEvents: _apneaEvents, // 누락된 'apneaEvents' 매개변수 추가
          onClose: () {
            // 'onClose' 콜백 함수 추가
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

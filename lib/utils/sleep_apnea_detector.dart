// lib/utils/sleep_apnea_detector.dart

import 'package:flutter/material.dart';

class SleepApneaDetector {
  // 베개 높이를 조절하는 가상의 메서드
  void _adjustPillowHeight() {
    print("수면 무호흡 감지: 베개 높이를 조절합니다.");
    // TODO: 여기에 실제 베개 높이 조절 로직을 추가하세요.
  }

  String? detectApnea({
    required double respirationDuration, // 호흡 주기 시간 (초)
    required double heartRateChange, // 심박수 변화량 (BPM)
    required double spo2Level, // 산소포화도 (%)
    required double chestAbdomenMovement, // 가슴/복부 움직임 (스코어, 0-10)
    required bool isSnoringStopped, // 코골이 정지 여부
    required bool isSuddenInhalation, // 급격한 들숨 감지 여부
  }) {
    if (respirationDuration >= 10.0) {
      _adjustPillowHeight();
      return "10초 이상 호흡 정지 감지. 베개 높이를 조절합니다.";
    }

    if (spo2Level <= 90.0) {
      _adjustPillowHeight();
      return "산소포화도 급락 (SpO₂ < 90%). 베개 높이를 조절합니다.";
    }

    if (heartRateChange >= 10.0) {
      _adjustPillowHeight();
      return "심박수 급격한 변화 감지. 베개 높이를 조절합니다.";
    }

    if (chestAbdomenMovement < 0.5) {
      _adjustPillowHeight();
      return "가슴/복부 움직임 정지 감지. 베개 높이를 조절합니다.";
    }

    if (isSnoringStopped && isSuddenInhalation) {
      _adjustPillowHeight();
      return "코골이 정지 후 급격한 들숨 감지. 베개 높이를 조절합니다.";
    }

    return null;
  }

  // 코골이 지속 시간에 따른 수면 무호흡증 의심 메시지 반환
  String getSnoringWarning(double snoringTime) {
    if (snoringTime > 20.0) {
      return '코골이 지속 시간이 20분을 초과했습니다. 수면 무호흡증이 의심됩니다. 전문가와 상담해보세요.';
    }
    return '양호한 수준의 코골이입니다.';
  }

  // HRV에 따른 스트레스/수면 질 저하 경고 반환
  String getHrvWarning(double hrv) {
    if (hrv < 30.0) {
      return 'HRV가 지속적으로 감소했습니다. 스트레스 관리가 필요합니다.';
    }
    return '양호한 HRV 수준입니다.';
  }
}

// lib/utils/sleep_score_analyzer.dart

import 'package:flutter/material.dart';

class SleepScoreAnalyzer {
  double analyzeSleepData({
    required double totalSleepTime,
    required int wakeUpCount,
    required int tossingAndTurningCount,
    required double snoringTime,
    required double avgHeartRate,
    required double hrv,
    required double sleepEfficiency,
    required double remRatio,
    required double deepSleepRatio,
  }) {
    double totalScore = 0.0;

    // 각 지표에 대한 점수 계산 로직
    // 점수는 0~100 사이의 값으로 계산하며, 100이 가장 좋은 점수

    // 1. 총 수면 시간 (7-9시간이 Good)
    if (totalSleepTime >= 7.0 && totalSleepTime <= 9.0) {
      totalScore += 15.0;
    } else if (totalSleepTime > 6.0 && totalSleepTime < 10.0) {
      totalScore += 10.0;
    } else {
      totalScore += 5.0;
    }

    // 2. 기상 횟수 (0-1회가 Good)
    if (wakeUpCount <= 1) {
      totalScore += 10.0;
    } else if (wakeUpCount == 2) {
      totalScore += 5.0;
    } else {
      totalScore += 0.0;
    }

    // 3. 뒤척임 횟수 (10회 이하가 Good)
    if (tossingAndTurningCount <= 10) {
      totalScore += 15.0; // 배점 조정
    } else if (tossingAndTurningCount <= 20) {
      totalScore += 7.5;
    } else {
      totalScore += 0.0;
    }

    // 4. 코골이 시간 (< 5분이 Good)
    if (snoringTime < 5.0) {
      totalScore += 10.0;
    } else if (snoringTime >= 5.0 && snoringTime <= 20.0) {
      totalScore += 5.0;
    } else {
      totalScore += 0.0;
    }

    // 5. 평균 심박수 (50-65 bpm이 Good)
    if (avgHeartRate >= 50.0 && avgHeartRate <= 65.0) {
      totalScore += 15.0;
    } else if (avgHeartRate > 45.0 && avgHeartRate < 75.0) {
      totalScore += 10.0;
    } else {
      totalScore += 5.0;
    }

    // 6. 심박 변이도 (HRV) (> 50ms가 Good)
    if (hrv > 50.0) {
      totalScore += 10.0;
    } else if (hrv >= 30.0 && hrv <= 50.0) {
      totalScore += 5.0;
    } else {
      totalScore += 0.0;
    }

    // 7. 수면 효율 (85% 이상이 Good)
    if (sleepEfficiency >= 85.0) {
      totalScore += 10.0;
    } else {
      totalScore += 5.0;
    }

    // 8. REM 비율 (25%가 Good)
    if (remRatio >= 20.0 && remRatio <= 30.0) {
      // 25%를 중심으로 5% 범위
      totalScore += 10.0; // 배점 조정
    } else if (remRatio > 15.0 && remRatio < 35.0) {
      totalScore += 5.0;
    } else {
      totalScore += 0.0;
    }

    // 9. 깊은 수면 (N3) 비율 (15%가 Good)
    if (deepSleepRatio >= 10.0 && deepSleepRatio <= 20.0) {
      // 15%를 중심으로 5% 범위
      totalScore += 10.0; // 배점 조정
    } else if (deepSleepRatio >= 5.0 && deepSleepRatio < 25.0) {
      totalScore += 5.0;
    } else {
      totalScore += 0.0;
    }

    // 최종 점수 반환
    return totalScore.clamp(0.0, 100.0);
  }

  // 코골이 지속 시간에 따른 수면 무호흡증 의심 메시지 반환
  String getSnoringWarning(double snoringTime) {
    if (snoringTime > 20.0) {
      return '수면 무호흡증이 의심됩니다. 전문가와 상담해보세요.';
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

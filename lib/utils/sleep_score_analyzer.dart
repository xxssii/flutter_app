// lib/utils/sleep_score_analyzer.dart

import 'package:flutter/material.dart';

class SleepScoreAnalyzer {
  // 1. 종합 점수 분석 (0~100점)
  int getSleepScore(
    double sleepEfficiency,
    double remRatio,
    double deepSleepRatio,
  ) {
    double totalScore = 0.0;

    // 수면 효율 (40점 만점)
    if (sleepEfficiency >= 85.0) {
      totalScore += 40.0;
    } else if (sleepEfficiency >= 70.0) {
      totalScore += 20.0;
    }

    // REM 비율 (30점 만점) - 25%가 양호
    if (remRatio >= 20.0 && remRatio <= 30.0) {
      totalScore += 30.0;
    } else if (remRatio >= 15.0 && remRatio < 35.0) {
      totalScore += 15.0;
    }

    // 깊은 수면 (N3) 비율 (30점 만점) - 15%가 양호
    if (deepSleepRatio >= 15.0 && deepSleepRatio <= 25.0) {
      totalScore += 30.0;
    } else if (deepSleepRatio >= 10.0 && deepSleepRatio < 30.0) {
      totalScore += 15.0;
    }

    return totalScore.clamp(0, 100).toInt();
  }

  // 2. ✅ [추가] 코골이 점수 환산 (10점 만점)
  double getSnoringScore(double totalSnoringMinutes, double totalSleepMinutes) {
    if (totalSleepMinutes == 0) return 10.0; // 수면 시간이 없으면 만점

    // 총 수면 시간 대비 코골이 시간의 비율
    double snoringRatio = totalSnoringMinutes / totalSleepMinutes;

    if (snoringRatio < 0.05) {
      // 5% 미만
      return 10.0; // 훌륭함
    } else if (snoringRatio < 0.15) {
      // 15% 미만
      return 7.0; // 양호
    } else if (snoringRatio < 0.3) {
      // 30% 미만
      return 4.0; // 주의
    } else {
      return 1.0; // 심각
    }
  }

  // 3. 수면 리포트 본문 생성
  String generateDailyReport(int score) {
    if (score > 85) {
      return "훌륭한 수면이었습니다. 어젯밤 꿀잠 주무셨네요!";
    } else if (score > 70) {
      return "좋은 수면이었지만, 개선의 여지가 있습니다. 리포트를 확인해보세요.";
    } else {
      return "수면의 질이 낮습니다. 수면 환경을 점검해보세요.";
    }
  }

  // 4. 수면 효율 경고 (85% 미만)
  String? getEfficiencyWarning(double sleepEfficiency) {
    if (sleepEfficiency < 85) {
      return "수면 효율이 ${sleepEfficiency.toStringAsFixed(0)}%로 기준치(85%)보다 낮습니다.";
    }
    return null;
  }

  // 5. 코골이 경고 (20분 초과)
  String? getSnoringWarning(double snoringDurationMinutes) {
    if (snoringDurationMinutes > 20) {
      return "코골이가 ${snoringDurationMinutes.toStringAsFixed(0)}분 동안 감지되었습니다. 수면 무호흡증이 의심될 수 있습니다.";
    }
    return null;
  }

  // 6. HRV에 따른 스트레스 경고 (30ms 미만)
  String? getHrvWarning(double hrv) {
    if (hrv < 30.0) {
      return 'HRV가 지속적으로 감소했습니다. 스트레스 관리가 필요합니다.';
    }
    return null;
  }
}

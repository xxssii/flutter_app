// lib/state/sleep_data_state.dart

import 'package:flutter/material.dart';

// 모든 수면 분석 지표를 담는 Mock 데이터 모델
class SleepMetrics {
  final double totalSleepDuration; // 총 수면 시간 (단위: 시간)
  final double timeInBed; // 누워 있던 시간 (단위: 시간)
  final double sleepEfficiency; // 수면 효율 (%)
  final double remRatio; // REM 수면 비율 (%)
  final double deepSleepRatio; // 깊은 수면 (N3) 비율 (%)
  final int wakeUpCount; // 기상 횟수
  final int tossingAndTurning; // 뒤척임 횟수
  final double avgSnoringDuration; // 평균 코골이 지속 시간 (분)
  final double avgHrv; // 평균 심박 변이도 (ms)
  final double avgHeartRate; // 평균 심박수 (BPM)
  final String reportDate; // 리포트 날짜

  SleepMetrics({
    required this.totalSleepDuration,
    required this.timeInBed,
    required this.sleepEfficiency,
    required this.remRatio,
    required this.deepSleepRatio,
    required this.wakeUpCount,
    required this.tossingAndTurning,
    required this.avgSnoringDuration,
    required this.avgHrv,
    required this.avgHeartRate,
    required this.reportDate,
  });
}

class SleepDataState extends ChangeNotifier {
  String _selectedPeriod = '최근30일';

  // Mock 데이터 생성
  final SleepMetrics _mockTodayMetrics = SleepMetrics(
    totalSleepDuration: 7.5,
    timeInBed: 8.0,
    sleepEfficiency: 93.75, // 7.5 / 8.0 * 100
    remRatio: 22.0,
    deepSleepRatio: 18.0,
    wakeUpCount: 1,
    tossingAndTurning: 12,
    avgSnoringDuration: 15.0,
    avgHrv: 55.0,
    avgHeartRate: 60.0,
    reportDate: '2025년 10월 27일',
  );

  // 트렌드 그래프에 사용될 데이터 (최근 10일치)
  final List<SleepMetrics> _mockTrendMetrics = [
    // 날짜, 효율, REM 비율, N3 비율만 예시
    SleepMetrics(
      totalSleepDuration: 7.0,
      timeInBed: 8.0,
      sleepEfficiency: 87.5,
      remRatio: 20.0,
      deepSleepRatio: 15.0,
      wakeUpCount: 1,
      tossingAndTurning: 10,
      avgSnoringDuration: 10,
      avgHrv: 50,
      avgHeartRate: 60,
      reportDate: '7월 13일',
    ),
    SleepMetrics(
      totalSleepDuration: 8.2,
      timeInBed: 9.0,
      sleepEfficiency: 91.1,
      remRatio: 24.0,
      deepSleepRatio: 19.0,
      wakeUpCount: 0,
      tossingAndTurning: 5,
      avgSnoringDuration: 5,
      avgHrv: 60,
      avgHeartRate: 58,
      reportDate: '7월 14일',
    ),
    SleepMetrics(
      totalSleepDuration: 6.5,
      timeInBed: 7.0,
      sleepEfficiency: 92.8,
      remRatio: 18.0,
      deepSleepRatio: 12.0,
      wakeUpCount: 2,
      tossingAndTurning: 15,
      avgSnoringDuration: 25,
      avgHrv: 40,
      avgHeartRate: 65,
      reportDate: '7월 15일',
    ),
    SleepMetrics(
      totalSleepDuration: 7.8,
      timeInBed: 8.0,
      sleepEfficiency: 97.5,
      remRatio: 25.0,
      deepSleepRatio: 21.0,
      wakeUpCount: 0,
      tossingAndTurning: 8,
      avgSnoringDuration: 2,
      avgHrv: 70,
      avgHeartRate: 55,
      reportDate: '7월 16일',
    ),
    SleepMetrics(
      totalSleepDuration: 9.0,
      timeInBed: 9.5,
      sleepEfficiency: 94.7,
      remRatio: 22.0,
      deepSleepRatio: 16.0,
      wakeUpCount: 0,
      tossingAndTurning: 3,
      avgSnoringDuration: 1,
      avgHrv: 80,
      avgHeartRate: 52,
      reportDate: '7월 17일',
    ),
  ];

  // Getter 추가
  String get selectedPeriod => _selectedPeriod;
  SleepMetrics get todayMetrics => _mockTodayMetrics;
  List<SleepMetrics> get trendMetrics => _mockTrendMetrics; // 트렌드 데이터 Getter

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }
}

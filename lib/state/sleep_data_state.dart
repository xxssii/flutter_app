// lib/state/sleep_data_state.dart

import 'package:flutter/material.dart';
import 'dart:math'; // Random을 위해 추가

// 시간별 데시벨 데이터를 위한 모델 (이전에 추가됨)
class SnoringDataPoint {
  final DateTime time;
  final double decibel;

  SnoringDataPoint(this.time, this.decibel);
}

class SleepMetrics {
  final String reportDate;
  final double totalSleepDuration; // 총 수면 시간 (예: 7.5시간)
  final double timeInBed; // 침대에 있었던 총 시간 (예: 8.0시간)
  final double sleepEfficiency; // 수면 효율 (%)
  final double remRatio; // REM 수면 비율 (%)
  final double deepSleepRatio; // 깊은 수면 비율 (%)
  final int tossingAndTurning; // 뒤척임 횟수
  final double avgSnoringDuration; // 코골이 감지 총 시간 (분)
  final double avgHrv; // 평균 HRV (Heart Rate Variability)
  final double avgHeartRate; // 평균 심박수
  final int apneaCount; // 수면 무호흡 횟수

  // ✅ 심박수 데이터 추가 (시간별) - 그래프용
  final List<double> heartRateData; // 22시부터 6시까지 10분 간격 심박수 (49개 데이터)

  // ✅ 코골이 데시벨 데이터 추가 (시간별) - 그래프용
  final List<SnoringDataPoint> snoringDecibelData; // 시간별 데시벨 값

  SleepMetrics({
    required this.reportDate,
    required this.totalSleepDuration,
    required this.timeInBed,
    required this.sleepEfficiency,
    required this.remRatio,
    required this.deepSleepRatio,
    required this.tossingAndTurning,
    required this.avgSnoringDuration,
    required this.avgHrv,
    required this.avgHeartRate,
    required this.apneaCount,
    required this.heartRateData, // ✅ 그래프용 데이터 생성자에 추가
    required this.snoringDecibelData, // ✅ 그래프용 데이터 생성자에 추가
  });
}

// ✅ 효율성 탭(막대그래프)을 위한 TIB/TST 데이터 구조 (기존 그대로)
class TstTibData {
  final String dayLabel;
  final double tib; // 누운 시간
  final double tst; // 실 수면 시간

  TstTibData({required this.dayLabel, required this.tib, required this.tst});
}

class SleepDataState extends ChangeNotifier {
  String _selectedPeriod = '최근7일';
  String get selectedPeriod => _selectedPeriod;

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  // ✅ Mock 데이터 생성을 위한 Random 인스턴스 (그래프 데이터 생성 시 사용)
  Random random = Random();

  // 2. SleepReportScreen이 사용할 Mock 데이터 (오늘의 데이터)
  //    심박수 및 코골이 그래프 데이터를 포함하도록 업데이트
  late final SleepMetrics _mockTodayMetrics; // late로 선언 후 생성자에서 초기화

  SleepDataState() {
    _mockTodayMetrics = _generateTodayMockMetrics(); // 생성자에서 초기화 함수 호출
  }

  // ✅ 오늘의 Mock 데이터 생성 함수 (이전에 generateMockSleepData에서 가져옴)
  SleepMetrics _generateTodayMockMetrics() {
    // 22시부터 6시까지 10분 간격 심박수 Mock 데이터 (49개 데이터)
    final List<double> mockHeartRate = List.generate(49, (index) {
      // 22:00 ~ 06:00
      double baseHeartRate = 60 + random.nextDouble() * 10; // 60~70 기본
      if (index > 10 && index < 30) {
        // 0시 ~ 3시 (깊은 수면 시) 심박수 약간 낮게
        baseHeartRate -= 5;
      }
      if (index % 15 == 0) {
        // 가끔 튀는 심박수 (뒤척임/REM)
        baseHeartRate += random.nextDouble() * 15;
      }
      return baseHeartRate.clamp(40.0, 80.0); // 40~80 사이로 제한
    });

    // ✅ Mock 코골이 데시벨 데이터 생성 (49개 데이터)
    final List<SnoringDataPoint> mockSnoringDecibelData = [];
    DateTime currentTime = DateTime(2025, 10, 29, 22, 0); // reportDate와 동일하게
    for (int i = 0; i < 49; i++) {
      // 10분 간격 49개 데이터
      double decibel;
      if (random.nextDouble() < 0.25) {
        // 25% 확률로 코골이 (50dB 이상)
        decibel = 50 + random.nextDouble() * 30; // 50~80dB
      } else {
        // 코골이 아님 (50dB 미만)
        decibel = 30 + random.nextDouble() * 20; // 30~50dB
      }
      mockSnoringDecibelData.add(
        SnoringDataPoint(currentTime, decibel.clamp(30.0, 90.0)),
      );
      currentTime = currentTime.add(const Duration(minutes: 10));
    }

    return SleepMetrics(
      reportDate: '2025년 10월 29일',
      totalSleepDuration: 7.5,
      timeInBed: 8.0,
      sleepEfficiency: 93.75,
      remRatio: 22.0,
      deepSleepRatio: 18.0,
      tossingAndTurning: 12,
      avgSnoringDuration: 15.0, // 코골이 감지 총 시간 (분) - (이 값은 하드웨어에서 오는 실제 데이터로 변경)
      avgHrv: 55.0,
      avgHeartRate: 60.0,
      apneaCount: 0,
      heartRateData: mockHeartRate, // ✅ 그래프용 데이터 포함
      snoringDecibelData: mockSnoringDecibelData, // ✅ 그래프용 데이터 포함
    );
  }

  SleepMetrics get todayMetrics => _mockTodayMetrics;

  // 3. ✅ TrendsTab (꺾은선그래프) Mock 데이터 (7일치)
  final List<SleepMetrics> _mockTrendMetrics = [
    SleepMetrics(
      reportDate: '7월 13일',
      totalSleepDuration: 7.0,
      timeInBed: 8.0,
      sleepEfficiency: 87.5,
      remRatio: 20.0,
      deepSleepRatio: 15.0,
      tossingAndTurning: 10,
      avgSnoringDuration: 10,
      avgHrv: 50,
      avgHeartRate: 60,
      apneaCount: 2,
      heartRateData: List.empty(), // 트렌드용에는 그래프 데이터 비워둠
      snoringDecibelData: List.empty(), // 트렌드용에는 그래프 데이터 비워둠
    ),
    SleepMetrics(
      reportDate: '7월 14일',
      totalSleepDuration: 8.2,
      timeInBed: 9.0,
      sleepEfficiency: 91.1,
      remRatio: 24.0,
      deepSleepRatio: 19.0,
      tossingAndTurning: 5,
      avgSnoringDuration: 5,
      avgHrv: 60,
      avgHeartRate: 58,
      apneaCount: 0,
      heartRateData: List.empty(),
      snoringDecibelData: List.empty(),
    ),
    SleepMetrics(
      reportDate: '7월 15일',
      totalSleepDuration: 6.5,
      timeInBed: 7.0,
      sleepEfficiency: 92.8,
      remRatio: 18.0,
      deepSleepRatio: 12.0,
      tossingAndTurning: 15,
      avgSnoringDuration: 25,
      avgHrv: 40,
      avgHeartRate: 65,
      apneaCount: 5,
      heartRateData: List.empty(),
      snoringDecibelData: List.empty(),
    ),
    SleepMetrics(
      reportDate: '7월 16일',
      totalSleepDuration: 7.8,
      timeInBed: 8.0,
      sleepEfficiency: 97.5,
      remRatio: 25.0,
      deepSleepRatio: 21.0,
      tossingAndTurning: 8,
      avgSnoringDuration: 2,
      avgHrv: 70,
      avgHeartRate: 55,
      apneaCount: 0,
      heartRateData: List.empty(),
      snoringDecibelData: List.empty(),
    ),
    SleepMetrics(
      reportDate: '7월 17일',
      totalSleepDuration: 9.0,
      timeInBed: 9.5,
      sleepEfficiency: 94.7,
      remRatio: 22.0,
      deepSleepRatio: 16.0,
      tossingAndTurning: 3,
      avgSnoringDuration: 1,
      avgHrv: 80,
      avgHeartRate: 52,
      apneaCount: 0,
      heartRateData: List.empty(),
      snoringDecibelData: List.empty(),
    ),
    SleepMetrics(
      reportDate: '7월 18일',
      totalSleepDuration: 7.2,
      timeInBed: 8.0,
      sleepEfficiency: 90.0,
      remRatio: 21.0,
      deepSleepRatio: 17.0,
      tossingAndTurning: 11,
      avgSnoringDuration: 8,
      avgHrv: 58,
      avgHeartRate: 59,
      apneaCount: 1,
      heartRateData: List.empty(),
      snoringDecibelData: List.empty(),
    ),
    SleepMetrics(
      reportDate: '7월 19일',
      totalSleepDuration: 7.5,
      timeInBed: 8.5,
      sleepEfficiency: 88.2,
      remRatio: 23.0,
      deepSleepRatio: 16.0,
      tossingAndTurning: 9,
      avgSnoringDuration: 12,
      avgHrv: 62,
      avgHeartRate: 61,
      apneaCount: 0,
      heartRateData: List.empty(),
      snoringDecibelData: List.empty(),
    ),
  ];

  // 4. ✅ EfficiencyTab (막대그래프) Mock 데이터 (7일치) (기존 그대로)
  final List<TstTibData> _mockTIB_TST_Data = [
    TstTibData(dayLabel: '7/13', tib: 8.0, tst: 7.0),
    TstTibData(dayLabel: '7/14', tib: 9.0, tst: 8.2),
    TstTibData(dayLabel: '7/15', tib: 7.0, tst: 6.5),
    TstTibData(dayLabel: '7/16', tib: 8.0, tst: 7.8),
    TstTibData(dayLabel: '7/17', tib: 9.5, tst: 9.0),
    TstTibData(dayLabel: '7/18', tib: 8.0, tst: 7.2),
    TstTibData(dayLabel: '7/19', tib: 8.5, tst: 7.5),
  ];

  List<SleepMetrics> get trendMetrics => _mockTrendMetrics;

  // 5. ✅ 누락되었던 Getter 추가 (기존 그대로)
  List<TstTibData> get tibTstData => _mockTIB_TST_Data;
}

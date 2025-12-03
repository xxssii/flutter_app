// lib/state/sleep_data_state.dart
// ✅ 수정된 버전: 크래시 방지 + 에러 처리 강화

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

// ========================================================================
// ✅ 데이터 모델 정의
// ========================================================================

class SnoringDataPoint {
  final DateTime time;
  final double decibel;

  SnoringDataPoint(this.time, this.decibel);

  Map<String, dynamic> toMap() {
    return {'time': time.toIso8601String(), 'decibel': decibel};
  }
}

class SleepMetrics {
  final String reportDate;
  final double totalSleepDuration;
  final double timeInBed;
  final double sleepEfficiency;
  final double remRatio;
  final double deepSleepRatio;
  final int tossingAndTurning;
  final double avgSnoringDuration;
  final double avgHrv;
  final double avgHeartRate;
  final int apneaCount;
  final List<double> heartRateData;
  final List<SnoringDataPoint> snoringDecibelData;

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
    required this.heartRateData,
    required this.snoringDecibelData,
  });
}

class TstTibData {
  final String dayLabel;
  final double tib;
  final double tst;

  TstTibData({required this.dayLabel, required this.tib, required this.tst});
}

// ========================================================================
// ✅ SleepDataState (상태 관리 클래스)
// ========================================================================

class SleepDataState extends ChangeNotifier {
  // --- 상태 변수 ---
  String _selectedPeriod = '최근7일';
  String get selectedPeriod => _selectedPeriod;

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  Random random = Random();
  
  // 오늘의 데이터
  late SleepMetrics _todayMetrics;
  
  // 수면 기록 리스트 (최신순 정렬)
  List<SleepMetrics> sleepHistory = [];

  // 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SleepDataState() {
    // 앱 시작 시 Mock 데이터로 초기화
    _todayMetrics = _generateTodayMockMetrics();
  }

  SleepMetrics get todayMetrics => _todayMetrics;

  // Mock 데이터 생성기 (초기값용)
  SleepMetrics _generateTodayMockMetrics() {
    final List<double> mockHeartRate = List.generate(49, (index) => 60.0);
    return SleepMetrics(
      reportDate: '데이터 없음',
      totalSleepDuration: 0.0,
      timeInBed: 0.0,
      sleepEfficiency: 0.0,
      remRatio: 0.0,
      deepSleepRatio: 0.0,
      tossingAndTurning: 0,
      avgSnoringDuration: 0.0,
      avgHrv: 0.0,
      avgHeartRate: 0.0,
      apneaCount: 0,
      heartRateData: mockHeartRate,
      snoringDecibelData: [],
    );
  }

  // ========================================================================
  // ✅ [핵심 복구] 이 함수들이 있어야 빌드가 됩니다!
  // ========================================================================

  // 1. ✅ 오늘의 데이터 수동 설정 (SleepHistoryScreen 등에서 호출)
  void setTodayMetrics(SleepMetrics metrics) {
    _todayMetrics = metrics;
    notifyListeners();
  }

  // 2. ✅ 수면 데이터 저장 (SleepReportScreen에서 호출)
  Future<void> saveSleepData(
    BuildContext context,
    String userId,
    SleepMetrics metrics,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Firestore에 데이터 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sleep_reports')
          .doc(metrics.reportDate)
          .set({
            'reportDate': metrics.reportDate,
            'totalSleepDuration': metrics.totalSleepDuration,
            'timeInBed': metrics.timeInBed,
            'sleepEfficiency': metrics.sleepEfficiency,
            'remRatio': metrics.remRatio,
            'deepSleepRatio': metrics.deepSleepRatio,
            'tossingAndTurning': metrics.tossingAndTurning,
            'avgSnoringDuration': metrics.avgSnoringDuration,
            'avgHrv': metrics.avgHrv,
            'avgHeartRate': metrics.avgHeartRate,
            'apneaCount': metrics.apneaCount,
            'heartRateData': metrics.heartRateData,
            'snoringDecibelData': metrics.snoringDecibelData
                .map((e) => e.toMap())
                .toList(),
            'created_at': FieldValue.serverTimestamp(),
          });

      print('✅ 수면 데이터 저장 성공: ${metrics.reportDate}');
      _showSnackBar(context, '수면 데이터가 성공적으로 저장되었습니다.', isError: false);
      
      // 저장 후 리스트 갱신
      await fetchAllSleepReports(userId);

    } catch (e) {
      print('❌ 저장 실패: $e');
      _showErrorDialog(context, '저장 실패', '데이터 저장 중 오류가 발생했습니다.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================================================
  // ✅ Firestore 연동 기능 (불러오기) - BuildContext 제거!
  // ========================================================================

  Future<void> fetchAllSleepReports(String userId, {BuildContext? context}) async {
    try {
      print('📥 [1/5] 데이터 가져오기 시작...');
      _isLoading = true;
      notifyListeners();

      print('📥 [2/5] Firebase 쿼리 실행 중...');
      // Home화면의 생성기가 만든 'sleep_reports' (루트) 조회
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sleep_reports') 
          .where('userId', isEqualTo: userId) 
          .orderBy('created_at', descending: true)
          .limit(10) // ✅ 최대 10개만 가져오기
          .get();

      print('📥 [3/5] Firebase에서 ${snapshot.docs.length}개 문서 받음');

      sleepHistory = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          final summary = data['summary'] ?? {};
          
          // ✅ 안전한 데이터 추출
          final totalDurationHours = (summary['total_duration_hours'] as num?)?.toDouble() ?? 0.0;
          final deepRatio = (summary['deep_ratio'] as num?)?.toDouble() ?? 0.0;
          final remRatio = (summary['rem_ratio'] as num?)?.toDouble() ?? 0.0;
          final totalScore = (data['total_score'] as num?)?.toDouble() ?? 0.0;
          final snoringDuration = (summary['snoring_duration'] as num?)?.toDouble() ?? 0.0;
          final apneaCount = (summary['apnea_count'] as num?)?.toInt() ?? 0;
          
          sleepHistory.add(
            SleepMetrics(
              reportDate: data['sessionId'] ?? 'unknown',
              totalSleepDuration: totalDurationHours,
              timeInBed: totalDurationHours * 1.1, // ✅ 누운 시간은 수면 시간보다 약간 길게
              sleepEfficiency: totalScore, 
              remRatio: remRatio,
              deepSleepRatio: deepRatio,
              tossingAndTurning: 0, 
              avgSnoringDuration: snoringDuration,
              avgHrv: 0.0,
              avgHeartRate: 0.0,
              apneaCount: apneaCount,
              heartRateData: [], 
              snoringDecibelData: [],
            ),
          );
          
          print('✅ 데이터 파싱 성공: ${data['sessionId']}');
        } catch (e) {
          print('⚠️ 문서 파싱 에러 (건너뛰기): $e');
          continue; // 에러 나도 계속 진행
        }
      }

      print('📥 [4/5] 총 ${sleepHistory.length}개 데이터 파싱 완료');

      // 최신 데이터를 "오늘의 데이터"로 설정
      if (sleepHistory.isNotEmpty) {
        _todayMetrics = sleepHistory.first; 
        print("✅ [5/5] 최신 데이터 업데이트 완료!");
        print("📊 첫 번째 데이터: ${_todayMetrics.totalSleepDuration}시간");
      } else {
        print("⚠️ [5/5] 데이터가 없습니다. 기본값 유지");
        _todayMetrics = _generateTodayMockMetrics();
      }

    } catch (e, stackTrace) {
      print('❌ 데이터 불러오기 실패!');
      print('❌ 에러: $e');
      print('❌ 스택 트레이스: $stackTrace');
      
      // ✅ 에러가 나도 앱은 계속 실행되도록!
      sleepHistory = [];
      _todayMetrics = _generateTodayMockMetrics();
      
    } finally {
      _isLoading = false;
      notifyListeners();
      print('✅ fetchAllSleepReports 완료!\n');
    }
  }

  // UI 연동용 Getter들
  String get averageSleepDurationStr {
    if (sleepHistory.isEmpty) return "-";
    final recent = sleepHistory.take(7);
    double total = recent.fold(0.0, (sum, item) => sum + item.totalSleepDuration);
    double avg = total / recent.length;
    int hours = avg.floor();
    int minutes = ((avg - hours) * 60).round();
    return "${hours}시간 ${minutes}분";
  }

  String get averageSnoringStr {
    if (sleepHistory.isEmpty) return "-";
    final recent = sleepHistory.take(7);
    double total = recent.fold(0.0, (sum, item) => sum + item.avgSnoringDuration);
    double avg = total / recent.length;
    return "${avg.toStringAsFixed(0)}분";
  }

  String get averageEfficiencyStr {
    if (sleepHistory.isEmpty) return "-";
    final recent = sleepHistory.take(7);
    double total = recent.fold(0.0, (sum, item) => sum + item.sleepEfficiency); 
    double avg = total / recent.length;
    return "${avg.toStringAsFixed(0)}%";
  }

  String get averageRemRatioStr {
    if (sleepHistory.isEmpty) return "-";
    final recent = sleepHistory.take(7);
    double total = recent.fold(0.0, (sum, item) => sum + item.remRatio);
    double avg = total / recent.length;
    return "${avg.toStringAsFixed(0)}%";
  }

  // Helper Methods
  void _showErrorDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: AppColors.errorRed)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.primaryNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
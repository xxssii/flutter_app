// lib/state/sleep_data_state.dart

import 'package:flutter/material.dart';
import 'dart:math'; // Random을 위해 추가
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore 임포트
import '../utils/app_colors.dart'; // ✅ 에러 메시지 색상 사용을 위해 임포트

// ========================================================================
// ✅ 데이터 모델 정의 (SnoringDataPoint, SleepMetrics, TstTibData)
// ========================================================================

// 시간별 데시벨 데이터를 위한 모델
class SnoringDataPoint {
  final DateTime time;
  final double decibel;

  SnoringDataPoint(this.time, this.decibel);

  // Firestore 저장을 위한 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {'time': time.toIso8601String(), 'decibel': decibel};
  }
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
  final double avgHrv; // 평균 HRV
  final double avgHeartRate; // 평균 심박수
  final int apneaCount; // 수면 무호흡 횟수

  // 심박수 데이터 (시간별) - 그래프용
  final List<double> heartRateData;

  // 코골이 데시벨 데이터 (시간별) - 그래프용
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

// 효율성 탭(막대그래프)을 위한 TIB/TST 데이터 구조
class TstTibData {
  final String dayLabel;
  final double tib; // 누운 시간
  final double tst; // 실 수면 시간

  TstTibData({required this.dayLabel, required this.tib, required this.tst});
}

// ========================================================================
// ✅ SleepDataState (상태 관리 클래스)
// ========================================================================

class SleepDataState extends ChangeNotifier {
  // --- 기존 Mock 데이터 관련 코드 시작 ---
  String _selectedPeriod = '최근7일';
  String get selectedPeriod => _selectedPeriod;

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  // Mock 데이터 생성을 위한 Random 인스턴스
  Random random = Random();

  // 오늘의 Mock 데이터
  late SleepMetrics _mockTodayMetrics;

  SleepDataState() {
    _mockTodayMetrics = _generateTodayMockMetrics();
  }

  // 오늘의 Mock 데이터 생성 함수
  SleepMetrics _generateTodayMockMetrics() {
    // 22시부터 6시까지 10분 간격 심박수 Mock 데이터 (49개 데이터)
    final List<double> mockHeartRate = List.generate(49, (index) {
      double baseHeartRate = 60 + random.nextDouble() * 10;
      if (index > 10 && index < 30) {
        baseHeartRate -= 5;
      }
      if (index % 15 == 0) {
        baseHeartRate += random.nextDouble() * 15;
      }
      return baseHeartRate.clamp(40.0, 80.0);
    });

    // Mock 코골이 데시벨 데이터 생성 (49개 데이터)
    final List<SnoringDataPoint> mockSnoringDecibelData = [];
    DateTime currentTime = DateTime(2025, 10, 29, 22, 0);
    for (int i = 0; i < 49; i++) {
      double decibel;
      if (random.nextDouble() < 0.25) {
        decibel = 50 + random.nextDouble() * 30;
      } else {
        decibel = 30 + random.nextDouble() * 20;
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
      avgSnoringDuration: 15.0,
      avgHrv: 55.0,
      avgHeartRate: 60.0,
      apneaCount: 0,
      heartRateData: mockHeartRate,
      snoringDecibelData: mockSnoringDecibelData,
    );
  }

  // ✅ 새로 추가된 함수: 선택된 데이터를 오늘의 데이터로 설정
  void setTodayMetrics(SleepMetrics metrics) {
    _mockTodayMetrics = metrics;
    notifyListeners(); // 리스너들에게 변경 알림
  }

  SleepMetrics get todayMetrics => _mockTodayMetrics;

  // TrendsTab (꺾은선그래프) Mock 데이터 (7일치)
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
      heartRateData: List.empty(),
      snoringDecibelData: List.empty(),
    ),
    // ... (중간 데이터 생략 - 실제 사용 시 모든 데이터 포함 필요) ...
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

  // EfficiencyTab (막대그래프) Mock 데이터 (7일치)
  final List<TstTibData> _mockTIB_TST_Data = [
    TstTibData(dayLabel: '7/13', tib: 8.0, tst: 7.0),
    // ... (중간 데이터 생략 - 실제 사용 시 모든 데이터 포함 필요) ...
    TstTibData(dayLabel: '7/19', tib: 8.5, tst: 7.5),
  ];

  List<SleepMetrics> get trendMetrics => _mockTrendMetrics;
  List<TstTibData> get tibTstData => _mockTIB_TST_Data;
  // --- 기존 Mock 데이터 관련 코드 끝 ---

  // ========================================================================
  // ✅ Firestore 연동 기능 (저장, 불러오기, 리스트 불러오기)
  // ========================================================================

  // 로딩 상태 관리를 위한 변수
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 1. Firestore에 수면 데이터 저장하기
  Future<void> saveSleepData(
    BuildContext context,
    String userId,
    SleepMetrics metrics,
  ) async {
    try {
      _isLoading = true;
      notifyListeners(); // 로딩 시작 알림

      // Firestore에 데이터 저장 시도
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sleep_reports')
          .doc(metrics.reportDate) // 날짜를 문서 ID로 사용
          .set({
            // SleepMetrics 객체를 Map으로 변환하여 저장
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
            // 그래프 데이터 저장 (리스트 형태)
            'heartRateData': metrics.heartRateData,
            'snoringDecibelData': metrics.snoringDecibelData
                .map((e) => e.toMap())
                .toList(),
          });

      print('✅ 수면 데이터 저장 성공: ${metrics.reportDate}');
      _showSnackBar(context, '수면 데이터가 성공적으로 저장되었습니다.', isError: false);
    } on FirebaseException catch (e) {
      print('❌ Firebase 오류 발생 (저장): ${e.message}');
      _showErrorDialog(
        context,
        '데이터 저장 실패',
        '서버와 연결하는 도중 문제가 발생했습니다.\n다시 시도해 주세요.\n(에러 코드: ${e.code})',
      );
    } catch (e) {
      print('❌ 알 수 없는 오류 발생 (저장): $e');
      _showErrorDialog(
        context,
        '오류 발생',
        '알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해 주세요.',
      );
    } finally {
      _isLoading = false;
      notifyListeners(); // 로딩 종료 알림
    }
  }

  // 2. Firestore에서 특정 날짜의 수면 데이터 불러오기
  Future<void> fetchSleepData(
    BuildContext context,
    String userId,
    String date,
  ) async {
    try {
      _isLoading = true;
      notifyListeners(); // 로딩 시작 알림

      // Firestore에서 데이터 가져오기 시도
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sleep_reports')
          .doc(date)
          .get();

      if (snapshot.exists) {
        // 데이터가 존재하면 Map을 SleepMetrics 객체로 변환
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // (여기서 데이터를 변환하여 UI에 반영하는 로직이 필요합니다. 현재는 로그만 출력)
        print('✅ 수면 데이터 불러오기 성공: $date');
        print('총 수면 시간: ${data['totalSleepDuration']}시간');
      } else {
        print('ℹ️ 해당 날짜의 수면 데이터가 없습니다: $date');
        _showSnackBar(context, '해당 날짜의 수면 데이터가 없습니다.', isError: false);
      }
    } on FirebaseException catch (e) {
      print('❌ Firebase 오류 발생 (불러오기): ${e.message}');
      _showErrorDialog(
        context,
        '데이터 불러오기 실패',
        '서버에서 데이터를 가져오는 도중 문제가 발생했습니다.\n(에러 코드: ${e.code})',
      );
    } catch (e) {
      print('❌ 알 수 없는 오류 발생 (불러오기): $e');
      _showErrorDialog(context, '오류 발생', '데이터를 처리하는 도중 알 수 없는 오류가 발생했습니다.');
    } finally {
      _isLoading = false;
      notifyListeners(); // 로딩 종료 알림
    }
  }

  // ========================================================================
  // ✅ 수면 기록 리스트 불러오기 (새로 추가된 부분)
  // ========================================================================

  // ✅ 불러온 수면 기록 리스트를 저장할 변수 (외부 접근 가능)
  List<SleepMetrics> sleepHistory = [];

  // 3. Firestore에서 특정 사용자의 모든 수면 리포트 가져오기
  Future<void> fetchAllSleepReports(BuildContext context, String userId) async {
    try {
      _isLoading = true;
      notifyListeners(); // 로딩 시작

      // 1. Firestore에서 해당 사용자의 'sleep_reports' 컬렉션의 모든 문서 가져오기
      //    reportDate를 기준으로 내림차순 정렬 (최신순)
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sleep_reports')
          .orderBy('reportDate', descending: true)
          .get();

      sleepHistory = []; // 리스트 초기화

      // 2. 가져온 문서들을 반복하며 SleepMetrics 객체로 변환하여 리스트에 추가
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 심박수 데이터 변환
        List<double> heartRateData =
            (data['heartRateData'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [];

        // 코골이 데이터 변환
        List<SnoringDataPoint> snoringDecibelData =
            (data['snoringDecibelData'] as List<dynamic>?)
                ?.map(
                  (e) => SnoringDataPoint(
                    DateTime.parse(e['time']),
                    (e['decibel'] as num).toDouble(),
                  ),
                )
                .toList() ??
            [];

        // SleepMetrics 객체 생성 및 리스트에 추가
        sleepHistory.add(
          SleepMetrics(
            reportDate: data['reportDate'],
            totalSleepDuration: (data['totalSleepDuration'] as num).toDouble(),
            timeInBed: (data['timeInBed'] as num).toDouble(),
            sleepEfficiency: (data['sleepEfficiency'] as num).toDouble(),
            remRatio: (data['remRatio'] as num).toDouble(),
            deepSleepRatio: (data['deepSleepRatio'] as num).toDouble(),
            tossingAndTurning: data['tossingAndTurning'] as int,
            avgSnoringDuration: (data['avgSnoringDuration'] as num).toDouble(),
            avgHrv: (data['avgHrv'] as num).toDouble(),
            avgHeartRate: (data['avgHeartRate'] as num).toDouble(),
            apneaCount: data['apneaCount'] as int,
            heartRateData: heartRateData,
            snoringDecibelData: snoringDecibelData,
          ),
        );
      }

      print('✅ 수면 기록 리스트 불러오기 성공 (${sleepHistory.length}개)');
    } on FirebaseException catch (e) {
      print('❌ Firebase 오류 발생 (리스트 불러오기): ${e.message}');
      _showErrorDialog(
        context,
        '기록 불러오기 실패',
        '서버에서 목록을 가져오는 도중 문제가 발생했습니다.\n(에러 코드: ${e.code})',
      );
    } catch (e) {
      print('❌ 알 수 없는 오류 발생 (리스트 불러오기): $e');
      _showErrorDialog(context, '오류 발생', '알 수 없는 오류가 발생했습니다.');
    } finally {
      _isLoading = false;
      notifyListeners(); // 로딩 종료 및 UI 업데이트
    }
  }

  // ========================================================================
  // ✅ 공통 UI 함수 (다이얼로그, 스낵바)
  // ========================================================================

  // 사용자에게 에러 메시지를 보여주는 다이얼로그 함수
  void _showErrorDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: AppColors.errorRed)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '확인',
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 간단한 메시지를 보여주는 스낵바 함수
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.primaryNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

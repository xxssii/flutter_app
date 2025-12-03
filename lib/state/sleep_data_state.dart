import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

// ✅ 소음 데이터 모델
class SnoringDataPoint {
  final DateTime time;
  final double decibel;
  SnoringDataPoint(this.time, this.decibel);
  Map<String, dynamic> toMap() {
    return {'time': time.toIso8601String(), 'decibel': decibel};
  }
}

// ✅ 수면 지표 모델
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

class SleepDataState extends ChangeNotifier {
  String _selectedPeriod = '최근7일';
  String get selectedPeriod => _selectedPeriod;
  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  Random random = Random();
  late SleepMetrics _todayMetrics;
  List<SleepMetrics> sleepHistory = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SleepDataState() {
    _todayMetrics = _generateTodayMockMetrics();
  }

  SleepMetrics get todayMetrics => _todayMetrics;

  // ✅ [복구됨] 화면에서 선택한 날짜의 데이터를 메인에 표시하기 위한 함수
  void setTodayMetrics(SleepMetrics metrics) {
    _todayMetrics = metrics;
    notifyListeners();
  }

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

  // ✅ [복구됨] 수면 데이터 저장 함수
  Future<void> saveSleepData(BuildContext context, String userId, SleepMetrics metrics) async {
    try {
      _isLoading = true;
      notifyListeners();
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
            'snoringDecibelData': metrics.snoringDecibelData.map((e) => e.toMap()).toList(),
            'created_at': FieldValue.serverTimestamp(),
          });
      print('✅ 수면 데이터 저장 성공: ${metrics.reportDate}');
      _showSnackBar(context, '수면 데이터가 성공적으로 저장되었습니다.', isError: false);
      await fetchAllSleepReports(userId);
    } catch (e) {
      print('❌ 저장 실패: $e');
      _showErrorDialog(context, '저장 실패', '데이터 저장 중 오류가 발생했습니다.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ 데이터 불러오기 함수
  Future<void> fetchAllSleepReports(String userId, {BuildContext? context}) async {
    try {
      print('📥 [1/5] 데이터 가져오기 시작...');
      _isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sleep_reports') 
          .where('userId', isEqualTo: userId) 
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      print('📥 [3/5] Firebase에서 ${snapshot.docs.length}개 문서 받음');
      sleepHistory = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          final summary = data['summary'] ?? {};
          
          final totalDurationHours = (summary['total_duration_hours'] as num?)?.toDouble() ?? 0.0;
          final deepSleepHours = (summary['deep_sleep_hours'] as num?)?.toDouble() ?? 0.0;
          final remSleepHours = (summary['rem_sleep_hours'] as num?)?.toDouble() ?? 0.0;
          final lightSleepHours = (summary['light_sleep_hours'] as num?)?.toDouble() ?? 0.0;
          
          final deepRatio = (summary['deep_ratio'] as num?)?.toDouble() ?? 0.0;
          final remRatio = (summary['rem_ratio'] as num?)?.toDouble() ?? 0.0;
          final snoringDuration = (summary['snoring_duration'] as num?)?.toDouble() ?? 0.0;
          final apneaCount = (summary['apnea_count'] as num?)?.toInt() ?? 0;

          // 깬 시간 보정 로직
          double awakeHours = (summary['awake_hours'] as num?)?.toDouble() ?? 0.0;
          final actualSleepTime = deepSleepHours + remSleepHours + lightSleepHours;

          if (awakeHours == 0 && totalDurationHours > actualSleepTime) {
             awakeHours = totalDurationHours - actualSleepTime;
          }
          
          double timeInBed = totalDurationHours;
          if ((actualSleepTime + awakeHours) > timeInBed) {
            timeInBed = actualSleepTime + awakeHours;
          }
          
          double sleepEfficiency = 0.0;
          if (timeInBed > 0) {
            sleepEfficiency = (actualSleepTime / timeInBed) * 100;
            if (sleepEfficiency > 100.0) sleepEfficiency = 100.0;
          }
          
          // ========================================
          // ✅ 심박수 데이터 가져오기
          // ========================================
          List<double> heartRateList = [];
          if (data.containsKey('heartRateData')) {
            try {
              final rawData = data['heartRateData'];
              if (rawData is List) {
                heartRateList = rawData
                    .map((e) => (e as num).toDouble())
                    .toList();
              }
              print('✅ 심박수 데이터 ${heartRateList.length}개 로드됨');
            } catch (e) {
              print('⚠️ 심박수 데이터 파싱 실패: $e');
            }
          }
          
          // ✅ 데이터가 없으면 테스트 데이터 생성
          if (heartRateList.isEmpty) {
            print('⚠️ 심박수 데이터 없음 - 테스트 데이터 생성');
            heartRateList = List.generate(49, (index) {
              return 60.0 + random.nextDouble() * 20.0;
            });
          }
          
          // ========================================
          // ✅ 코골이 데이터 가져오기
          // ========================================
          List<SnoringDataPoint> snoringList = [];
          if (data.containsKey('snoringDecibelData')) {
            try {
              final rawData = data['snoringDecibelData'];
              if (rawData is List) {
                snoringList = rawData.map((item) {
                  if (item is Map<String, dynamic>) {
                    DateTime time = DateTime.parse(
                      item['time'] ?? DateTime.now().toIso8601String()
                    );
                    double decibel = (item['decibel'] as num?)?.toDouble() ?? 0.0;
                    return SnoringDataPoint(time, decibel);
                  }
                  return SnoringDataPoint(DateTime.now(), 0.0);
                }).toList();
              }
              print('✅ 코골이 데이터 ${snoringList.length}개 로드됨');
            } catch (e) {
              print('⚠️ 코골이 데이터 파싱 실패: $e');
            }
          }
          
          // ✅ 데이터가 없으면 테스트 데이터 생성
          if (snoringList.isEmpty) {
            print('⚠️ 코골이 데이터 없음 - 테스트 데이터 생성');
            snoringList = List.generate(49, (index) {
              DateTime time = DateTime.now().add(Duration(seconds: index * 5));
              double decibel = 30.0 + random.nextDouble() * 50.0;
              return SnoringDataPoint(time, decibel);
            });
          }
          
          sleepHistory.add(
            SleepMetrics(
              reportDate: data['sessionId'] ?? 'unknown',
              totalSleepDuration: actualSleepTime,
              timeInBed: timeInBed,
              sleepEfficiency: sleepEfficiency,
              remRatio: remRatio,
              deepSleepRatio: deepRatio,
              tossingAndTurning: awakeHours > 0 ? 1 : 0,
              avgSnoringDuration: snoringDuration,
              avgHrv: 0.0,
              avgHeartRate: 0.0,
              apneaCount: apneaCount,
              heartRateData: heartRateList,  // ✅ 여기!
              snoringDecibelData: snoringList,  // ✅ 여기!
            ),
          );
        } catch (e) {
          print('⚠️ 문서 파싱 에러 (건너뛰기): $e');
          continue;
        }
      }

      if (sleepHistory.isNotEmpty) {
        _todayMetrics = sleepHistory.first; 
      } else {
        _todayMetrics = _generateTodayMockMetrics();
      }
    } catch (e, stackTrace) {
      print('❌ 데이터 불러오기 실패!');
      print('❌ 에러: $e');
      sleepHistory = [];
      _todayMetrics = _generateTodayMockMetrics();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ [복구됨] UI 헬퍼 함수들
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
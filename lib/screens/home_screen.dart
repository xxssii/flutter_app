// lib/screens/home_screen.dart
// ✅ 수정된 버전: 앱 시작 시 자동으로 Firebase 데이터 가져오기

import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/app_state.dart';
import '../state/settings_state.dart';
import '../state/sleep_data_state.dart';
import '../utils/sleep_score_analyzer.dart';
import 'sleep_mode_screen.dart';
import '../services/ble_service.dart';
import 'hardware_test_screen.dart';

// ✅ StatefulWidget으로 변경!
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _random = Random();  // ✅ static 제거!
  
  // ✨ 화면이 처음 나타날 때 자동으로 실행되는 함수!
  @override
  void initState() {
    super.initState();
    
    // 화면이 완전히 그려진 후에 데이터 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataFromFirebase();
    });
  }
  
  // ✨ Firebase에서 데이터 가져오는 함수
  Future<void> _loadDataFromFirebase() async {
    try {
      print('🔄 HomeScreen: Firebase에서 데이터 가져오기 시작!');
      
      final sleepDataState = Provider.of<SleepDataState>(context, listen: false);
      await sleepDataState.fetchAllSleepReports(context, 'demoUser');
      
      print('✅ HomeScreen: 데이터 가져오기 완료!');
      print('📊 가져온 데이터 개수: ${sleepDataState.sleepHistory.length}개');
      
      if (sleepDataState.sleepHistory.isNotEmpty) {
        print('📈 첫 번째 데이터: ${sleepDataState.sleepHistory.first.totalSleepDuration}시간');
      } else {
        print('⚠️ 데이터가 없습니다. 구름 버튼(☁️)을 눌러 데이터를 생성해주세요!');
      }
    } catch (e) {
      print('❌ 데이터 가져오기 실패: $e');
    }
  }
  
  // 🔧 [백엔드 기능] 가우시안 랜덤 함수
  double _randRange(double min, double max) {  // ✅ static 제거!
    double u = 0, v = 0;
    while (u == 0) u = _random.nextDouble();
    while (v == 0) v = _random.nextDouble();
    double num = sqrt(-2.0 * log(u)) * cos(2.0 * pi * v);
    double mean = (min + max) / 2;
    double stdDev = (max - min) / 5;
    double result = mean + num * stdDev;
    if (_random.nextDouble() < 0.05) return result;
    return result.clamp(min, max);
  }

  // ========================================
  // ✨ [핵심 수정] 7일치 데이터 완벽 생성기
  // ========================================
  Future<void> _generateWeeklyTestData(BuildContext context) async {
    if (!context.mounted) return;

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('데이터 초기화 및\n주간 리포트 생성 중...\n(약 10~20초 소요)'),
          ],
        ),
      ),
    );

    try {
      final userId = 'demoUser';
      final firestore = FirebaseFirestore.instance;

      // 🧹 1. 기존 데이터 "진짜" 삭제
      await _clearCollection(userId, 'raw_data');
      await _clearCollection(userId, 'processed_data');
      await _clearCollection(userId, 'sleep_reports');
      await _clearCollection(userId, 'session_state');
      await _clearCollection(userId, 'sleep_insights');

      // 🏭 2. 데이터 생성 시작 (7일전 ~ 어제)
      final now = DateTime.now();
      int totalRawDocs = 0;

      WriteBatch batch = firestore.batch();
      int batchCount = 0;

      for (int i = 7; i >= 1; i--) {
        final targetDate = now.subtract(Duration(days: i));
        final dateString =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        final sessionId = 'session-$dateString';

        final int startHour = 22 + _random.nextInt(2);
        final int startMin = _random.nextInt(60);
        final int sleepDurationHours = 6 + _random.nextInt(3);

        DateTime sleepStart = DateTime(
            targetDate.year, targetDate.month, targetDate.day, startHour, startMin);
        DateTime sleepEnd = sleepStart.add(Duration(
            hours: sleepDurationHours, minutes: _random.nextInt(60)));

        DateTime currentTime = sleepStart;

        double totalDeep = 0;
        double totalRem = 0;
        double totalLight = 0;
        double totalWake = 0;

        while (currentTime.isBefore(sleepEnd)) {
          String stage = _simulateSleepStage(sleepStart, sleepEnd, currentTime);

          final sensorData = _generateDataForStage(
              stage: stage,
              userId: userId,
              sessionId: sessionId,
              timestamp: currentTime);

          final rawRef = firestore.collection('raw_data').doc();
          batch.set(rawRef, sensorData);

          final processedRef = firestore.collection('processed_data').doc();
          batch.set(processedRef, {
            'userId': userId,
            'sessionId': sessionId,
            'stage': stage,
            'raw_stage': stage,
            'confidence': 1.0,
            'ts': Timestamp.fromDate(currentTime),
            'changed_at': Timestamp.fromDate(currentTime),
            'source_ts': Timestamp.fromDate(currentTime),
          });

          if (stage == 'Deep') totalDeep += 3;
          else if (stage == 'REM') totalRem += 3;
          else if (stage == 'Light') totalLight += 3;
          else totalWake += 3;

          batchCount += 2;
          totalRawDocs++;
          if (batchCount >= 450) {
            await batch.commit();
            batch = firestore.batch();
            batchCount = 0;
          }

          currentTime = currentTime.add(const Duration(minutes: 3));
        }

        final totalDuration = totalDeep + totalRem + totalLight + totalWake;
        final totalHours = totalDuration / 60.0;

        int score = 70 + _random.nextInt(25);
        if (totalHours < 5) score -= 20;
        if (totalDeep / totalDuration < 0.1) score -= 10;
        score = score.clamp(0, 100);

        String message = score > 80 ? "훌륭한 수면입니다!" : "수면 관리가 필요해요.";
        String grade = score > 90 ? "S" : (score > 80 ? "A" : "B");

        final reportRef = firestore.collection('sleep_reports').doc(sessionId);
        batch.set(reportRef, {
          'userId': userId,
          'sessionId': sessionId,
          'total_score': score,
          'grade': grade,
          'message': message,
          'created_at': Timestamp.fromDate(sleepEnd),
          'summary': {
            'total_duration_hours': double.parse(totalHours.toStringAsFixed(1)),
            'deep_sleep_hours': double.parse((totalDeep / 60).toStringAsFixed(1)),
            'rem_sleep_hours': double.parse((totalRem / 60).toStringAsFixed(1)),
            'light_sleep_hours': double.parse((totalLight / 60).toStringAsFixed(1)),
            'awake_hours': double.parse((totalWake / 60).toStringAsFixed(1)),
            'apnea_count': _random.nextInt(5),
            'snoring_duration': _random.nextInt(30),
            'deep_ratio': (totalDeep / totalDuration * 100).round(),
            'rem_ratio': (totalRem / totalDuration * 100).round(),
            'awake_ratio': (totalWake / totalDuration * 100).round(),
          }
        });
        batchCount++;
      }

      if (batchCount > 0) await batch.commit();

      if (context.mounted) {
        Navigator.of(context).pop();
        
        // ✨ 데이터 생성 후 자동으로 새로고침!
        await _loadDataFromFirebase();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ 7일치 데이터 ($totalRawDocs개) 생성 완료!\n화면이 자동으로 갱신되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ 생성 실패: $e'), backgroundColor: Colors.red));
      }
      print(e);
    }
  }

  // 🧹 컬렉션 삭제 헬퍼
  Future<void> _clearCollection(String userId, String collection) async {
    final instance = FirebaseFirestore.instance;
    final batchSize = 400;

    while (true) {
      var snapshot = await instance
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .limit(batchSize)
          .get();

      if (snapshot.docs.isEmpty) break;

      var batch = instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  String _simulateSleepStage(DateTime start, DateTime end, DateTime current) {
    final totalMinutes = end.difference(start).inMinutes;
    final elapsedMinutes = current.difference(start).inMinutes;
    final progress = elapsedMinutes / totalMinutes;

    if (progress < 0.3) {
      return _random.nextDouble() < 0.6 ? 'Deep' : 'Light';
    } else if (progress < 0.7) {
      double r = _random.nextDouble();
      if (r < 0.1) return 'Snoring';
      if (r < 0.4) return 'Deep';
      if (r < 0.6) return 'REM';
      return 'Light';
    } else {
      double r = _random.nextDouble();
      if (r < 0.05) return 'Awake';
      if (r < 0.4) return 'REM';
      return 'Light';
    }
  }

  Map<String, dynamic> _generateDataForStage({
    required String stage,
    required String userId,
    required String sessionId,
    required DateTime timestamp,
  }) {
    double hrMin, hrMax, spo2Min, spo2Max, micMin, micMax, pressureMin, pressureMax;

    switch (stage) {
      case 'Deep':
        hrMin = 50; hrMax = 60; spo2Min = 97; spo2Max = 99; micMin = 5; micMax = 20; pressureMin = 800; pressureMax = 1200;
        break;
      case 'Light':
        hrMin = 60; hrMax = 75; spo2Min = 96; spo2Max = 99; micMin = 20; micMax = 40; pressureMin = 800; pressureMax = 1300;
        break;
      case 'REM':
        hrMin = 65; hrMax = 85; spo2Min = 96; spo2Max = 99; micMin = 10; micMax = 30; pressureMin = 800; pressureMax = 1200;
        break;
      case 'Awake':
        hrMin = 80; hrMax = 110; spo2Min = 97; spo2Max = 100; micMin = 40; micMax = 100; pressureMin = 0; pressureMax = 100;
        break;
      case 'Tossing':
        hrMin = 70; hrMax = 90; spo2Min = 96; spo2Max = 99; micMin = 30; micMax = 80; pressureMin = 3000; pressureMax = 4095;
        break;
      case 'Snoring':
        hrMin = 60; hrMax = 75; spo2Min = 93; spo2Max = 96; micMin = 150; micMax = 255; pressureMin = 800; pressureMax = 1300;
        break;
      case 'Apnea':
        hrMin = 75; hrMax = 95; spo2Min = 80; spo2Max = 88; micMin = 0; micMax = 5; pressureMin = 500; pressureMax = 900;
        break;
      default:
        hrMin = 60; hrMax = 75; spo2Min = 96; spo2Max = 99; micMin = 10; micMax = 30; pressureMin = 800; pressureMax = 1200;
        break;
    }
    return {
      'hr': _randRange(hrMin, hrMax).toInt(),
      'spo2': _randRange(spo2Min, spo2Max).toInt(),
      'mic_avg': _randRange(micMin, micMax).toInt(),
      'pressure_avg': _randRange(pressureMin, pressureMax).toInt(),
      'mic_1_avg_10s': 0, 'mic_2_avg_10s': 0,
      'pressure_1_avg_10s': 0, 'pressure_2_avg_10s': 0, 'pressure_3_avg_10s': 0,
      'pillow_battery': 100, 'watch_battery': 100,
      'auto_control_active': false,
      'is_snoring': false,
      'userId': userId,
      'sessionId': sessionId,
      'ts': Timestamp.fromDate(timestamp),
      'label': stage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ 헤더 섹션
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘 밤은 어떨까요?',
                              style:
                                  AppTextStyles.heading2.copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '수면 측정을 시작해 주세요.',
                              style: AppTextStyles.secondaryBodyText.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Consumer<SettingsState>(
                          builder: (context, settingsState, _) {
                            final iconColor = settingsState.isDarkMode
                                ? AppColors.darkPrimaryText
                                : AppColors.primaryText;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.cloud_upload_outlined),
                                  color: iconColor,
                                  tooltip: '7일치 데이터 생성',
                                  onPressed: () => _generateWeeklyTestData(context),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.star_border_rounded),
                                  color: iconColor,
                                  tooltip: '하드웨어 테스트',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const HardwareTestScreen()),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    settingsState.isDarkMode
                                        ? Icons.wb_sunny_outlined
                                        : Icons.mode_night_outlined,
                                    size: 28,
                                  ),
                                  color: iconColor,
                                  onPressed: () {
                                    settingsState.toggleDarkMode(
                                        !settingsState.isDarkMode);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                Center(child: _buildMeasurementButton(context, appState)),

                const SizedBox(height: 24),
                _buildPlaceholderInfoCards(),
                const SizedBox(height: 24),
                _buildDeviceCards(context),
                const SizedBox(height: 24),
                _buildSummaryCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealTimeMetricsCard(BuildContext context, AppState appState) {
    if (!appState.isMeasuring) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(
              icon: Icons.favorite,
              label: '심박수',
              value: appState.currentHeartRate.toStringAsFixed(0),
              unit: 'BPM',
              color: AppColors.errorRed,
            ),
            _buildMetricItem(
              icon: Icons.opacity,
              label: '산소포화도',
              value: appState.currentSpo2.toStringAsFixed(0),
              unit: '%',
              color: AppColors.primaryNavy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
        Text(unit, style: AppTextStyles.smallText),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.secondaryBodyText),
      ],
    );
  }

  Widget _buildMeasurementButton(BuildContext context, AppState appState) {
    final bool isMeasuring = appState.isMeasuring;
    final Color colDeep = const Color(0xFF011F25);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final bleService = Provider.of<BleService>(context, listen: false);
            if (isMeasuring) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text('수면 종료',
                      style: TextStyle(
                          color: colDeep, fontWeight: FontWeight.bold)),
                  content: const Text('측정을 종료하시겠습니까?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소',
                            style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colDeep,
                          foregroundColor: Colors.white),
                      onPressed: () {
                        bleService.stopDataCollection();
                        appState.toggleMeasurement(context);
                        Navigator.pop(context);
                      },
                      child: const Text('종료'),
                    ),
                  ],
                ),
              );
            } else {
              if (!bleService.isPillowConnected &&
                  !bleService.isWatchConnected) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('기기를 연결해주세요.')));
                return;
              }
              bleService.startDataCollection();
              appState.toggleMeasurement(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const SleepModeScreen(key: Key('sleepModeScreen'))));
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: isMeasuring
                ? _buildMeasuringState(colDeep)
                : const SleepStartJellyIcon(),
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: [
            Text(
              isMeasuring ? "편안한 밤 되세요" : "수면 시작",
              style: AppTextStyles.heading2.copyWith(
                  color: const Color(0xFF6292BE), fontSize: 22, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              isMeasuring ? "수면 데이터를 분석하고 있습니다" : "베개를 톡 눌러 꿈나라로 떠나보세요",
              style: AppTextStyles.secondaryBodyText
                  .copyWith(color: const Color(0xFFBD9A8E), fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasuringState(Color colDeep) {
    return Container(
      width: 180,
      height: 140,
      decoration: BoxDecoration(
        color: colDeep.withOpacity(0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: colDeep.withOpacity(0.1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SpinKitRipple(
            color: const Color(0xFF6292BE),
            size: 120.0,
            borderWidth: 4.0,
          ),
          Icon(Icons.stop_rounded, size: 48, color: colDeep),
        ],
      ),
    );
  }

  Widget _buildPlaceholderInfoCards() {
    return Consumer<SleepDataState>(
      builder: (context, sleepDataState, child) {
        final metrics = sleepDataState.todayMetrics;
        final totalHours = metrics.totalSleepDuration;
        final hours = totalHours.floor();
        final minutes = ((totalHours - hours) * 60).round();
        final centerValue = '$hours시간 $minutes분';
        
        final targetHours = 8.0;
        final progress = (totalHours / targetHours).clamp(0.0, 1.0);
        
        return Column(
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildAnimatedDonutContent(
                  title: '목표: ${targetHours.toInt()}시간',
                  centerValue: centerValue,
                  footerLabel: '오늘의 수면 달성률',
                  progress: progress,
                  color: const Color(0xFF6292BE),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDeviceCards(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, bleService, child) {
        return Column(
          children: [
            _buildDeviceCard(
              deviceName: '스마트 베개 Pro',
              deviceType: '스마트 베개',
              isConnected: bleService.isPillowConnected,
              batteryPercentage: bleService.pillowBattery,
              version: 'v1.0.0',
            ),
            const SizedBox(height: 16),
            _buildDeviceCard(
              deviceName: '수면 팔찌 Plus',
              deviceType: '스마트 팔찌',
              isConnected: bleService.isWatchConnected,
              batteryPercentage: bleService.watchBattery,
              version: 'v1.0.0',
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceCard({
    required String deviceName,
    required String deviceType,
    required bool isConnected,
    required int batteryPercentage,
    required String version,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.wifi,
              color: isConnected
                  ? AppColors.successGreen
                  : AppColors.secondaryText,
              size: 24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(deviceType, style: AppTextStyles.secondaryBodyText),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      batteryPercentage > 20
                          ? Icons.battery_full
                          : Icons.battery_alert,
                      color: batteryPercentage > 20
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$batteryPercentage%',
                      style: AppTextStyles.secondaryBodyText,
                    ),
                  ],
                ),
                Text(
                  isConnected ? version : '미연결',
                  style: AppTextStyles.smallText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Consumer<SleepDataState>(
      builder: (context, sleepDataState, _) {
        final history = sleepDataState.sleepHistory;

        String avgSleepStr = '-';
        String avgSnoringStr = '-';
        String avgEfficiencyStr = '-';
        String avgRemStr = '-';

        if (history.isNotEmpty) {
          final recentHistory = history.take(7).toList();
          final analyzer = SleepScoreAnalyzer();

          double totalSleep = 0;
          double totalSnoringScore = 0;
          double totalEfficiency = 0;
          double totalRem = 0;

          for (var metric in recentHistory) {
            totalSleep += metric.totalSleepDuration;
            double score = analyzer.getSnoringScore(
              metric.avgSnoringDuration,
              metric.totalSleepDuration * 60,
            );
            totalSnoringScore += score;
            totalEfficiency += metric.sleepEfficiency;
            totalRem += metric.remRatio;
          }

          final count = recentHistory.length;
          final avgSleep = totalSleep / count;
          final hours = avgSleep.floor();
          final minutes = ((avgSleep - hours) * 60).round();
          avgSleepStr = '${hours}시간 ${minutes}분';

          final avgSnoringScore = totalSnoringScore / count;
          avgSnoringStr = '${avgSnoringScore.toStringAsFixed(1)}점';

          final avgEfficiency = totalEfficiency / count;
          avgEfficiencyStr = '${avgEfficiency.toStringAsFixed(0)}%';

          final avgRem = totalRem / count;
          avgRemStr = '${avgRem.toStringAsFixed(0)}%';
        }

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('최근 7일 수면 요약', style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(avgSleepStr, '평균 수면', context),
                    _buildSummaryItem(avgSnoringStr, '평균 코골이', context),
                    _buildSummaryItem(avgEfficiencyStr, '수면 효율', context),
                    _buildSummaryItem(avgRemStr, 'REM 비율', context),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String value, String label, BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTextStyles.secondaryBodyText.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAnimatedDonutContent({
    required String title,
    required String centerValue,
    required String footerLabel,
    required double progress,
    Color color = AppColors.primaryNavy,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                centerValue,
                style: AppTextStyles.heading2.copyWith(color: color),
              ),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(footerLabel, style: AppTextStyles.secondaryBodyText),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey.shade300.withOpacity(0.3),
                        ),
                        strokeWidth: 12,
                      ),
                      CircularProgressIndicator(
                        value: value,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Text(
                          '${(value * 100).toInt()}%',
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ========================================
// 🎨 SleepStartJellyIcon (변경 없음)
// ========================================

class SleepStartJellyIcon extends StatelessWidget {
  const SleepStartJellyIcon({super.key});

  @override
  Widget build(BuildContext context) {
    const double width = 200;
    const double height = 150;
    const Color colRose = Color(0xFFBD9A8E);
    const Color colBlue = Color(0xFF6292BE);
    const Color colMoon = Color(0xFFF2E6E6);

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(width, height),
          painter: _SoftPillowPainter(),
        ),
        ClipPath(
          clipper: _SoftPillowClipper(),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colBlue.withOpacity(0.4),
                  colRose.withOpacity(0.3),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 40, left: -20, right: -20, height: 80,
                  child: _buildWave(colBlue.withOpacity(0.5), 0.1),
                ),
                Positioned(
                  bottom: 20, left: -30, right: -30, height: 90,
                  child: _buildWave(colRose.withOpacity(0.6), -0.15),
                ),
                Positioned(
                  bottom: -10, left: -20, right: -20, height: 100,
                  child: _buildWave(colMoon.withOpacity(0.8), 0.05),
                ),
                ..._buildSparkles(),
                Positioned(
                  top: 30, left: 0, right: 0,
                  child: Center(
                    child: Transform.rotate(
                      angle: -math.pi / 8,
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          color: colMoon,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colRose.withOpacity(0.5),
                              blurRadius: 20, spreadRadius: 2,
                              offset: const Offset(2, 4),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 10, spreadRadius: -2,
                              offset: const Offset(-2, -2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.nightlight_round,
                          size: 45,
                          color: colRose.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0, left: 0, right: 0, height: height / 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildWave(Color color, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              const BorderRadius.vertical(top: Radius.elliptical(200, 60)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _buildSparkles() {
    final random = math.Random(42);
    final sparkles = <Widget>[];
    final positions = [
      const Offset(30, 40), const Offset(170, 30), const Offset(160, 110),
      const Offset(40, 100), const Offset(100, 20), const Offset(150, 60)
    ];

    for (var pos in positions) {
      sparkles.add(
        Positioned(
          top: pos.dy,
          left: pos.dx,
          child: Container(
            width: random.nextDouble() * 3 + 2,
            height: random.nextDouble() * 3 + 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: const [
                BoxShadow(color: Colors.white, blurRadius: 3, spreadRadius: 1),
              ],
            ),
          ),
        ),
      );
    }
    return sparkles;
  }
}

Path _getSoftPillowPath(Size size) {
  final path = Path();
  final w = size.width;
  final h = size.height;
  const double r = 30.0;
  const double curve = 10.0;

  path.moveTo(0, r);
  path.quadraticBezierTo(curve, h / 2, 0, h - r);
  path.quadraticBezierTo(0, h, r, h);
  path.quadraticBezierTo(w / 2, h - curve, w - r, h);
  path.quadraticBezierTo(w, h, w, h - r);
  path.quadraticBezierTo(w - curve, h / 2, w, r);
  path.quadraticBezierTo(w, 0, w - r, 0);
  path.quadraticBezierTo(w / 2, curve, r, 0);
  path.quadraticBezierTo(0, 0, 0, r);
  path.close();
  return path;
}

class _SoftPillowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _getSoftPillowPath(size);
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _SoftPillowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _getSoftPillowPath(size);
    canvas.drawShadow(
      path,
      const Color(0xFF6292BE).withOpacity(0.3),
      15.0,
      true,
    );
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
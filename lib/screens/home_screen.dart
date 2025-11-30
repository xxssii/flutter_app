// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/app_state.dart';
import '../state/settings_state.dart';
import '../state/sleep_data_state.dart';
import '../utils/sleep_score_analyzer.dart';
import 'sleep_mode_screen.dart';
import '../services/ble_service.dart';
// 🔔 알림 서비스 import 추가
import '../services/notification_service.dart';
import 'hardware_test_screen.dart'; // ✅ 하드웨어 테스트 화면 import

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 사용하지 않는 색상 변수 제거됨
  static final _random = Random();
  static double _randRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  // ========================================
  // ✨ 7일치 테스트 데이터 생성
  // ========================================
  Future<void> _generateWeeklyTestData(BuildContext context) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('7일치 데이터 생성 중...'),
          ],
        ),
      ),
    );

    try {
      final now = DateTime.now();
      int totalDataPoints = 0;

      for (int dayOffset = 6; dayOffset >= 0; dayOffset--) {
        final date = now.subtract(Duration(days: dayOffset));
        final dateString =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final sessionId = 'session-$dateString';
        final userId = 'demo_user';

        print('📅 날짜: $dateString 데이터 생성 시작...');

        DateTime currentTime = DateTime(date.year, date.month, date.day, 22, 0);
        final sleepCycle = _generateRealisticSleepCycle();

        for (int minute = 0; minute < 480; minute++) {
          final stage = sleepCycle[minute];
          final data = _generateDataForStage(
            stage: stage,
            userId: userId,
            sessionId: sessionId,
            timestamp: currentTime,
          );

          await FirebaseFirestore.instance.collection('raw_data').add(data);
          currentTime = currentTime.add(const Duration(minutes: 1));
          totalDataPoints++;

          if (totalDataPoints % 100 == 0) {
            print('✅ $totalDataPoints개 데이터 저장됨...');
          }
        }

        print('✅ $dateString 완료! (480개 데이터)');
      }

      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 7일치 데이터 생성 완료! (총 $totalDataPoints개)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('🎉 전체 완료! 총 $totalDataPoints개 데이터 생성됨');
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 데이터 생성 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ 오류 발생: $e');
    }
  }

  List<String> _generateRealisticSleepCycle() {
    final List<String> cycle = [];
    cycle.addAll(List.filled(60, 'Light'));
    cycle.addAll(List.filled(120, 'Deep'));
    cycle.addAll(List.filled(90, 'Light'));
    cycle.addAll(List.filled(30, 'REM'));
    cycle.addAll(List.filled(90, 'Deep'));
    cycle.addAll(List.filled(30, 'Light'));
    cycle.addAll(List.filled(30, 'REM'));
    cycle.addAll(List.filled(30, 'Light'));
    return cycle;
  }

  Map<String, dynamic> _generateDataForStage({
    required String stage,
    required String userId,
    required String sessionId,
    required DateTime timestamp,
  }) {
    double hrMin,
        hrMax,
        spo2Min,
        spo2Max,
        micMin,
        micMax,
        pressureMin,
        pressureMax;

    switch (stage) {
      case 'Light':
        hrMin = 60;
        hrMax = 70;
        spo2Min = 96;
        spo2Max = 98;
        micMin = 10;
        micMax = 40;
        pressureMin = 500;
        pressureMax = 1500;
        break;
      case 'Deep':
        hrMin = 50;
        hrMax = 60;
        spo2Min = 96;
        spo2Max = 98;
        micMin = 5;
        micMax = 20;
        pressureMin = 100;
        pressureMax = 500;
        break;
      case 'REM':
        hrMin = 65;
        hrMax = 75;
        spo2Min = 96;
        spo2Max = 98;
        micMin = 5;
        micMax = 20;
        pressureMin = 100;
        pressureMax = 500;
        break;
      default:
        hrMin = 60;
        hrMax = 70;
        spo2Min = 96;
        spo2Max = 98;
        micMin = 10;
        micMax = 30;
        pressureMin = 500;
        pressureMax = 1000;
    }

    return {
      'hr': _randRange(hrMin, hrMax).toInt(),
      'spo2': _randRange(spo2Min, spo2Max),
      'mic_level': _randRange(micMin, micMax).toInt(),
      'pressure_level': _randRange(pressureMin, pressureMax).toInt(),
      'userId': userId,
      'sessionId': sessionId,
      'ts': Timestamp.fromDate(timestamp),
    };
  }

  // ========================================
  // ✨ 수면 점수 계산 테스트
  // ========================================
  Future<void> _testCalculateSleepScore(BuildContext context) async {
    final now = DateTime.now();
    final dateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final sessionId = 'session-$dateString';

    print('🧪 테스트 시작: sessionId = $sessionId');

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('수면 점수 계산 중...'),
          ],
        ),
      ),
    );

    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'asia-northeast3',
      );
      final callable = functions.httpsCallable('calculate_sleep_score');

      final result = await callable.call({'session_id': sessionId});

      final data = result.data;

      if (!context.mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 수면 점수'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('세션: $sessionId', style: const TextStyle(fontSize: 12)),
                const Divider(),
                Text(
                  '총점: ${data['total_score']}점',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('등급: ${data['grade']}'),
                Text('평가: ${data['message']}'),
                const SizedBox(height: 16),
                const Text(
                  '수면 요약:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('총 수면: ${data['summary']['total_duration_hours']}시간'),
                Text('깊은 수면: ${data['summary']['deep_sleep_hours']}시간'),
                Text('REM 수면: ${data['summary']['rem_sleep_hours']}시간'),
                Text('얕은 수면: ${data['summary']['light_sleep_hours']}시간'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );

      print('✅ 테스트 성공!');
      print('점수: ${data['total_score']}');
      print('총 수면 시간: ${data['summary']['total_duration_hours']}시간');
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 오류 발생: $e'), backgroundColor: Colors.red),
        );
      }
      print('❌ 직접 계산 실패: $e');
    }
  }

  // ========================================
  // 🔧 Cloud Functions 트리거 테스트
  // ========================================
  Future<void> _testOnNewDataTrigger(BuildContext context) async {
    print('🔧 트리거 테스트 시작...');

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('트리거 테스트 중...'),
          ],
        ),
      ),
    );

    try {
      final now = DateTime.now();
      final testSessionId = 'test-trigger-${now.millisecondsSinceEpoch}';

      print('📝 raw_data에 테스트 데이터 추가 중...');

      final docRef =
          await FirebaseFirestore.instance.collection('raw_data').add({
        'hr': 65,
        'spo2': 97.5,
        'mic_level': 20,
        'pressure_level': 300,
        'userId': 'test_user',
        'sessionId': testSessionId,
        'ts': Timestamp.now(),
      });

      print('✅ raw_data 추가 완료! docId: ${docRef.id}');

      print('⏳ 5초 대기 중 (트리거 실행 시간)...');
      await Future.delayed(const Duration(seconds: 5));

      print('🔍 processed_data 확인 중...');

      final processedQuery = await FirebaseFirestore.instance
          .collection('processed_data')
          .where('sessionId', isEqualTo: testSessionId)
          .get();

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (processedQuery.docs.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ 트리거 작동 안 함'),
            content: const Text('5초를 기다렸지만 processed_data에 데이터가 생성되지 않았습니다.\n\n'
                'Cloud Functions의 on_new_data 트리거가 작동하지 않고 있습니다.\n\n'
                '원인:\n'
                '1. Functions 배포 안 됨\n'
                '2. 트리거 설정 오류\n'
                '3. 코드 오류'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        print('❌ 트리거 작동 안 함!');
      } else {
        final processedDoc = processedQuery.docs.first;
        final stage = processedDoc['stage'];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ 트리거 작동함!'),
            content: Text('Cloud Functions가 정상 작동합니다!\n\n'
                '분류된 단계: $stage\n\n'
                'processed_data에 데이터가 생성되었습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        print('✅ 트리거 작동함! stage: $stage');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ 테스트 실패: $e');
    }
  }

  // ========================================
  // 훈련 데이터 생성
  // ========================================
  Future<void> _pushBurstData(BuildContext context, String label) async {
    final String userId = "train_user_v3";
    final String sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";

    for (int i = 0; i < 10; i++) {
      double hrMin = 60,
          hrMax = 70,
          spo2Min = 96,
          spo2Max = 99,
          micMin = 10,
          micMax = 30,
          pressureMin = 500,
          pressureMax = 1000;

      switch (label) {
        case 'Awake':
          hrMin = 70;
          hrMax = 90;
          spo2Min = 97;
          spo2Max = 99;
          micMin = 100;
          micMax = 160;
          pressureMin = 1500;
          pressureMax = 2500;
          break;
        case 'Light':
          hrMin = 60;
          hrMax = 70;
          spo2Min = 96;
          spo2Max = 98;
          micMin = 10;
          micMax = 40;
          pressureMin = 500;
          pressureMax = 1500;
          break;
        case 'Deep':
          hrMin = 50;
          hrMax = 60;
          spo2Min = 96;
          spo2Max = 98;
          micMin = 5;
          micMax = 20;
          pressureMin = 100;
          pressureMax = 500;
          break;
        case 'REM':
          hrMin = 65;
          hrMax = 75;
          spo2Min = 96;
          spo2Max = 98;
          micMin = 5;
          micMax = 20;
          pressureMin = 100;
          pressureMax = 500;
          break;
        case 'Snoring':
          hrMin = 65;
          hrMax = 80;
          spo2Min = 94;
          spo2Max = 97;
          micMin = 180;
          micMax = 250;
          pressureMin = 200;
          pressureMax = 800;
          break;
        case 'Tossing':
          hrMin = 70;
          hrMax = 85;
          spo2Min = 97;
          spo2Max = 99;
          micMin = 20;
          micMax = 70;
          pressureMin = 3000;
          pressureMax = 4095;
          break;
        case 'Apnea':
          hrMin = 75;
          hrMax = 90;
          spo2Min = 80;
          spo2Max = 90;
          micMin = 0;
          micMax = 10;
          pressureMin = 100;
          pressureMax = 500;
          break;
      }

      final Map<String, dynamic> data = {
        'hr': _randRange(hrMin, hrMax).toInt(),
        'spo2': _randRange(spo2Min, spo2Max),
        'mic_level': _randRange(micMin, micMax).toInt(),
        'pressure_level': _randRange(pressureMin, pressureMax).toInt(),
        'label': label,
        'userId': userId,
        'sessionId': sessionId,
        'ts': FieldValue.serverTimestamp(),
      };

      try {
        await FirebaseFirestore.instance.collection('raw_data').add(data);
        if (i < 9) {
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        print("❌ 데이터 저장 실패: $e");
        if (i == 0 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Firebase 저장 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      }
    }

    print("✅ $label 훈련 데이터 (10건) 전송 완료 (v3 스키마)");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $label 훈련 데이터 (10건) 전송 완료 (v3 스키마)'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
                // ✅ PillowScreen 스타일의 헤더 (SafeArea + Padding)
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
                        // 다크모드 토글 버튼
                        Consumer<SettingsState>(
                          builder: (context, settingsState, _) {
                            final iconColor = settingsState.isDarkMode
                                ? AppColors.darkPrimaryText
                                : AppColors.primaryText;
                            return IconButton(
                              icon: Icon(
                                settingsState.isDarkMode
                                    ? Icons.wb_sunny_outlined
                                    : Icons.mode_night_outlined,
                                color: iconColor,
                                size: 28,
                              ),
                              onPressed: () {
                                settingsState
                                    .toggleDarkMode(!settingsState.isDarkMode);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Center(child: _buildMeasurementButton(context, appState)),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "--- [0단계] 테스트 데이터 생성 (날짜별 분리) ---",
                        style: AppTextStyles.secondaryBodyText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _generateWeeklyTestData(context),
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('7일치 테스트 데이터 생성 (날짜별)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '각 날짜마다 다른 sessionId로 8시간 수면 데이터 생성',
                        style: AppTextStyles.smallText.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _testCalculateSleepScore(context),
                        icon: const Icon(Icons.analytics),
                        label: const Text('📊 수면 점수 계산 테스트'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '가장 최근 세션의 수면 점수 계산',
                        style: AppTextStyles.smallText.copyWith(
                          color: Colors.grey,
                        ),
                      ),

                      // ========================================
                      // ✨ 새로 추가: 트리거 테스트 버튼
                      // ========================================
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _testOnNewDataTrigger(context),
                        icon: const Icon(Icons.bug_report),
                        label: const Text('🔧 Cloud Functions 트리거 테스트'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'raw_data에 1개 테스트 데이터 추가 (트리거 확인용)',
                        style: AppTextStyles.smallText.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "-----------------------------------------",
                        style: AppTextStyles.secondaryBodyText,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "--- [1단계] 훈련 데이터 생성기 (v3: 진짜 범위) ---",
                        style: AppTextStyles.secondaryBodyText,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _pushBurstData(context, 'Awake'),
                        child: const Text('Awake 훈련 데이터 (10s)'),
                      ),
                      ElevatedButton(
                        onPressed: () => _pushBurstData(context, 'Light'),
                        child: const Text('Light 훈련 데이터 (10s)'),
                      ),
                      ElevatedButton(
                        onPressed: () => _pushBurstData(context, 'Deep'),
                        child: const Text('Deep 훈련 데이터 (10s)'),
                      ),
                      ElevatedButton(
                        onPressed: () => _pushBurstData(context, 'REM'),
                        child: const Text('REM 훈련 데이터 (10s)'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _pushBurstData(context, 'Snoring'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: const Text('★ 코골이(Snoring) 훈련 데이터 (10s)'),
                      ),
                      ElevatedButton(
                        onPressed: () => _pushBurstData(context, 'Tossing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                        ),
                        child: const Text('★ 뒤척임(Tossing) 훈련 데이터 (10s)'),
                      ),
                      ElevatedButton(
                        onPressed: () => _pushBurstData(context, 'Apnea'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('★ 무호흡(Apnea) 훈련 데이터 (10s)'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "-----------------------------------------",
                        style: AppTextStyles.secondaryBodyText,
                      ),
                    ],
                  ),
                ),
                // 🔔 [신규] 알림 시뮬레이션 버튼 추가
                // ===============================================
                // ✨✨✨ 새로 추가된 하드웨어 테스트 섹션 ✨✨✨
                // ===============================================
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "--- [2단계] 알림 시뮬레이션 (즉시 발송) ---",
                        style: AppTextStyles.secondaryBodyText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 1. 수면 리포트 알림 시뮬레이션
                      ElevatedButton.icon(
                        onPressed: () {
                          // 실제로는 아침에 예약되지만, 시연을 위해 즉시 발송합니다.
                          NotificationService.instance.showImmediateWarning(
                            1, // ID
                            '☀️ 좋은 아침입니다!',
                            '지난밤 수면 효율은 92%입니다. 리포트를 확인해보세요.',
                          );
                        },
                        icon: const Icon(Icons.wb_sunny),
                        label: const Text('시뮬레이션: 아침 리포트 알림'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 2. 수면 효율 저하 알림 시뮬레이션
                      ElevatedButton.icon(
                        onPressed: () {
                          // 설정값 확인 (설정이 켜져 있을 때만 알림 발송)
                          final settings = Provider.of<SettingsState>(
                            context,
                            listen: false,
                          );
                          if (settings.isEfficiencyOn) {
                            NotificationService.instance.showImmediateWarning(
                              2, // ID
                              '⚠️ 수면 효율 저하 감지',
                              '깊은 잠이 부족했어요. 오늘은 카페인 섭취를 줄여보세요.',
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('수면 효율 알림 설정이 꺼져 있습니다.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.warning_amber),
                        label: const Text('시뮬레이션: 효율 저하 알림 (조건부)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 3. 코골이 알림 시뮬레이션
                      ElevatedButton.icon(
                        onPressed: () {
                          // 설정값 확인
                          final settings = Provider.of<SettingsState>(
                            context,
                            listen: false,
                          );
                          if (settings.isSnoringOn) {
                            NotificationService.instance.showImmediateWarning(
                              3, // ID
                              '💤 코골이 감지',
                              '심한 코골이가 감지되었습니다. 베개 높이를 조절해보세요.',
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('코골이 알림 설정이 꺼져 있습니다.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.mic_off),
                        label: const Text('시뮬레이션: 코골이 알림 (조건부)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      // ===============================================
                      // [하드웨어] 기기 제어 및 테스트
                      // ===============================================
                      Text(
                        "--- [하드웨어] 기기 제어 및 테스트 ---",
                        style: AppTextStyles.secondaryBodyText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                        ),
                        icon: const Icon(Icons.build),
                        label: const Text(
                          "🛠️ 하드웨어 테스트 화면으로 이동",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const HardwareTestScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '펌프, 밸브, 진동 모터 개별 제어',
                        style: AppTextStyles.smallText.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "-----------------------------------------",
                        style: AppTextStyles.secondaryBodyText,
                      ),
                    ],
                  ),
                ),
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

  // ✅ 측정 버튼 (BleService 연동)
  Widget _buildMeasurementButton(BuildContext context, AppState appState) {
    final bool isMeasuring = appState.isMeasuring;
    final buttonText = isMeasuring ? '수면 측정 중지' : '수면 측정 시작';
    final descriptionText =
        isMeasuring ? '수면을 측정하고 있습니다.' : '버튼을 눌러 수면 측정을 시작하세요.';

    // 다크모드 감지하여 아이콘 색상 변경
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isMeasuring
        ? AppColors.errorRed
        : (isDarkMode ? const Color(0xFF6292BE) : AppColors.primaryNavy);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final bleService = Provider.of<BleService>(context, listen: false);

            if (isMeasuring) {
              // 측정 중지
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('수면 측정 종료'),
                    content: const Text('수면 측정을 종료하시겠습니까?\n(기기 연결은 유지됩니다)'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          // ✅ 수정됨: 데이터 수집만 중지하는 함수 호출
                          bleService.stopDataCollection();
                          appState.toggleMeasurement(context);
                          Navigator.of(dialogContext).pop();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                // ✅ 메시지 수정
                                content: Text('수면 측정이 종료되었습니다. (기기 연결 유지됨)'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          '종료',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            } else {
              // 측정 시작
              if (!bleService.isPillowConnected &&
                  !bleService.isWatchConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    // ✅ const 제거함
                    content: const Text('먼저 기기를 연결해주세요!'),
                    // ✅ 배경색을 테마 색상 변수로 변경
                    backgroundColor: AppColors.primaryNavy,
                  ),
                );
                return;
              }

              bleService.startDataCollection();
              appState.toggleMeasurement(context);

              if (appState.isMeasuring) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const SleepModeScreen(key: Key('sleepModeScreen')),
                  ),
                );
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('수면 측정을 시작합니다 ✨'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: buttonColor.withOpacity(0.1),
            ),
            child: isMeasuring
                ? SpinKitPulse(color: buttonColor, size: 80.0)
                : Icon(Icons.nights_stay_rounded, color: buttonColor, size: 80),
          ),
        ),
        const SizedBox(height: 16),
        Text(buttonText, style: AppTextStyles.heading2),
        const SizedBox(height: 8),
        Text(descriptionText, style: AppTextStyles.secondaryBodyText),
      ],
    );
  }

  // ✅ 수정됨: 도넛 그래프를 사용하여 정보를 표시하는 함수
  Widget _buildPlaceholderInfoCards() {
    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildAnimatedDonutContent(
              title: '목표: 8시간',
              centerValue: '6시간 48분',
              footerLabel: '오늘의 수면 달성률',
              progress: 0.85,
              // 팔레트 색상: #6292BE
              color: const Color(0xFF6292BE),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildAnimatedDonutContent(
              title: '권장: 10~12cm',
              centerValue: '12cm',
              footerLabel: '현재 높이 상태',
              progress: 0.6,
              // 팔레트 색상: #B5C1D4
              color: const Color(0xFFB5C1D4),
            ),
          ),
        ),
      ],
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
                // if (isConnected)
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
          // 최근 7개 데이터만 사용
          final recentHistory = history.take(7).toList();
          final analyzer = SleepScoreAnalyzer();

          double totalSleep = 0;
          double totalSnoringScore = 0;
          double totalEfficiency = 0;
          double totalRem = 0;

          for (var metric in recentHistory) {
            totalSleep += metric.totalSleepDuration;

            // ✅ 코골이 점수 계산 (10점 만점)
            double score = analyzer.getSnoringScore(
              metric.avgSnoringDuration, // 분 단위
              metric.totalSleepDuration * 60, // 분 단위로 변환
            );
            totalSnoringScore += score;

            totalEfficiency += metric.sleepEfficiency;
            totalRem += metric.remRatio;
          }

          final count = recentHistory.length;

          // 평균 수면 시간 포맷팅
          final avgSleep = totalSleep / count;
          final hours = avgSleep.floor();
          final minutes = ((avgSleep - hours) * 60).round();
          avgSleepStr = '${hours}시간 ${minutes}분';

          // 평균 코골이 점수
          final avgSnoringScore = totalSnoringScore / count;
          avgSnoringStr = '${avgSnoringScore.toStringAsFixed(1)}점';

          // 수면 효율
          final avgEfficiency = totalEfficiency / count;
          avgEfficiencyStr = '${avgEfficiency.toStringAsFixed(0)}%';

          // REM 비율
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

  // ✅ 도넛 그래프 위젯 (애니메이션 복원 및 테마 적용됨)
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
                        // ✅ [테마 적용] 배경색 투명도 조절
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

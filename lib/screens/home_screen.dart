// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
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
  // 🔧 [백엔드 기능] 가우시안 랜덤 함수 (더 현실적인 데이터 분포)
  static double _randRange(double min, double max) {
    // Box-Muller 변환으로 정규분포 난수 생성
    double u = 0, v = 0;
    while (u == 0) u = _random.nextDouble();
    while (v == 0) v = _random.nextDouble();
    double num = sqrt(-2.0 * log(u)) * cos(2.0 * pi * v);

    // 평균값 중심으로 퍼뜨리기
    double mean = (min + max) / 2;
    
    // 🚨 [수정] 표준편차를 키워서 데이터를 더 지저분하게 만듦
    // 기존: / 12 (너무 깔끔) -> 변경: / 5 (적당히 지저분함)
    double stdDev = (max - min) / 5;
    double result = mean + num * stdDev;

    // 가끔은 범위 밖으로 튀는 데이터(이상치)도 허용 (약간의 확률로 clamp 안 함)
    if (_random.nextDouble() < 0.05) return result;

    // 그래도 최소/최대 범위는 넘지 않게 자르기 (안전장치)
    return result.clamp(min, max);
  }

  // ========================================
  // ✨ 7일치 테스트 데이터 생성
  // ========================================
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
      print("🧹 데이터 청소 시작...");
      await _clearCollection(userId, 'raw_data');
      await _clearCollection(userId, 'processed_data');
      await _clearCollection(userId, 'sleep_reports');
      await _clearCollection(userId, 'session_state');
      await _clearCollection(userId, 'sleep_insights'); // 인사이트도 삭제
      print("🧹 데이터 청소 완료!");

      // 🏭 2. 데이터 생성 시작 (7일전 ~ 어제)
      final now = DateTime.now();
      int totalRawDocs = 0;

      WriteBatch batch = firestore.batch();
      int batchCount = 0;

      // 7일치 루프
      for (int i = 7; i >= 1; i--) {
        final targetDate = now.subtract(Duration(days: i));

        // 날짜 기반 세션 ID 생성
        final dateString =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        final sessionId = 'session-$dateString';

        // 수면 시간 설정 (랜덤)
        final int startHour = 22 + _random.nextInt(2); // 22시 ~ 23시
        final int startMin = _random.nextInt(60);
        final int sleepDurationHours = 6 + _random.nextInt(3); // 6 ~ 8시간

        DateTime sleepStart = DateTime(
            targetDate.year, targetDate.month, targetDate.day, startHour, startMin);
        DateTime sleepEnd = sleepStart.add(Duration(
            hours: sleepDurationHours, minutes: _random.nextInt(60)));

        print(
            '📅 생성 중: $dateString ($sessionId) - ${sleepDurationHours}시간 수면');

        DateTime currentTime = sleepStart;

        // 통계용 변수
        double totalDeep = 0;
        double totalRem = 0;
        double totalLight = 0;
        double totalWake = 0;
        int count = 0;

        // --- [루프] 분 단위 데이터 생성 ---
        while (currentTime.isBefore(sleepEnd)) {
          // 1. 단계 시뮬레이션
          String stage = _simulateSleepStage(sleepStart, sleepEnd, currentTime);

          // 2. 센서 데이터 생성
          final sensorData = _generateDataForStage(
              stage: stage,
              userId: userId,
              sessionId: sessionId,
              timestamp: currentTime);

          // 3. raw_data 저장 (Jupyter 학습용)
          final rawRef = firestore.collection('raw_data').doc();
          batch.set(rawRef, sensorData);

          // 4. processed_data 저장 (앱 그래프용) - 트리거 기다리지 않고 직접 저장!
          final processedRef = firestore.collection('processed_data').doc();
          batch.set(processedRef, {
            'userId': userId,
            'sessionId': sessionId,
            'stage': stage, // 이미 분류된 것으로 간주
            'raw_stage': stage,
            'confidence': 1.0,
            'ts': Timestamp.fromDate(currentTime),
            'changed_at': Timestamp.fromDate(currentTime), // 그래프 X축
            'source_ts': Timestamp.fromDate(currentTime),
          });

          // 통계 누적
          if (stage == 'Deep')
            totalDeep += 3;
          // 3분 간격
          else if (stage == 'REM')
            totalRem += 3;
          else if (stage == 'Light')
            totalLight += 3;
          else
            totalWake += 3;
          count++;

          // 배치 관리
          batchCount += 2; // raw + processed
          totalRawDocs++;
          if (batchCount >= 450) {
            await batch.commit();
            batch = firestore.batch();
            batchCount = 0;
          }

          currentTime = currentTime.add(const Duration(minutes: 3)); // 3분 간격
        }

        // 5. Sleep Report 직접 생성 (앱 요약 카드용) - 트리거 기다리지 않음!
        final totalDuration = totalDeep + totalRem + totalLight + totalWake; // 분 단위
        final totalHours = totalDuration / 60.0;

        // 점수 계산 (간이 로직)
        int score = 70 + _random.nextInt(25); // 70~95점
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
          'created_at': Timestamp.fromDate(sleepEnd), // 수면 끝난 시간 기준
          'summary': {
            'total_duration_hours':
                double.parse(totalHours.toStringAsFixed(1)),
            'deep_sleep_hours': double.parse((totalDeep / 60).toStringAsFixed(1)),
            'rem_sleep_hours': double.parse((totalRem / 60).toStringAsFixed(1)),
            'light_sleep_hours':
                double.parse((totalLight / 60).toStringAsFixed(1)),
            'awake_hours': double.parse((totalWake / 60).toStringAsFixed(1)),
            'apnea_count': _random.nextInt(5), // 랜덤 무호흡
            'snoring_duration': _random.nextInt(30),
            'deep_ratio': (totalDeep / totalDuration * 100).round(),
            'rem_ratio': (totalRem / totalDuration * 100).round(),
            'awake_ratio': (totalWake / totalDuration * 100).round(),
          }
        });
        batchCount++;
      }

      // 남은 배치 처리
      if (batchCount > 0) await batch.commit();

      if (context.mounted) {
        Navigator.of(context).pop(); // 다이얼로그 닫기

        // ✅ [중요] 상태 강제 업데이트 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ 7일치 데이터 ($totalRawDocs개) 생성 완료!\n앱을 재시작하거나 화면을 갱신하세요.'),
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

  // 🧹 컬렉션 삭제 헬퍼 (기존과 동일하지만 userId 필터링 확실히)
  Future<void> _clearCollection(String userId, String collection) async {
    final instance = FirebaseFirestore.instance;
    final batchSize = 400;

    // 무한 루프로 모든 데이터 삭제 보장
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
      print("Deleted ${snapshot.docs.length} docs from $collection");
      await Future.delayed(const Duration(milliseconds: 50)); // 속도 조절
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
    double hrMin,
        hrMax,
        spo2Min,
        spo2Max,
        micMin,
        micMax,
        pressureMin,
        pressureMax;

    switch (stage) {
      case 'Deep': // 깊은 잠: 심박수 최저, 움직임 거의 없음
        hrMin = 50;
        hrMax = 60; // 안정적인 낮은 심박수
        spo2Min = 97;
        spo2Max = 99; // 정상 산소포화도
        micMin = 5;
        micMax = 20; // 거의 침묵 (백색소음 수준)
        pressureMin = 800;
        pressureMax = 1200; // 머리 무게 안정적 지지
        break;

      case 'Light': // 얕은 잠: 심박수 약간 상승, 일반적인 수면 상태
        hrMin = 60;
        hrMax = 75;
        spo2Min = 96;
        spo2Max = 99;
        micMin = 20;
        micMax = 40; // 얕은 숨소리나 약한 생활 소음
        pressureMin = 800;
        pressureMax = 1300;
        break;

      case 'REM': // 렘수면: 뇌 활발, 심박수 불규칙하게 상승 (꿈)
        hrMin = 65;
        hrMax = 85; // 꿈꿀 때 심박수 오름
        spo2Min = 96;
        spo2Max = 99;
        micMin = 10;
        micMax = 30; // 근육 마비로 소리는 조용함
        pressureMin = 800;
        pressureMax = 1200;
        break;

      case 'Awake': // 깸: 심박수 급증, 머리를 뗌 (압력 0 근처)
        hrMin = 80;
        hrMax = 110; // 깨어나서 활동 시작
        spo2Min = 97;
        spo2Max = 100;
        micMin = 40;
        micMax = 100; // 말하거나 움직이는 소리
        pressureMin = 0;
        pressureMax = 100; // 💡 핵심: 머리를 들어서 압력이 사라짐
        break;

      case 'Tossing': // 뒤척임: 베개를 짓누르거나 강한 움직임
        hrMin = 70;
        hrMax = 90;
        spo2Min = 96;
        spo2Max = 99;
        micMin = 30;
        micMax = 80; // 이불 부스럭거리는 소리
        pressureMin = 3000;
        pressureMax = 4095; // 💡 핵심: 베개를 꾹 누르는 최대 압력
        break;

      case 'Snoring': // 코골이: 소리 센서 폭발
        hrMin = 60;
        hrMax = 75;
        spo2Min = 93;
        spo2Max = 96; // 호흡 곤란으로 약간 떨어질 수 있음
        micMin = 150;
        micMax = 255; // 💡 핵심: 마이크 값 최대치 (코고는 소리)
        pressureMin = 800;
        pressureMax = 1300; // 자세는 그대로
        break;

      case 'Apnea': // 수면 무호흡: 소리 없음 + 산소포화도 위험 수준
        hrMin = 75;
        hrMax = 95; // 숨 멈춰서 느려졌다가, 헐떡이며 빨라짐 (변동성)
        spo2Min = 80;
        spo2Max = 88; // 💡 핵심: 위험 수준으로 떨어짐 (저산소증)
        micMin = 0;
        micMax = 5; // 💡 핵심: 숨을 안 쉬어서 소리가 '0'에 가까움
        pressureMin = 500;
        pressureMax = 900; // 몸부림 치기 직전 정지 상태
        break;

      default:
        hrMin = 60;
        hrMax = 75;
        spo2Min = 96;
        spo2Max = 99;
        micMin = 10;
        micMax = 30;
        pressureMin = 800;
        pressureMax = 1200;
        break;
    }
    return {
      'hr': _randRange(hrMin, hrMax).toInt(),
      'spo2': _randRange(spo2Min, spo2Max).toInt(),
      'mic_avg': _randRange(micMin, micMax).toInt(),
      'pressure_avg': _randRange(pressureMin, pressureMax).toInt(),

      // 더미 데이터
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
  // 훈련 데이터 생성
  // ========================================
  // ========================================
  // 🔧 [백엔드 기능] 훈련 데이터 생성 (랜덤 개수)
  // ========================================
  Future<void> _pushBurstData(BuildContext context, String label) async {
    final String userId = "demoUser";
    final String sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";

    // 🚨 [수정] 개수를 랜덤하게! (80 ~ 150개 사이)
    // 이렇게 하면 그래프에서 막대 높이가 들쭉날쭉해서 리얼해 보임
    int count = 80 + _random.nextInt(71); 

    for (int i = 0; i < count; i++) {
      final data = _generateDataForStage(
          stage: label, 
          userId: userId, 
          sessionId: sessionId, 
          timestamp: DateTime.now()
      );
      
      data['auto_control_active'] = true;
      data['ts'] = FieldValue.serverTimestamp();

      try {
        await FirebaseFirestore.instance.collection('raw_data').add(data);
        // 속도를 위해 딜레이 최소화
        if (i % 10 == 0) await Future.delayed(const Duration(milliseconds: 10)); 
      } catch (e) {
        break;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $label 데이터 ($count개) 생성 완료'), backgroundColor: Colors.green)
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
                const SizedBox(height: 24),
                _buildPlaceholderInfoCards(), // ✅ 도넛 그래프 카드 복구
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

  // ✅ [수정됨] 수면 측정 버튼 UI (베개 모양 아이콘 적용)
  Widget _buildMeasurementButton(BuildContext context, AppState appState) {
    final bool isMeasuring = appState.isMeasuring;

    // 🎨 디자인 팔레트
    final Color colDeep = const Color(0xFF011F25);
    final Color colMoon = const Color(0xFFF2E6E6);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // (기존 측정 시작/종료 로직 - 그대로 유지)
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
          // ✨ [UI 핵심] 측정 대기 중일 때 '베개 아이콘' 표시
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: isMeasuring
                ? _buildMeasuringState(colDeep) // 측정 중 UI
                : const SleepStartJellyIcon(), // 대기 중 UI (베개 아이콘)
          ),
        ),
        const SizedBox(height: 24),

        // 하단 텍스트
        Column(
          children: [
            Text(
              isMeasuring ? "편안한 밤 되세요" : "수면 시작",
              style: AppTextStyles.heading2.copyWith(
                  color: Color(0xFF6292BE), fontSize: 22, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              isMeasuring ? "수면 데이터를 분석하고 있습니다" : "베개를 톡 눌러 꿈나라로 떠나보세요",
              style: AppTextStyles.secondaryBodyText
                  .copyWith(color: Color(0xFFBD9A8E), fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  // 측정 중일 때 보여줄 심플한 UI (파동)
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

  // ✅ 수정됨: 도넛 그래프를 사용하여 정보를 표시하는 함수
  Widget _buildPlaceholderInfoCards() {
    return Consumer<SleepDataState>(
      builder: (context, sleepDataState, child) {
        // ✅ 실제 데이터 가져오기
        final metrics = sleepDataState.todayMetrics;
        final totalHours = metrics.totalSleepDuration;
        final hours = totalHours.floor();
        final minutes = ((totalHours - hours) * 60).round();
        final centerValue = '$hours시간 $minutes분';
        
        // ✅ 목표 대비 달성률 계산 (목표: 8시간)
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
                  // 팔레트 색상: #6292BE
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

// ✨ [ART] 풍부한 입체감의 레이어드 베개 아이콘 (이미지 참고)
class SleepStartJellyIcon extends StatelessWidget {
  const SleepStartJellyIcon({super.key});

  @override
  Widget build(BuildContext context) {
    // 아이콘 크기
    const double width = 200;
    const double height = 150;

    // 팔레트
    const Color colRose = Color(0xFFBD9A8E); // 로즈 브라운
    const Color colBlue = Color(0xFF6292BE); // 블루
    const Color colMoon = Color(0xFFF2E6E6); // 달빛

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. 베개 모양 그림자 & 테두리 (Glow)
        CustomPaint(
          size: const Size(width, height),
          painter: _SoftPillowPainter(), // ✅ 이제 정의된 클래스를 사용합니다
        ),

        // 2. 베개 모양으로 내용물 자르기
        ClipPath(
          clipper: _SoftPillowClipper(), // ✅ 이제 정의된 클래스를 사용합니다
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              // 배경 그라데이션
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colBlue.withOpacity(0.4),
                  colRose.withOpacity(0.3),
                ],
              ),
            ),
            // ☁️ 내부 콘텐츠
            child: Stack(
              children: [
                // Layer 1: 뒤쪽 물결
                Positioned(
                  bottom: 40,
                  left: -20,
                  right: -20,
                  height: 80,
                  child: _buildWave(colBlue.withOpacity(0.5), 0.1),
                ),
                // Layer 2: 중간 물결
                Positioned(
                  bottom: 20,
                  left: -30,
                  right: -30,
                  height: 90,
                  child: _buildWave(colRose.withOpacity(0.6), -0.15),
                ),
                // Layer 3: 앞쪽 물결
                Positioned(
                  bottom: -10,
                  left: -20,
                  right: -20,
                  height: 100,
                  child: _buildWave(colMoon.withOpacity(0.8), 0.05),
                ),

                // 반짝이는 별
                ..._buildSparkles(),

                // 🌙 중앙 달 아이콘
                Positioned(
                  top: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Transform.rotate(
                      angle: -math.pi / 8,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: colMoon,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colRose.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(2, 4),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: -2,
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

                // 상단 유리 광택
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: height / 2,
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

  Widget _buildWave(Color color, double angle) {
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

  List<Widget> _buildSparkles() {
    final random = math.Random(42);
    final sparkles = <Widget>[];
    final positions = [
      const Offset(30, 40),
      const Offset(170, 30),
      const Offset(160, 110),
      const Offset(40, 100),
      const Offset(100, 20),
      const Offset(150, 60)
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

// 📐 [Path] 부드러운 쿠션/베개 모양 정의 (누락되었던 부분!)
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

// 🎨 [Clipper] (누락되었던 부분!)
class _SoftPillowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _getSoftPillowPath(size);
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// 🖌️ [Painter] (누락되었던 부분!)
class _SoftPillowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _getSoftPillowPath(size);

    // 1. 부드러운 그림자 (Glow)
    canvas.drawShadow(
      path,
      const Color(0xFF6292BE).withOpacity(0.3),
      15.0,
      true,
    );

    // 2. 흰색 테두리
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

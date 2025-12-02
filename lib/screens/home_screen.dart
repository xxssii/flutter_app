// lib/screens/home_screen.dart
// ✅ [수정 완료] 실시간 배터리 및 연결 상태 모니터링 UI 통합됨

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
import 'sleep_mode_screen.dart';
import '../services/ble_service.dart';
import 'hardware_test_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ✅ [수정] 가우시안 랜덤 (자연스러운 종 모양 분포)
  static final _random = Random();
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
  // ✨ [개선] 8일치 테스트 데이터 생성 (기존 데이터 삭제 + 직장인 패턴)
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
            Text('기존 데이터 삭제 후\n새로 생성 중... (약 1분)'),
          ],
        ),
      ),
    );

    try {
      final userId = 'demoUser'; // ID 통일

      // 🧹 1. 기존 데모 데이터 청소 (중복 방지)
      print("🧹 기존 데이터 삭제 시작...");
      await _clearCollection(userId, 'raw_data');
      await _clearCollection(userId, 'processed_data');
      await _clearCollection(userId, 'sleep_reports');
      await _clearCollection(userId, 'session_state');
      print("🧹 기존 데이터 삭제 완료!");

      // 🏭 2. 데이터 생성 시작
      final now = DateTime.now();
      int totalDocs = 0;

      // 7일 전 ~ 어제까지 (총 8일치)
      for (int i = 7; i >= 0; i--) {
        final targetDate = now.subtract(Duration(days: i));

        // 🏢 [직장인 패턴]
        // 취침: 23:00 ~ 00:30 랜덤
        final int startHour = 23;
        final int startMin = _random.nextInt(90);

        // 기상: 06:30 ~ 07:30 랜덤
        final int endHour = 6;
        final int endMin = 30 + _random.nextInt(60);

        DateTime sleepStart = DateTime(
                targetDate.year, targetDate.month, targetDate.day, startHour, 0)
            .add(Duration(minutes: startMin));

        DateTime sleepEnd = DateTime(
                targetDate.year, targetDate.month, targetDate.day, endHour, 0)
            .add(Duration(days: 1, minutes: endMin));

        final dateString =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        final sessionId = 'session-$dateString';

        print('📅 생성 중: $dateString ($sessionId)');

        DateTime currentTime = sleepStart;
        WriteBatch batch = FirebaseFirestore.instance.batch();
        int batchCount = 0;

        while (currentTime.isBefore(sleepEnd)) {
          // 수면 단계 시뮬레이션
          String stage = _simulateSleepStage(sleepStart, sleepEnd, currentTime);

          final data = _generateDataForStage(
            stage: stage,
            userId: userId,
            sessionId: sessionId,
            timestamp: currentTime,
          );

          final docRef =
              FirebaseFirestore.instance.collection('raw_data').doc();
          batch.set(docRef, data);
          batchCount++;
          totalDocs++;

          if (batchCount >= 400) {
            await batch.commit();
            batch = FirebaseFirestore.instance.batch();
            batchCount = 0;
          }

          // 3분 간격 (데이터 절약)
          currentTime = currentTime.add(const Duration(minutes: 3));
        }

        if (batchCount > 0) await batch.commit();
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ 초기화 및 8일치 데이터 생성 완료! ($totalDocs개)'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // 🧹 컬렉션 청소 헬퍼 함수
  Future<void> _clearCollection(String userId, String collection) async {
    var collectionRef = FirebaseFirestore.instance.collection(collection);
    var snapshots =
        await collectionRef.where('userId', isEqualTo: userId).get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 400) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
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
  // ✨ 테스트: raw_data에서 직접 수면 점수 계산
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
            Text('수면 데이터 분석 중...'),
          ],
        ),
      ),
    );

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('raw_data')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      final sortedDocs = querySnapshot.docs.toList()
        ..sort((a, b) {
          final aTime = (a['ts'] as Timestamp).toDate();
          final bTime = (b['ts'] as Timestamp).toDate();
          return aTime.compareTo(bTime);
        });

      if (sortedDocs.isEmpty) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ 데이터 없음'),
            content: Text(
                '세션 $sessionId의 데이터가 없습니다.\n\n먼저 "7일치 테스트 데이터 생성" 버튼을 눌러주세요!'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인')),
            ],
          ),
        );
        return;
      }

      print('✅ ${sortedDocs.length}개 데이터 발견!');

      final firstDoc = sortedDocs.first;
      final lastDoc = sortedDocs.last;
      final firstTime = (firstDoc['ts'] as Timestamp).toDate();
      final lastTime = (lastDoc['ts'] as Timestamp).toDate();
      final totalSeconds = lastTime.difference(firstTime).inSeconds;
      final totalHours = totalSeconds / 3600;

      Map<String, int> stageDurations = {
        'Deep': 0,
        'Light': 0,
        'REM': 0,
        'Awake': 0
      };
      int totalMinutes = 0;

      for (var doc in sortedDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final hr = (data['hr'] as num).toDouble();
        final spo2 = (data['spo2'] as num).toDouble();
        final micLevel = (data['mic_avg'] ?? data['mic_level'] ?? 0).toDouble();
        final pressureLevel =
            (data['pressure_avg'] ?? data['pressure_level'] ?? 0).toDouble();

        String stage;
        if (hr <= 59.5) {
          stage = 'Deep';
        } else if (spo2 <= 91.9) {
          stage = 'Awake';
        } else if (pressureLevel > 1493.5) {
          stage = 'Awake';
        } else if (micLevel > 109.5) {
          stage = 'Light';
        } else if (pressureLevel <= 505.0) {
          stage = 'REM';
        } else {
          stage = 'Light';
        }

        stageDurations[stage] = stageDurations[stage]! + 60;
        totalMinutes++;
      }

      final actualTotalSeconds = totalMinutes * 60;
      final deepRatio = (stageDurations['Deep']! / actualTotalSeconds * 100);
      final remRatio = (stageDurations['REM']! / actualTotalSeconds * 100);
      final awakeRatio = (stageDurations['Awake']! / actualTotalSeconds * 100);

      int durationScore = 30;
      if (totalHours >= 7 && totalHours <= 9)
        durationScore = 40;
      else if (totalHours >= 6)
        durationScore = 30;
      else
        durationScore = 20;

      int deepScore = 10;
      if (deepRatio >= 15 && deepRatio <= 25)
        deepScore = 25;
      else if (deepRatio >= 10 || deepRatio > 25) deepScore = 20;

      int remScore = 8;
      if (remRatio >= 20 && remRatio <= 25)
        remScore = 20;
      else if (remRatio >= 15)
        remScore = 15;
      else if (remRatio >= 10) remScore = 10;

      int efficiencyScore = 5;
      if (awakeRatio < 5)
        efficiencyScore = 15;
      else if (awakeRatio < 10)
        efficiencyScore = 12;
      else if (awakeRatio < 15) efficiencyScore = 8;

      final totalScore = durationScore + deepScore + remScore + efficiencyScore;

      String grade;
      String message;
      if (totalScore >= 90) {
        grade = 'S';
        message = '훌륭한 수면! 🌟';
      } else if (totalScore >= 80) {
        grade = 'A';
        message = '좋은 수면 😊';
      } else if (totalScore >= 70) {
        grade = 'B';
        message = '양호한 수면 👍';
      } else if (totalScore >= 60) {
        grade = 'C';
        message = '개선 필요 😐';
      } else {
        grade = 'D';
        message = '수면 개선 필요 ⚠️';
      }

      if (!context.mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 수면 점수 (raw_data 분석)'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('세션: $sessionId', style: const TextStyle(fontSize: 12)),
                const Divider(),
                Text('총점: $totalScore점',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Text('등급: $grade'),
                Text('평가: $message'),
                const SizedBox(height: 16),
                const Text('수면 요약:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('총 수면: ${totalHours.toStringAsFixed(2)}시간'),
                Text(
                    '깊은 수면: ${(stageDurations['Deep']! / 3600).toStringAsFixed(2)}시간 (${deepRatio.toStringAsFixed(1)}%)'),
                Text(
                    'REM 수면: ${(stageDurations['REM']! / 3600).toStringAsFixed(2)}시간 (${remRatio.toStringAsFixed(1)}%)'),
                Text(
                    '얕은 수면: ${(stageDurations['Light']! / 3600).toStringAsFixed(2)}시간'),
                Text(
                    '깨어있음: ${(stageDurations['Awake']! / 3600).toStringAsFixed(2)}시간 (${awakeRatio.toStringAsFixed(1)}%)'),
                const SizedBox(height: 16),
                Text('데이터: ${sortedDocs.length}개',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인')),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ 오류 발생: $e'), backgroundColor: Colors.red));
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
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('트리거 테스트 중...')
        ]),
      ),
    );

    try {
      final now = DateTime.now();
      final testSessionId = 'test-trigger-${now.millisecondsSinceEpoch}';

      await FirebaseFirestore.instance.collection('raw_data').add({
        'hr': 65,
        'spo2': 97.5,
        'mic_avg': 20,
        'pressure_avg': 300,
        'mic_1_avg_10s': 0,
        'pressure_1_avg_10s': 0,
        'userId': 'test_user',
        'sessionId': testSessionId,
        'ts': Timestamp.now(),
        'auto_control_active': false,
      });

      print('⏳ 5초 대기 중...');
      await Future.delayed(const Duration(seconds: 15));

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
            content: const Text('processed_data가 생성되지 않았습니다. 서버 로그를 확인하세요.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'))
            ],
          ),
        );
      } else {
        final stage = processedQuery.docs.first['stage'];
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ 트리거 작동함!'),
            content: Text('Cloud Functions 정상 작동.\n분류된 단계: $stage'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'))
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ 테스트 실패: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ========================================
  // 훈련 데이터 생성
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
          appBar: AppBar(
            toolbarHeight: 80,
            title: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘 밤은 어떨까요?',
                      style: AppTextStyles.heading2.copyWith(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('수면 측정을 시작해 주세요.',
                      style: AppTextStyles.secondaryBodyText
                          .copyWith(fontSize: 15)),
                ],
              ),
            ),
            actions: [
              Consumer<SettingsState>(
                builder: (context, settingsState, _) {
                  return IconButton(
                    icon: Icon(
                      settingsState.isDarkMode
                          ? Icons.wb_sunny_outlined
                          : Icons.mode_night_outlined,
                      color: settingsState.isDarkMode
                          ? AppColors.darkPrimaryText
                          : AppColors.primaryText,
                      size: 28,
                    ),
                    onPressed: () =>
                        settingsState.toggleDarkMode(!settingsState.isDarkMode),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _buildMeasurementButton(context, appState)),
                const SizedBox(height: 24),

                // --- 테스트 도구 섹션 ---
                Center(
                  child: Column(
                    children: [
                      Text("--- [0단계] 테스트 데이터 생성 ---",
                          style: AppTextStyles.secondaryBodyText.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _generateWeeklyTestData(context),
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('7일치 데이터 생성'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _testCalculateSleepScore(context),
                        icon: const Icon(Icons.analytics),
                        label: const Text('📊 수면 점수 분석'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _testOnNewDataTrigger(context),
                        icon: const Icon(Icons.bug_report),
                        label: const Text('🔧 트리거 테스트'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      Text("--- [1단계] 훈련 데이터 (v3) ---",
                          style: AppTextStyles.secondaryBodyText),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                              onPressed: () => _pushBurstData(context, 'Awake'),
                              child: const Text('Awake')),
                          ElevatedButton(
                              onPressed: () => _pushBurstData(context, 'Light'),
                              child: const Text('Light')),
                          ElevatedButton(
                              onPressed: () => _pushBurstData(context, 'Deep'),
                              child: const Text('Deep')),
                          ElevatedButton(
                              onPressed: () => _pushBurstData(context, 'REM'),
                              child: const Text('REM')),
                          ElevatedButton(
                              onPressed: () =>
                                  _pushBurstData(context, 'Snoring'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal),
                              child: const Text('코골이')),
                          ElevatedButton(
                              onPressed: () =>
                                  _pushBurstData(context, 'Tossing'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown),
                              child: const Text('뒤척임')),
                          ElevatedButton(
                              onPressed: () => _pushBurstData(context, 'Apnea'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('무호흡')),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text("--- [하드웨어] 제어 ---",
                          style: AppTextStyles.secondaryBodyText.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.build),
                        label: const Text("🛠️ 하드웨어 테스트"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const HardwareTestScreen())),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildRealTimeMetricsCard(context, appState),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  title: '오늘의 총 수면시간',
                  icon: Icons.access_time,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('8시간 38분',
                          style: AppTextStyles.heading1
                              .copyWith(color: AppColors.primaryNavy)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                          value: 0.9,
                          backgroundColor: AppColors.progressBackground,
                          color: AppColors.primaryNavy,
                          minHeight: 8),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // ✅ [수정됨] 실시간 BleService 상태를 구독하는 위젯 사용
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

  Widget _buildMeasurementButton(BuildContext context, AppState appState) {
    final bool isMeasuring = appState.isMeasuring;
    final buttonColor =
        isMeasuring ? AppColors.errorRed : AppColors.primaryNavy;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final bleService = Provider.of<BleService>(context, listen: false);
            if (isMeasuring) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('수면 측정 종료'),
                  content: const Text('수면 측정을 종료하시겠습니까?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('취소')),
                    TextButton(
                      onPressed: () {
                        bleService.stopDataCollection();
                        appState.toggleMeasurement(context);
                        Navigator.of(context).pop();
                      },
                      child:
                          const Text('종료', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            } else {
              if (!bleService.isPillowConnected &&
                  !bleService.isWatchConnected) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('먼저 기기를 연결해주세요!'),
                    backgroundColor: Colors.orange));
                return;
              }
              bleService.startDataCollection();
              appState.toggleMeasurement(context);
              if (appState.isMeasuring) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        const SleepModeScreen(key: Key('sleepModeScreen'))));
              }
            }
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: buttonColor.withOpacity(0.1)),
            child: isMeasuring
                ? SpinKitPulse(color: buttonColor, size: 80.0)
                : Icon(Icons.nights_stay_rounded, color: buttonColor, size: 80),
          ),
        ),
        const SizedBox(height: 16),
        Text(isMeasuring ? '수면 측정 중지' : '수면 측정 시작',
            style: AppTextStyles.heading2),
      ],
    );
  }

  Widget _buildRealTimeMetricsCard(BuildContext context, AppState appState) {
    if (!appState.isMeasuring) return const SizedBox.shrink();
    return Card(
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
                color: AppColors.errorRed),
            _buildMetricItem(
                icon: Icons.opacity,
                label: '산소포화도',
                value: appState.currentSpo2.toStringAsFixed(0),
                unit: '%',
                color: AppColors.primaryNavy),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      {required IconData icon,
      required String label,
      required String value,
      required String unit,
      required Color color}) {
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

  Widget _buildInfoCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Widget content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.primaryNavy, size: 24),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.heading3)
            ]),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 수면 요약', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('8시간 17.5분', '평균 수면', context),
                _buildSummaryItem('3.3점', '평균 코골이', context),
                _buildSummaryItem('92%', '수면 효율', context),
                _buildSummaryItem('20%', 'REM 비율', context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, BuildContext context) {
    return Column(
      children: [
        Text(value,
            style:
                AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: AppTextStyles.secondaryBodyText.copyWith(fontSize: 12)),
      ],
    );
  }

  // ==========================================
  // ✨ [추가됨] 기기 상태 카드 빌더 (BleService 연동)
  // ==========================================
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
                  style: AppTextStyles.bodyText
                      .copyWith(fontWeight: FontWeight.bold),
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
}

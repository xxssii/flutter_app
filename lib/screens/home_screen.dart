// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/app_state.dart';
import '../state/settings_state.dart';
// ✅ 올바른 임포트
import '../providers/sleep_provider.dart';
import '../models/sleep_report_model.dart';
import 'sleep_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 로드 시 최신 수면 리포트 가져오기
    final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
    // ✅ TODO: 실제 사용자의 ID나 마지막 세션 ID를 사용해야 합니다.
    // 테스트를 위해 하드코딩된 세션 ID 사용. 실제 Firestore에 존재하는 ID로 교체 필요.
    sleepProvider.fetchLatestSleepReport('your_test_session_id');
  }

  // --- [개발용] 훈련 데이터 생성 관련 변수 및 함수 ---
  static final _random = Random();
  static double _randRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  Future<void> _pushBurstData(BuildContext context, String label) async {
    final String userId = "train_user_v3"; // v3 훈련용 ID
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
        if (i < 9) await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        print("❌ 데이터 저장 실패: $e");
        break;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $label 훈련 데이터 (10건) 전송 완료'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  // -----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // ✅ Consumer2를 사용하여 AppState와 SleepProvider 모두 구독
    return Consumer2<AppState, SleepProvider>(
      builder: (context, appState, sleepProvider, child) {
        return Scaffold(
          appBar: _buildAppBar(context),
          body: _buildBody(context, appState, sleepProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 80,
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘 밤은 어떨까요?',
              style: AppTextStyles.heading2.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              '수면 측정을 시작해 주세요.',
              style: AppTextStyles.secondaryBodyText.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
      actions: [
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
                settingsState.toggleDarkMode(!settingsState.isDarkMode);
              },
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppState appState,
    SleepProvider sleepProvider,
  ) {
    // 🔥 중요 변경: 에러가 있어도 기본 화면 구조는 유지합니다.
    // 에러 처리는 _buildSummaryCard 내부로 이동했습니다.

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 측정 시작/중지 버튼 (AppState 연동)
          Center(child: _buildMeasurementButton(context, appState)),
          const SizedBox(height: 24),

          // 2. [개발용] 데이터 생성기 버튼들
          _buildDevTools(context),
          const SizedBox(height: 24),

          // 3. Firestore 실시간 상태 스트림 (측정 중에만 표시)
          _buildRealTimeStatusStream(context, appState),

          const SizedBox(height: 16),

          // 4. 최신 수면 리포트 요약 카드 (백엔드 데이터 연동)
          // ✅ sleepProvider 자체를 넘겨서 내부에서 상태를 처리하도록 합니다.
          _buildSummaryCard(context, sleepProvider),
          const SizedBox(height: 16),

          // 5. 기타 정보 카드 (현재는 하드코딩된 데이터, 추후 연동 필요)
          _buildPlaceholderInfoCards(context),
          const SizedBox(height: 24),

          // 6. 기기 상태 카드 (현재는 하드코딩된 데이터)
          _buildDeviceCards(context),
        ],
      ),
    );
  }

  // ===================== 위젯 빌드 헬퍼 함수들 =====================

  // 1. 측정 버튼
  Widget _buildMeasurementButton(BuildContext context, AppState appState) {
    final bool isMeasuring = appState.isMeasuring;
    final buttonText = isMeasuring ? '수면 측정 중지' : '수면 측정 시작';
    final descriptionText = isMeasuring
        ? '수면을 측정하고 있습니다.'
        : '버튼을 눌러 수면 측정을 시작하세요.';
    final buttonColor = isMeasuring
        ? AppColors.errorRed
        : AppColors.primaryNavy;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            appState.toggleMeasurement(context);
            if (appState.isMeasuring) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const SleepModeScreen(key: Key('sleepModeScreen')),
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

  // 2. 개발툴 위젯
  Widget _buildDevTools(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            "--- [개발용] 훈련 데이터 생성기 ---",
            style: AppTextStyles.secondaryBodyText,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (String label in [
                'Awake',
                'Light',
                'Deep',
                'REM',
                'Snoring',
                'Tossing',
                'Apnea',
              ])
                ElevatedButton(
                  onPressed: () => _pushBurstData(context, label),
                  style: ['Snoring', 'Tossing', 'Apnea'].contains(label)
                      ? ElevatedButton.styleFrom(
                          backgroundColor: label == 'Snoring'
                              ? Colors.teal
                              : label == 'Tossing'
                              ? Colors.brown
                              : Colors.red[700],
                        )
                      : null,
                  child: Text(label),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "-----------------------------------------",
            style: AppTextStyles.secondaryBodyText,
          ),
        ],
      ),
    );
  }

  // 3. 실시간 상태 스트림 빌더 (Firestore 연동)
  Widget _buildRealTimeStatusStream(BuildContext context, AppState appState) {
    if (!appState.isMeasuring) {
      return const SizedBox.shrink();
    }

    // TODO: 실제 실시간 데이터를 스트리밍할 사용자 ID로 변경해야 합니다.
    final Stream<DocumentSnapshot> sleepStatusStream = FirebaseFirestore
        .instance
        .collection('processed_data')
        .doc('test_user_v3')
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: sleepStatusStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitFadingCircle(
              color: AppColors.primaryNavy,
              size: 30.0,
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(
            '데이터 로딩 실패: ${snapshot.error}',
            style: const TextStyle(color: AppColors.errorRed),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('실시간 수면 데이터 대기 중...'));
        }

        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;

        String currentStatus =
            data['stage'] ?? '분석 중'; // 'status' -> 'stage'로 변경됨
        double heartRate = (data['heart_rate'] as num?)?.toDouble() ?? 0.0;
        double spo2 = (data['spo2'] as num?)?.toDouble() ?? 0.0;

        IconData statusIcon = _getIconForStatus(currentStatus);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, color: AppColors.primaryNavy, size: 30),
                    const SizedBox(width: 12),
                    Text(
                      '현재 수면 상태: $currentStatus',
                      style: AppTextStyles.heading3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      icon: Icons.favorite,
                      label: '심박수',
                      value: heartRate.toStringAsFixed(0),
                      unit: 'BPM',
                      color: AppColors.errorRed,
                      isAnimated: true, // ✅ 여기에 true를 추가해서 애니메이션을 켭니다!
                    ),
                    _buildMetricItem(
                      icon: Icons.opacity,
                      label: '산소포화도',
                      value: spo2.toStringAsFixed(0),
                      unit: '%',
                      color: AppColors.primaryNavy,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 4. 최신 수면 리포트 요약 카드 (백엔드 데이터 사용)
  // 🔥 중요 변경: SleepProvider를 받아서 내부에서 로딩/에러/데이터 상태를 처리합니다.
  Widget _buildSummaryCard(BuildContext context, SleepProvider sleepProvider) {
    // 1. 로딩 중일 때
    if (sleepProvider.isLoading) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: SpinKitFadingCircle(
              color: AppColors.primaryNavy,
              size: 30.0,
            ),
          ),
        ),
      );
    }

    // 2. 에러가 발생했을 때 (image_0.png 상황)
    if (sleepProvider.errorMessage != null) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              sleepProvider.errorMessage!, // 에러 메시지 표시
              style: const TextStyle(color: AppColors.errorRed),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final report = sleepProvider.latestSleepReport;

    // 3. 데이터가 없을 때 (에러는 아니지만 데이터가 없는 경우)
    if (report == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              "최근 수면 리포트가 없습니다.",
              style: AppTextStyles.secondaryBodyText,
            ),
          ),
        ),
      );
    }

    // 4. 데이터가 정상적으로 있을 때
    final summary = report.summary;
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('최근 수면 요약', style: AppTextStyles.heading3),
                Text(
                  dateFormat.format(report.createdAt.toLocal()),
                  style: AppTextStyles.smallText,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${report.totalScore}점 (${report.grade}등급)',
              style: AppTextStyles.heading2.copyWith(
                color: report.totalScore >= 80
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(report.message, style: AppTextStyles.secondaryBodyText),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  '${summary.totalDurationHours.toStringAsFixed(1)}시간',
                  '총 수면',
                  context,
                ),
                _buildSummaryItem(
                  '${summary.deepRatio.toStringAsFixed(1)}%',
                  '깊은 수면',
                  context,
                ),
                _buildSummaryItem(
                  '${summary.remRatio.toStringAsFixed(1)}%',
                  'REM 수면',
                  context,
                ),
                _buildSummaryItem('${summary.apneaCount}회', '무호흡', context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 5. 플레이스홀더 정보 카드들 (목표 수면, 베개 높이 - 추후 실제 데이터 연동 필요)
  Widget _buildPlaceholderInfoCards(BuildContext context) {
    return Column(
      children: [
        // 첫 번째 카드: 수면 시간
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildAnimatedDonutContent(
              title: '목표: 8시간',
              centerValue: '6시간 48분', // 예시 데이터
              footerLabel: '오늘의 수면 달성률',
              progress: 0.85, // 85% 달성
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 두 번째 카드: 베개 높이
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildAnimatedDonutContent(
              title: '권장: 10~12cm',
              centerValue: '12cm',
              footerLabel: '현재 높이 상태',
              progress: 0.6, // 적정 범위 내 위치 표시 (예시)
              color: AppColors.successGreen, // 상태가 좋으면 초록색으로 표시해 볼까요?
            ),
          ),
        ),
      ],
    );
  }

  // 6. 기기 상태 카드들 (플레이스홀더)
  Widget _buildDeviceCards(BuildContext context) {
    return Column(
      children: [
        _buildDeviceCard(
          context,
          deviceName: '스마트 베개 Pro',
          deviceType: '스마트 베개',
          isConnected: false,
          batteryPercentage: 87,
          version: 'v1.0.0',
        ),
        const SizedBox(height: 16),
        _buildDeviceCard(
          context,
          deviceName: '수면 팔찌 Plus',
          deviceType: '스마트 팔찌',
          isConnected: false,
          batteryPercentage: 73,
          version: 'v1.0.0',
        ),
      ],
    );
  }

  // ===================== 공통 UI 컴포넌트 함수들 =====================

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'Awake':
        return Icons.wb_sunny;
      case 'Light':
        return Icons.cloud_queue;
      case 'Deep':
        return Icons.nights_stay;
      case 'REM':
        return Icons.psychology;
      case 'Apnea':
        return Icons.warning_amber_rounded;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    bool isAnimated = false, // ✅ 파라미터 추가 (기본값 false)
  }) {
    // ✅ 애니메이션 여부에 따라 아이콘 위젯 결정
    Widget iconWidget;
    if (isAnimated && icon == Icons.favorite) {
      // 심박수이고 애니메이션이 켜져있으면 박동하는 하트 사용
      iconWidget = SpinKitPumpingHeart(
        color: color,
        size: 30.0, // 아이콘보다 약간 키워서 박동감 강조
        duration: const Duration(milliseconds: 1200), // 박동 속도 조절
      );
    } else {
      // 그 외에는 일반 정적 아이콘 사용
      iconWidget = Icon(icon, color: color, size: 28);
    }

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

  Widget _buildSummaryItem(String value, String label, BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.secondaryBodyText.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryNavy, size: 24),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBarContent({
    required String current,
    required String target,
    required double progress,
    required String startLabel,
    required String endLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              current,
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: 8),
            Text('목표: $target', style: AppTextStyles.secondaryBodyText),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.progressBackground,
          color: AppColors.primaryNavy,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(startLabel, style: AppTextStyles.secondaryBodyText),
            Text(endLabel, style: AppTextStyles.secondaryBodyText),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceCard(
    BuildContext context, {
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
}
// lib/screens/home_screen.dart 맨 하단 헬퍼 함수 영역에 추가

// ✅ 새로 추가되는 도넛 그래프 위젯 함수
Widget _buildAnimatedDonutContent({
  required String title,
  required String centerValue,
  required String footerLabel,
  required double progress, // 0.0 ~ 1.0 사이의 값
  Color color = AppColors.primaryNavy,
}) {
  return Row(
    children: [
      // 왼쪽: 텍스트 정보
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
      // 오른쪽: 애니메이션 도넛 그래프
      Expanded(
        flex: 2,
        child: Center(
          child: SizedBox(
            width: 100, // 그래프 크기
            height: 100,
            // TweenAnimationBuilder가 값이 변할 때 애니메이션을 만들어줍니다.
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(
                milliseconds: 1500,
              ), // 애니메이션 지속 시간 (1.5초)
              curve: Curves.easeOutCubic, // 자연스러운 속도 곡선
              builder: (context, value, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. 배경이 되는 회색 원
                    CircularProgressIndicator(
                      value: 1.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.progressBackground,
                      ),
                      strokeWidth: 12,
                    ),
                    // 2. 실제 진행률을 보여주는 색상 원 (애니메이션 값 적용)
                    CircularProgressIndicator(
                      value: value, // 여기에 애니메이션 값이 들어갑니다.
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round, // 끝부분을 둥글게
                    ),
                    // 3. 가운데 퍼센트 텍스트
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

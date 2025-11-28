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
import '../providers/sleep_provider.dart';
import '../models/sleep_report_model.dart';
import 'sleep_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ [테마 적용] 색상 팔레트 정의 (배경색 제외)
  final Color _mainDeepColor = const Color(0xFF011F25);
  final Color _lightSleepColor = const Color(0xFF1B4561);
  // final Color _remSleepColor = const Color(0xFF6292BE); // 현재 사용 안함
  final Color _awakeColor = const Color(0xFFBD9A8E);
  final Color _themeLightGray = const Color(0xFFB5C1D4);

  @override
  void initState() {
    super.initState();
    final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
    // TODO: 실제 사용자의 ID나 마지막 세션 ID를 사용해야 합니다.
    sleepProvider.fetchLatestSleepReport('your_test_session_id');
  }

  // --- [개발용] 훈련 데이터 생성 관련 변수 및 함수 ---
  static final _random = Random();
  static double _randRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

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
          backgroundColor: _lightSleepColor,
        ),
      );
    }
  }
  // -----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, SleepProvider>(
      builder: (context, appState, sleepProvider, child) {
        return Scaffold(
          // ✅ 배경색을 원래대로 AppColors.background로 복원
          backgroundColor: AppColors.background,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildMeasurementButton(context, appState)),
          const SizedBox(height: 24),
          _buildDevTools(context),
          const SizedBox(height: 24),
          _buildRealTimeStatusStream(context, appState),
          const SizedBox(height: 16),
          // ✅ 수정됨: context 전달 제거
          _buildSummaryCard(sleepProvider),
          const SizedBox(height: 16),
          // ✅ 수정됨: context 전달 제거
          _buildPlaceholderInfoCards(),
          const SizedBox(height: 24),
          // ✅ 수정됨: context 전달 제거
          _buildDeviceCards(),
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
    // ✅ [테마 적용] 측정 중(_awakeColor), 대기 중(_mainDeepColor)
    final buttonColor = isMeasuring ? _awakeColor : _mainDeepColor;

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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: label == 'Apnea'
                        ? _awakeColor
                        : label == 'Snoring'
                        ? _lightSleepColor
                        : _mainDeepColor,
                    foregroundColor: Colors.white,
                  ),
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

  // 3. 실시간 상태 스트림 빌더
  Widget _buildRealTimeStatusStream(BuildContext context, AppState appState) {
    if (!appState.isMeasuring) {
      return const SizedBox.shrink();
    }

    final Stream<DocumentSnapshot> sleepStatusStream = FirebaseFirestore
        .instance
        .collection('processed_data')
        .doc('test_user_v3')
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: sleepStatusStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitFadingCircle(color: _mainDeepColor, size: 30.0),
          );
        }
        if (snapshot.hasError) {
          return Text(
            '데이터 로딩 실패: ${snapshot.error}',
            style: TextStyle(color: _awakeColor),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('실시간 수면 데이터 대기 중...'));
        }

        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;

        String currentStatus = data['stage'] ?? '분석 중';
        double heartRate = (data['heart_rate'] as num?)?.toDouble() ?? 0.0;
        double spo2 = (data['spo2'] as num?)?.toDouble() ?? 0.0;

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
                    Icon(
                      _getIconForStatus(currentStatus),
                      color: _mainDeepColor,
                      size: 30,
                    ),
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
                      color: _awakeColor,
                      isAnimated: true,
                    ),
                    _buildMetricItem(
                      icon: Icons.opacity,
                      label: '산소포화도',
                      value: spo2.toStringAsFixed(0),
                      unit: '%',
                      color: _mainDeepColor,
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

  // 4. 최신 수면 리포트 요약 카드
  // ✅ 수정됨: context 매개변수 제거
  Widget _buildSummaryCard(SleepProvider sleepProvider) {
    if (sleepProvider.isLoading) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SpinKitFadingCircle(color: _mainDeepColor, size: 30.0),
          ),
        ),
      );
    }

    if (sleepProvider.errorMessage != null) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              sleepProvider.errorMessage!,
              style: TextStyle(color: _awakeColor),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final report = sleepProvider.latestSleepReport;

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

    final summary = report.summary;
    final dateFormat = DateFormat('MM/dd HH:mm');
    final scoreColor = report.totalScore >= 80 ? _mainDeepColor : _awakeColor;

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
              style: AppTextStyles.heading2.copyWith(color: scoreColor),
            ),
            const SizedBox(height: 4),
            Text(report.message, style: AppTextStyles.secondaryBodyText),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // ✅ 수정됨: context 전달 제거
                _buildSummaryItem(
                  '${summary.totalDurationHours.toStringAsFixed(1)}시간',
                  '총 수면',
                ),
                _buildSummaryItem(
                  '${summary.deepRatio.toStringAsFixed(1)}%',
                  '깊은 수면',
                ),
                _buildSummaryItem(
                  '${summary.remRatio.toStringAsFixed(1)}%',
                  'REM 수면',
                ),
                _buildSummaryItem('${summary.apneaCount}회', '무호흡'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 5. 플레이스홀더 정보 카드들
  // ✅ 수정됨: context 매개변수 제거
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
              color: _lightSleepColor,
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
              color: _lightSleepColor,
            ),
          ),
        ),
      ],
    );
  }

  // 6. 기기 상태 카드들
  // ✅ 수정됨: context 매개변수 제거
  Widget _buildDeviceCards() {
    return Column(
      children: [
        // ✅ 수정됨: context 전달 제거
        _buildDeviceCard(
          deviceName: '스마트 베개 Pro',
          deviceType: '스마트 베개',
          isConnected: false,
          batteryPercentage: 87,
          version: 'v1.0.0',
        ),
        const SizedBox(height: 16),
        // ✅ 수정됨: context 전달 제거
        _buildDeviceCard(
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
    bool isAnimated = false,
  }) {
    Widget iconWidget;
    if (isAnimated && icon == Icons.favorite) {
      iconWidget = SpinKitPumpingHeart(
        color: color,
        size: 30.0,
        duration: const Duration(milliseconds: 1200),
      );
    } else {
      iconWidget = Icon(icon, color: color, size: 28);
    }

    return Column(
      children: [
        iconWidget,
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
        Text(unit, style: AppTextStyles.smallText),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.secondaryBodyText),
      ],
    );
  }

  // ✅ 수정됨: context 매개변수 제거
  Widget _buildSummaryItem(String value, String label) {
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

  // ✅ 수정됨: required BuildContext context 매개변수 제거
  Widget _buildDeviceCard({
    required String deviceName,
    required String deviceType,
    required bool isConnected,
    required int batteryPercentage,
    required String version,
  }) {
    final batteryColor = batteryPercentage > 20
        ? _lightSleepColor
        : _awakeColor;
    final connectionColor = isConnected
        ? _lightSleepColor
        : AppColors.secondaryText;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.wifi, color: connectionColor, size: 24),
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
                      color: batteryColor,
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

  // 도넛 그래프 위젯
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
                          _themeLightGray.withOpacity(0.3),
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

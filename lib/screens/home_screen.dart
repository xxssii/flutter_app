// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/app_state.dart';
import '../state/settings_state.dart';
import 'sleep_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- "진짜 뇌" 훈련을 위한 데이터 생성 함수 (v3: "진짜" 범위 적용) ---
  static final _random = Random();
  static double _randRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  /// [label]에 해당하는 "진짜" 센서 범위의 프로필을 10초간 1Hz로 전송합니다.
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
        if (i < 9) {
          await Future.delayed(const Duration(seconds: 1));
        }
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
                  Text(
                    '오늘 밤은 어떨까요?',
                    style: AppTextStyles.heading2.copyWith(fontSize: 22),
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _buildMeasurementButton(context, appState)),
<<<<<<< HEAD
                const SizedBox(height: 24),

                // 1. 개발용 데이터 생성 버튼 (테스트를 위해 유지)
=======

                // --- 훈련용 데이터 생성 버튼 (7개) ---
                const SizedBox(height: 24),
>>>>>>> origin/master
                Center(
                  child: Column(
                    children: [
                      Text(
                        "--- [개발용] 훈련 데이터 생성기 ---",
                        style: AppTextStyles.secondaryBodyText,
                      ),
                      const SizedBox(height: 12),
<<<<<<< HEAD
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => _pushBurstData(context, 'Awake'),
                            child: const Text('Awake'),
                          ),
                          ElevatedButton(
                            onPressed: () => _pushBurstData(context, 'Light'),
                            child: const Text('Light'),
                          ),
                          ElevatedButton(
                            onPressed: () => _pushBurstData(context, 'Deep'),
                            child: const Text('Deep'),
                          ),
                          ElevatedButton(
                            onPressed: () => _pushBurstData(context, 'REM'),
                            child: const Text('REM'),
                          ),
                          ElevatedButton(
                            onPressed: () => _pushBurstData(context, 'Snoring'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                            child: const Text('Snoring'),
                          ),
                          ElevatedButton(
                            onPressed: () => _pushBurstData(context, 'Tossing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                            ),
                            child: const Text('Tossing'),
                          ),
                          ElevatedButton(
                            onPressed: () => _pushBurstData(context, 'Apnea'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                            ),
                            child: const Text('Apnea'),
                          ),
                        ],
                      ),
=======

                      // 7개 훈련용 버튼
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

>>>>>>> origin/master
                      const SizedBox(height: 12),
                      Text(
                        "-----------------------------------------",
                        style: AppTextStyles.secondaryBodyText,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

<<<<<<< HEAD
                // 2. Firestore 실시간 상태 (친구분 코드 - 우선 순위)
                _buildRealTimeStatus(context, appState),
                const SizedBox(height: 16),

                // 3. 앱 자체 상태 메트릭 (보조)
                if (appState.isMeasuring)
                  _buildRealTimeMetricsCard(context, appState),

=======
                const SizedBox(height: 24),
                _buildRealTimeMetricsCard(context, appState),
>>>>>>> origin/master
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  title: '오늘의 총 수면시간',
                  icon: Icons.access_time,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '8시간 38분',
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '목표: 8시간',
                            style: AppTextStyles.secondaryBodyText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.9,
                        backgroundColor: AppColors.progressBackground,
                        color: AppColors.primaryNavy,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('진행률', style: AppTextStyles.secondaryBodyText),
                          Text('100%', style: AppTextStyles.secondaryBodyText),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  title: '현재 베개 높이',
                  icon: Icons.height,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '12cm',
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '목표: 12cm',
                            style: AppTextStyles.secondaryBodyText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (12 - 8) / (16 - 8),
                        backgroundColor: AppColors.progressBackground,
                        color: AppColors.primaryNavy,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('8cm', style: AppTextStyles.secondaryBodyText),
                          Text('16cm', style: AppTextStyles.secondaryBodyText),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                _buildSummaryCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

<<<<<<< HEAD
  // --- 친구분 코드 (Firestore 연동) ---
  Widget _buildRealTimeStatus(BuildContext context, AppState appState) {
    if (!appState.isMeasuring) {
      return const SizedBox.shrink();
    }

    final Stream<DocumentSnapshot> sleepStatusStream = FirebaseFirestore
        .instance
        .collection('processed_data')
        .doc(DEMO_USER_ID)
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
          return Text('데이터 로딩 실패: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('수면 데이터가 없습니다.');
        }

        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;

        String currentStatus = data['status'] ?? '분석 중';
        double heartRate = (data['heart_rate'] as num?)?.toDouble() ?? 0.0;
        double spo2 = (data['spo2'] as num?)?.toDouble() ?? 0.0;
        double movement = (data['movement_score'] as num?)?.toDouble() ?? 0.0;

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
                    ),
                    _buildMetricItem(
                      icon: Icons.opacity,
                      label: '산소포화도',
                      value: spo2.toStringAsFixed(0),
                      unit: '%',
                      color: AppColors.primaryNavy,
                    ),
                    _buildMetricItem(
                      icon: Icons.motion_photos_on,
                      label: '움직임',
                      value: movement.toStringAsFixed(1),
                      unit: '스코어',
                      color: AppColors.warningOrange,
                    ),
                  ],
                ),
              ),
=======
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
>>>>>>> origin/master
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  IconData _getIconForStatus(String status) {
    switch (status) {
      case '깨어있음':
        return Icons.wb_sunny;
      case '얕은 수면':
        return Icons.cloud_queue;
      case '깊은 수면':
        return Icons.nights_stay;
      case 'REM 수면':
        return Icons.psychology;
      default:
        return Icons.help_outline;
    }
  }

  // --- 작성하신 코드 (AppState 연동 UI) ---
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
              label: '심박수 (앱)',
              value: appState.currentHeartRate.toStringAsFixed(0),
              unit: 'BPM',
              color: AppColors.errorRed,
            ),
            _buildMetricItem(
              icon: Icons.opacity,
              label: '산소포화도 (앱)',
              value: appState.currentSpo2.toStringAsFixed(0),
              unit: '%',
              color: AppColors.primaryNavy,
            ),
            _buildMetricItem(
              icon: Icons.motion_photos_on,
              label: '움직임 (앱)',
              value: appState.currentMovementScore.toStringAsFixed(1),
              unit: '스코어',
              color: AppColors.warningOrange,
            ),
          ],
        ),
      ),
    );
  }

=======
>>>>>>> origin/master
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
        SizedBox(height: 16),
        Text(buttonText, style: AppTextStyles.heading2),
        SizedBox(height: 8),
        Text(descriptionText, style: AppTextStyles.secondaryBodyText),
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
                SizedBox(width: 8),
                Text(title, style: AppTextStyles.heading3),
              ],
            ),
            SizedBox(height: 16),
            content,
          ],
        ),
      ),
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
            SizedBox(width: 12),
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
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isConnected)
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
                      SizedBox(width: 4),
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 수면 요약', style: AppTextStyles.heading3),
            SizedBox(height: 16),
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
}

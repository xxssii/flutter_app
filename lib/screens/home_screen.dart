import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore 임포트
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/app_state.dart'; // ✅ DEMO_USER_ID를 가져오기 위해 임포트
import '../state/settings_state.dart';
import 'sleep_mode_screen.dart'; // s_main_moon.dart -> sleep_mode_screen.dart

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
                    '오늘 밤은 어떨까요?', // 멘트 수정됨
                    style: AppTextStyles.heading2.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '수면 측정을 시작해 주세요.', // 멘트 수정됨
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
                const SizedBox(height: 24),

                // ✅ 1. Firestore 실시간 수면 상태 위젯 (측정 중에만 보임)
                _buildRealTimeStatus(context, appState),
                const SizedBox(height: 16),

                // 2. 고정 정보 카드 (총 수면시간, 베개 높이 등)
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
                            '8시간 38분', // (이 값은 리포트에서 가져와야 함)
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
                            '12cm', // (이 값은 BLE/Firestore에서 가져와야 함)
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
                        value: (12 - 8) / (16 - 8), // (임시 값)
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
                // ✅ 여기에서 version 값을 'v1.0.0'으로 전달
                _buildDeviceCard(
                  context,
                  deviceName: '스마트 베개 Pro',
                  deviceType: '스마트 베개',
                  isConnected:
                      false, // (이 값은 BleService.isPillowConnected와 연동 필요)
                  batteryPercentage: 87,
                  version: 'v1.0.0', // ✅ Mock 버전 직접 주입!
                ),
                const SizedBox(height: 16),
                // ✅ 여기에서 version 값을 'v1.0.0'으로 전달
                _buildDeviceCard(
                  context,
                  deviceName: '수면 팔찌 Plus',
                  deviceType: '스마트 팔찌',
                  isConnected:
                      false, // (이 값은 BleService.isWristbandConnected와 연동 필요)
                  batteryPercentage: 73,
                  version: 'v1.0.0', // ✅ Mock 버전 직접 주입!
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

  // ✅ _buildRealTimeStatus 및 _getIconForStatus 함수 (이전과 동일)
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
          ); // 로딩 인디케이터 변경
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
            ),
          ],
        );
      },
    );
  }

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
    required String version, // ✅ 이제 version 매개변수를 받습니다!
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
            // ✅ 연결 상태에 따라 배터리 및 버전 표시 여부 변경
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isConnected) // 연결되었을 때만 배터리 아이콘과 % 표시
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
                // ✅ 연결 상태에 따라 버전 또는 '미연결' 표시
                Text(
                  isConnected ? version : '미연결', // 연결되면 받은 version, 아니면 '미연결'
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

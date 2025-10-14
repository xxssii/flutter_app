// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/app_state.dart';
import '../state/settings_state.dart';
import 'sleep_mode_screen.dart';

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
                    '안녕하세요, 기본사용자님',
                    style: AppTextStyles.heading2.copyWith(fontSize: 22),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '오늘도 좋은 수면을 위해 준비되셨나요?',
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
              SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _buildMeasurementButton(context, appState)),
                SizedBox(height: 24),
                // Mock 데이터 기반 실시간 지표 카드
                _buildRealTimeMetricsCard(context, appState),
                SizedBox(height: 16),
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
                          SizedBox(width: 8),
                          Text(
                            '목표: 8시간',
                            style: AppTextStyles.secondaryBodyText,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.9,
                        backgroundColor: AppColors.progressBackground,
                        color: AppColors.primaryNavy,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      SizedBox(height: 8),
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
                SizedBox(height: 16),
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
                          SizedBox(width: 8),
                          Text(
                            '목표: 12cm',
                            style: AppTextStyles.secondaryBodyText,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (12 - 8) / (16 - 8),
                        backgroundColor: AppColors.progressBackground,
                        color: AppColors.primaryNavy,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      SizedBox(height: 8),
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
                SizedBox(height: 24),
                _buildDeviceCard(
                  context,
                  deviceName: '스마트 베개 Pro',
                  deviceType: '스마트 베개',
                  isConnected: true,
                  batteryPercentage: 87,
                  version: 'v2.1.3',
                ),
                SizedBox(height: 16),
                _buildDeviceCard(
                  context,
                  deviceName: '수면 밴드 Plus',
                  deviceType: '스마트 팔찌',
                  isConnected: true,
                  batteryPercentage: 73,
                  version: 'v1.8.2',
                ),
                SizedBox(height: 24),
                _buildSummaryCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealTimeMetricsCard(BuildContext context, AppState appState) {
    // 측정 중일 때만 실시간 데이터를 표시
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
              value: '${appState.currentHeartRate.toStringAsFixed(0)}',
              unit: 'BPM',
              color: AppColors.errorRed,
            ),
            _buildMetricItem(
              icon: Icons.opacity,
              label: '산소포화도',
              value: '${appState.currentSpo2.toStringAsFixed(0)}',
              unit: '%',
              color: AppColors.primaryNavy,
            ),
            _buildMetricItem(
              icon: Icons.motion_photos_on,
              label: '움직임',
              value: '${appState.currentMovementScore.toStringAsFixed(1)}',
              unit: '스코어',
              color: AppColors.warningOrange,
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
                      const SMainMoonScreen(key: Key('sleepModeScreen')),
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
                Text(version, style: AppTextStyles.smallText),
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

// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/settings_state.dart';
import '../widgets/alarm_setting_widget.dart'; // 알람 시간 설정을 위한 위젯
import 'profile_screen.dart'; // 프로필 관리 화면

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 임시 프로필 정보 (main.dart의 _buildCurrentProfileCard와 동일)
  final String _currentProfileName = "김코딩";
  final int _currentProfileAge = 28;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('설정', style: AppTextStyles.heading1),
                    Text(
                      '앱 환경과 개인 설정을 관리하세요.',
                      style: AppTextStyles.secondaryBodyText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildCurrentProfileCard(context), // 프로필 정보 상단 배치
            const SizedBox(height: 16),
            _buildThemeSettingsCard(context),
            const SizedBox(height: 16),
            _buildAlarmSettingsCard(context), // 알람 설정 카드
            const SizedBox(height: 16),
            _buildNotificationSettingsCard(context), // 알림 설정 카드
            const SizedBox(height: 16),
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentProfileCard(BuildContext context) {
    // SettingsScreen의 상단에 프로필 정보를 표시합니다.
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const ProfileScreen(key: Key('profileScreen')),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.person, size: 40, color: AppColors.primaryNavy),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentProfileName, style: AppTextStyles.heading1),
                    const SizedBox(height: 4),
                    Text('$_currentProfileAge세', style: AppTextStyles.bodyText),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSettingsCard(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '다크 모드',
                        style: AppTextStyles.bodyText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '편안한 시청을 위해 다크 모드를 켜거나 끕니다.',
                        style: AppTextStyles.secondaryBodyText,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settingsState.isDarkMode,
                  onChanged: (bool value) {
                    settingsState.toggleDarkMode(value);
                  },
                  activeColor: AppColors.primaryNavy,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlarmSettingsCard(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 알람 시간 설정 위젯
                const AlarmSettingWidget(),
                const Divider(),
                // 알람 상태 토글들 (스누즈는 제거됨)
                _buildToggleRow(
                  '스마트 기상',
                  '얕은 수면 단계에서 기상 알람을 울립니다.',
                  settingsState.isSmartWakeUpOn,
                  settingsState.toggleSmartWakeUp,
                ),
                _buildToggleRow(
                  '진동',
                  '알람 시 진동이 울립니다.',
                  settingsState.isVibrationOn,
                  settingsState.toggleVibration,
                ),
                _buildToggleRow(
                  '소리',
                  '알람 시 소리가 울립니다.',
                  settingsState.isSoundOn,
                  settingsState.toggleSound,
                ),
                _buildToggleRow(
                  '베개 조절',
                  '알람 시 베개 높이를 조절합니다.',
                  settingsState.isPillowAdjustOn,
                  settingsState.togglePillowAdjust,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationSettingsCard(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('알림 설정', style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                _buildToggleRow(
                  '수면 리포트 알림',
                  '매일 아침 수면 리포트를 받습니다.',
                  settingsState.isReportOn,
                  settingsState.toggleReport,
                ),
                _buildToggleRow(
                  '수면 효율 알림',
                  '수면 효율이 낮을 때 알림을 받습니다.',
                  settingsState.isEfficiencyOn,
                  settingsState.toggleEfficiency,
                ),
                _buildToggleRow(
                  '코골이 개선 알림',
                  '코골이가 심할 때 알림을 받습니다.',
                  settingsState.isSnoringOn,
                  settingsState.toggleSnoring,
                ),
                _buildToggleRow(
                  '목표 달성 알림',
                  '수면 목표를 달성했을 때 알림을 받습니다.',
                  settingsState.isGoalOn,
                  settingsState.toggleGoal,
                ),
                _buildToggleRow(
                  '가이드 알림',
                  '수면 가이드를 위한 팁을 받습니다.',
                  settingsState.isGuideOn,
                  settingsState.toggleGuide,
                ),
                _buildToggleRow(
                  '팝업 알림',
                  '베개 제어를 위한 팝업을 표시합니다.',
                  settingsState.isPopupOn,
                  settingsState.togglePopup,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      color: AppColors.primaryNavy.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryNavy, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '정보',
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '버전 정보, 이용 약관, 개인정보 처리 방침 등 앱 관련 정보를 확인하세요.',
                    style: AppTextStyles.secondaryBodyText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.secondaryBodyText),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryNavy,
          ),
        ],
      ),
    );
  }
}

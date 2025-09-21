// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/settings_state.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 임시 프로필 정보 (추후 상태관리로 대체)
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
            _buildCurrentProfileCard(context),
            const SizedBox(height: 16),
            _buildThemeSettingsCard(context),
            const SizedBox(height: 16),
            _buildNotificationSettingsCard(context),
            const SizedBox(height: 16),
            _buildAlarmSettingsCard(context),
            const SizedBox(height: 16),
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentProfileCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.person, size: 40, color: AppColors.primaryBlue),
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
                  activeColor: AppColors.primaryBlue,
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

  Widget _buildAlarmSettingsCard(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('알람 설정', style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                _buildToggleRow(
                  '알람 켜기',
                  '설정된 시간에 알람이 울립니다.',
                  settingsState.isAlarmOn,
                  settingsState.toggleAlarm,
                ),
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
                _buildToggleRow(
                  '스누즈',
                  '알람 스누즈를 활성화합니다.',
                  settingsState.isSnoozeOn,
                  settingsState.toggleSnooze,
                ),
                _buildDropdownRow(
                  '스누즈 시간',
                  settingsState.snoozeDuration,
                  ['5분', '10분', '15분', '30분'],
                  settingsState.setSnoozeDuration,
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
      color: AppColors.primaryBlue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.primaryBlue,
              size: 24,
            ),
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
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(
    String title,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: value,
            icon: const Icon(Icons.arrow_drop_down),
            underline: Container(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
          ),
        ],
      ),
    );
  }
}

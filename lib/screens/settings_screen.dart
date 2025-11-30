// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/settings_state.dart';
import '../state/profile_state.dart';
import '../widgets/alarm_setting_widget.dart';
import 'profile_screen.dart';
import 'info_screen.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileState>(
      builder: (context, profileState, child) {
        final activeProfile = profileState.activeProfile;

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
                _buildCurrentProfileCard(
                  context,
                  activeProfile.name,
                  activeProfile.age,
                ),
                const SizedBox(height: 16),
                _buildThemeSettingsCard(context),
                const SizedBox(height: 16),
                _buildAlarmSettingsCard(context),
                const SizedBox(height: 16),
                // 푸시 알림 설정 카드로 이름 변경
                _buildNotificationSettingsCard(context),
                const SizedBox(height: 16),
                _buildInfoCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentProfileCard(BuildContext context, String name, int age) {
    // ... (기존 코드와 동일)
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.person, size: 40, color: Color(0xFF011F25)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.heading1),
                    const SizedBox(height: 4),
                    Text('$age세', style: AppTextStyles.bodyText),
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
    // ... (기존 코드와 동일)
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
                  activeThumbColor: const Color(0xFF011F25),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlarmSettingsCard(BuildContext context) {
    // ... (기존 코드와 동일)
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AlarmSettingWidget(),
                if (settingsState.isAlarmOn)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      _buildToggleRow(
                        '스마트 기상',
                        '설정 시간 부근 얕은 수면 시 자연스럽게 깨워줍니다.',
                        settingsState.isSmartWakeUpOn,
                        settingsState.toggleSmartWakeUp,
                      ),
                      if (settingsState.isSmartWakeUpOn)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                          child: Column(
                            children: [
                              _buildToggleRow(
                                '스마트 진동',
                                '얕은 수면 시 진동으로 깨워줍니다.',
                                settingsState.isSmartVibrationOn,
                                settingsState.toggleSmartVibration,
                              ),
                              _buildToggleRow(
                                '스마트 베개 조절',
                                '얕은 수면 시 베개 높이를 조절하여 부드럽게 깨워줍니다.',
                                settingsState.isSmartPillowAdjustOn,
                                settingsState.toggleSmartPillowAdjust,
                              ),
                            ],
                          ),
                        ),
                      const Divider(),
                      _buildToggleRow(
                        '정확한 시간 알람(기본 진동)',
                        '수면 단계와 관계없이 설정된 시간에 진동이 울립니다.',
                        settingsState.isExactTimeAlarmOn,
                        settingsState.toggleExactTimeAlarm,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ 푸시 알림 설정 카드 수정
  Widget _buildNotificationSettingsCard(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ 제목 변경
                Text('푸시 알림 설정', style: AppTextStyles.heading3),
                // ✅ 설명 추가
                const SizedBox(height: 4),
                Text(
                  '중요한 정보를 푸시 알림으로 받아볼 수 있습니다.',
                  style: AppTextStyles.secondaryBodyText,
                ),
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
                  '가이드 알림',
                  '수면 가이드를 위한 팁을 받습니다.',
                  settingsState.isGuideOn,
                  settingsState.toggleGuide,
                ),

                if (settingsState.isGuideOn)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        NotificationService.instance.showTestNotification();
                      },
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      label: const Text('지금 테스트 알림 받기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF011F25).withOpacity(0.1),
                        foregroundColor: const Color(0xFF011F25),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    // ... (기존 코드와 동일)
    return Card(
      color: const Color(0xFF011F25).withOpacity(0.05),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InfoScreen(key: Key('infoScreen')),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
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
                      '앱 개발 정보 및 제작자 정보를 확인합니다.',
                      style: AppTextStyles.secondaryBodyText,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
            ],
          ),
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
    // ... (기존 코드와 동일)
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
            activeThumbColor: const Color(0xFF011F25),
          ),
        ],
      ),
    );
  }
}

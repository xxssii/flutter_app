// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/settings_state.dart';
import '../state/profile_state.dart'; // ★ 추가: ProfileState 임포트
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
    // ★ 수정: 전체를 Consumer<ProfileState>로 감싸서 프로필 변경 시 리빌드
    return Consumer<ProfileState>(
      builder: (context, profileState, child) {
        // 현재 활성 프로필 정보 가져오기
        final activeProfile = profileState.activeProfile;

        return Scaffold(
          // ✅ 배경색 변경 없음 (기본 배경 사용)
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
                // ★ 수정: 현재 활성 프로필 정보를 전달
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

  // ★ 수정: 프로필 이름과 나이를 인자로 받음
  Widget _buildCurrentProfileCard(BuildContext context, String name, int age) {
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
              const Icon(Icons.person, size: 40, color: AppColors.primaryNavy),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ★ 수정: 인자로 받은 이름과 나이 표시
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
                  activeThumbColor: AppColors.primaryNavy,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅--- 알람 설정 카드 전체 수정---
  Widget _buildAlarmSettingsCard(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 알람 시간 설정 위젯(시간+ 메인 토글)
                const AlarmSettingWidget(),

                // ✅--- 이 부분이 핵심---
                // 메인 알람(_isAlarmOn)이 켜져 있을 때만
                // 하위 옵션들을 보여줍니다.
                if (settingsState.isAlarmOn)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),

                      // 2. 스마트 기상 마스터 토글
                      _buildToggleRow(
                        '스마트 기상',
                        '설정 시간 부근 얕은 수면 시 자연스럽게 깨워줍니다.',
                        settingsState.isSmartWakeUpOn,
                        settingsState.toggleSmartWakeUp,
                      ),

                      // 3. 스마트 기상이 켜져 있을 때만 하위 옵션 표시
                      if (settingsState.isSmartWakeUpOn)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            top: 8.0,
                          ), // 들여쓰기
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

                      // 4. "정확한 시간 알람" 옵션
                      _buildToggleRow(
                        '정확한 시간 알람(기본 진동)',
                        '수면 단계와 관계없이 설정된 시간에 진동이 울립니다.',
                        settingsState.isExactTimeAlarmOn,
                        settingsState.toggleExactTimeAlarm,
                      ),
                    ], // (if settingsState.isAlarmOn) Column
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
                  '가이드 알림',
                  '수면 가이드를 위한 팁을 받습니다.',
                  settingsState.isGuideOn,
                  settingsState.toggleGuide,
                ),

                // '지금 테스트 알림 받기' 버튼
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
                        backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                        foregroundColor: AppColors.primaryNavy,
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
    return Card(
      color: AppColors.primaryNavy.withOpacity(0.05),
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
                color: AppColors.primaryNavy,
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
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅--- _buildToggleRow 수정---
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
            // 래퍼를 제거하고 함수를 직접 전달합니다.
            // Switch의onChanged는Future<void>를 반환하는 함수를 처리할 수 있습니다.
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryNavy,
          ),
        ],
      ),
    );
  }
}

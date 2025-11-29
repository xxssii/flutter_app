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
  // ✅ [테마 적용] 색상 팔레트 정의
  // 요청하신 0xFF011F25 색상을 메인 강조 색상으로 사용합니다.
  final Color _mainDeepColor = const Color(0xFF011F25);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileState>(
      builder: (context, profileState, child) {
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
              // ✅ [테마 적용] 아이콘 색상 변경
              Icon(Icons.person, size: 40, color: _mainDeepColor),
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
              // ✅ [테마 적용] 화살표 아이콘 색상 변경
              Icon(Icons.arrow_forward_ios, size: 16, color: _mainDeepColor),
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
                  // ✅ [테마 적용] 스위치 활성 색상 변경
                  activeThumbColor: _mainDeepColor,
                  activeTrackColor: _mainDeepColor.withOpacity(0.5),
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

  // ✅ 수정된 알림 설정 카드
  Widget _buildNotificationSettingsCard(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔔 직관적인 제목으로 변경
                Text('푸시 알림 설정', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Text(
                  '중요한 수면 정보를 푸시 알림으로 받아보세요.',
                  style: AppTextStyles.secondaryBodyText,
                ),
                const SizedBox(height: 16),
                _buildToggleRow(
                  '수면 리포트 알림',
                  '매일 아침 수면 리포트가 도착하면 알림을 받습니다.',
                  settingsState.isReportOn,
                  settingsState.toggleReport,
                ),
                _buildToggleRow(
                  '수면 효율 알림',
                  '수면 효율이 낮을 때 개선 팁 알림을 받습니다.',
                  settingsState.isEfficiencyOn,
                  settingsState.toggleEfficiency,
                ),
                _buildToggleRow(
                  '코골이 개선 알림',
                  '코골이가 심할 때 주의 알림을 받습니다.',
                  settingsState.isSnoringOn,
                  settingsState.toggleSnoring,
                ),
                _buildToggleRow(
                  '가이드 알림',
                  '숙면을 위한 유용한 팁 알림을 받습니다.',
                  settingsState.isGuideOn,
                  settingsState.toggleGuide,
                ),

                // 🔔 테스트 알림 버튼 추가
                if (settingsState.isGuideOn) // 가이드 알림이 켜져있을 때만 테스트 버튼 표시
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 🔔 테스트 알림 발송 (시연용)
                        NotificationService.instance.showTestNotification();
                      },
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      label: const Text('지금 테스트 알림 받기'),
                      style: ElevatedButton.styleFrom(
                        // ✅ [테마 적용] 버튼 배경 및 텍스트 색상 변경
                        backgroundColor: _mainDeepColor.withOpacity(0.1),
                        foregroundColor: _mainDeepColor,
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
      // ✅ [테마 적용] 카드 배경색 변경
      color: _mainDeepColor.withOpacity(0.05),
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
              // ✅ [테마 적용] 아이콘 색상 변경
              Icon(Icons.info_outline, color: _mainDeepColor, size: 24),
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
              // ✅ [테마 적용] 화살표 아이콘 색상 변경
              Icon(Icons.arrow_forward_ios, size: 16, color: _mainDeepColor),
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
            // ✅ [테마 적용] 스위치 활성 색상 변경
            activeThumbColor: _mainDeepColor,
            activeTrackColor: _mainDeepColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

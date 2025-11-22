// lib/screens/pillow_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/settings_state.dart';
import '../services/ble_service.dart'; // ✅ BleService 임포트

class PillowScreen extends StatefulWidget {
  const PillowScreen({Key? key}) : super(key: key);

  @override
  _PillowScreenState createState() => _PillowScreenState();
}

class _PillowScreenState extends State<PillowScreen> {
  // 베개 높이 상태를 관리할 변수
  double _currentPillowHeight = 12.0;
  double _targetPillowHeight = 12.0;

  // 자동 조절 속도
  String _adjustmentSpeed = '보통';
  // REM 수면과 깊은 수면의 목표 높이
  double _remPillowHeight = 11.0;
  double _deepPillowHeight = 12.0;

  @override
  Widget build(BuildContext context) {
    // ✅ BleService와 SettingsState를 동시에 사용하기 위해 Consumer2로 변경
    return Consumer2<BleService, SettingsState>(
      builder: (context, bleService, settingsState, child) {
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
                        Text(
                          '베개 및 팔찌 제어',
                          style: AppTextStyles.heading1,
                        ), // ✅ 타이틀 수정
                        Text(
                          '스마트 기기를 연결하고 설정을 관리하세요', // ✅ 설명 수정
                          style: AppTextStyles.secondaryBodyText,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ 1. 새로운 BLE 연결 상태 카드
                _buildConnectionStatusCard(context, bleService),

                const SizedBox(height: 16),
                _buildHeightSettingsCard(context),
                const SizedBox(height: 16),
                _buildAutoAdjustmentCard(
                  context,
                  settingsState,
                ), // ✅ SettingsState 전달
                const SizedBox(height: 16),
                _buildSleepModeSettings(context),
                const SizedBox(height: 16),
                _buildGuideCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ 2. BLE 연결 상태 및 스캔 버튼 위젯 (대대적 수정)
  Widget _buildConnectionStatusCard(
    BuildContext context,
    BleService bleService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기기 연결 관리', style: AppTextStyles.heading3),
            const SizedBox(height: 12),

            // 베개 상태
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      color: bleService.isPillowConnected
                          ? AppColors.successGreen
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text('스마트 베개', style: AppTextStyles.bodyText),
                  ],
                ),
                Text(
                  bleService.pillowConnectionStatus,
                  style: AppTextStyles.bodyText.copyWith(
                    color: bleService.isPillowConnected
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 워치 상태
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.watch_outlined,
                      color: bleService.isWatchConnected
                          ? AppColors.successGreen
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text('스마트 팔찌', style: AppTextStyles.bodyText),
                  ],
                ),
                Text(
                  bleService.watchConnectionStatus,
                  style: AppTextStyles.bodyText.copyWith(
                    color: bleService.isWatchConnected
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 스캔 버튼
            Center(
              child: ElevatedButton.icon(
                onPressed:
                    (bleService.isPillowConnected &&
                        bleService.isWatchConnected)
                    ? null // 두 장치가 모두 연결되면 비활성화
                    : () => bleService.startScan(), // 버튼 클릭 시 스캔 시작
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('기기 스캔하기'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- (이하 위젯들은 기존과 동일, _buildAutoAdjustmentCard만 수정) ---

  Widget _buildHeightSettingsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('높이 설정', style: AppTextStyles.heading3),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeightDisplay('현재 높이', _currentPillowHeight),
                _buildHeightDisplay('목표 높이', _targetPillowHeight),
              ],
            ),
            const SizedBox(height: 20),
            _buildHeightSlider(),
            const SizedBox(height: 16),
            _buildHeightControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightDisplay(String label, double value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.secondaryBodyText),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)}cm',
          style: AppTextStyles.heading1.copyWith(color: AppColors.primaryNavy),
        ),
      ],
    );
  }

  Widget _buildHeightSlider() {
    return Column(
      children: [
        Slider(
          value: _targetPillowHeight,
          min: 8.0,
          max: 16.0,
          divisions: 8,
          activeColor: AppColors.primaryNavy,
          onChanged: (double newValue) {
            setState(() {
              _targetPillowHeight = newValue;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('8cm', style: AppTextStyles.smallText),
            Text('16cm', style: AppTextStyles.smallText),
          ],
        ),
      ],
    );
  }

  Widget _buildHeightControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _targetPillowHeight = (_targetPillowHeight - 1).clamp(
                  8.0,
                  16.0,
                );
              });
            },
            child: const Text('↓ 1cm 내리기'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _targetPillowHeight = (_targetPillowHeight + 1).clamp(
                  8.0,
                  16.0,
                );
              });
            },
            child: const Text('↑ 1cm 올리기'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _targetPillowHeight = 12.0; // 최적 높이(예시)
              });
            },
            child: const Text('◎ 최적 높이'),
          ),
        ),
      ],
    );
  }

  // ✅ '조절 속도' 드롭다운이 제거된 카드
  Widget _buildAutoAdjustmentCard(
    BuildContext context,
    SettingsState settingsState,
  ) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: AppColors.primaryNavy, size: 24),
                    const SizedBox(width: 8),
                    Text('자동 조절 설정', style: AppTextStyles.heading3),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '수면 시 높이 자동 조절 활성화',
                            style: AppTextStyles.bodyText,
                          ),
                          Text(
                            '수면 단계에 따라 자동으로 베개 높이를 조절합니다.',
                            style: AppTextStyles.secondaryBodyText,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settingsState.isAutoAdjustOn,
                      onChanged: (bool value) {
                        settingsState.toggleAutoAdjust(value);
                      },
                      activeColor: AppColors.primaryNavy,
                    ),
                  ],
                ),
                // ❌ '조절 속도' Row가 여기서 삭제됨
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ '목표 높이' 슬라이더가 제거된 카드
  Widget _buildSleepModeSettings(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REM 수면 단계',
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '꿈을 꾸는 단계에서 베개를 약간 낮춤', // ✅ 설명 유지
                    style: AppTextStyles.secondaryBodyText,
                  ),
                  // ❌ 목표 높이 슬라이더 삭제
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '깊은 수면 단계',
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '깊은 잠에서 최적의 높이 유지', // ✅ 설명 유지
                    style: AppTextStyles.secondaryBodyText,
                  ),
                  // ❌ 목표 높이 슬라이더 삭제
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard(BuildContext context) {
    return Card(
      color: AppColors.primaryNavy.withOpacity(0.05),
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
                    '스마트 조절 안내',
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '자동 조절이 활성화되면 수면 단계를 감지하여 최적의 높이로 조절합니다. 조절 중에도 잠이 깨지 않도록 매우 부드럽게 움직입니다.',
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
}

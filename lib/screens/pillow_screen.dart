// lib/screens/pillow_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/settings_state.dart';

class PillowScreen extends StatefulWidget {
  const PillowScreen({Key? key}) : super(key: key);

  @override
  _PillowScreenState createState() => _PillowScreenState();
}

class _PillowScreenState extends State<PillowScreen> {
  // 베개 높이 상태를 관리할 변수
  double _currentPillowHeight = 12.0;
  double _targetPillowHeight = 12.0;

  // 추가된 변수: 자동 조절 속도
  String _adjustmentSpeed = '보통';
  // 추가된 변수: REM 수면과 깊은 수면의 목표 높이
  double _remPillowHeight = 11.0;
  double _deepPillowHeight = 12.0;

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
                    Text('베개 제어', style: AppTextStyles.heading1),
                    Text(
                      '스마트 베개의 높이를 조절하고 설정을 관리하세요',
                      style: AppTextStyles.secondaryBodyText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDeviceStatusCard(context),
            const SizedBox(height: 16),
            _buildHeightSettingsCard(context),
            const SizedBox(height: 16),
            _buildAutoAdjustmentCard(context),
            const SizedBox(height: 16),
            _buildSleepModeSettings(context),
            const SizedBox(height: 16),
            _buildGuideCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatusCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(
              Icons.bed_outlined,
              color: AppColors.primaryNavy,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '스마트 베개',
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('연결됨: 제어 가능', style: AppTextStyles.secondaryBodyText),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildAutoAdjustmentCard(BuildContext context) {
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
                    const Icon(
                      Icons.bolt,
                      color: AppColors.primaryNavy,
                      size: 24,
                    ),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('조절 속도', style: AppTextStyles.bodyText),
                    DropdownButton<String>(
                      value: _adjustmentSpeed,
                      icon: const Icon(Icons.arrow_drop_down),
                      underline: Container(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _adjustmentSpeed = newValue!;
                        });
                      },
                      items: <String>['느리게', '보통', '빠르게']
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
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
                    '꿈을 꾸는 단계에서 베개를 약간 낮춤',
                    style: AppTextStyles.secondaryBodyText,
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _remPillowHeight,
                    min: 8.0,
                    max: 16.0,
                    divisions: 8,
                    activeColor: AppColors.primaryNavy,
                    onChanged: (double newValue) {
                      setState(() {
                        _remPillowHeight = newValue;
                      });
                    },
                  ),
                  Text(
                    '목표 높이: ${_remPillowHeight.toStringAsFixed(0)}cm',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.primaryNavy,
                    ),
                  ),
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
                    '깊은 잠에서 최적의 높이 유지',
                    style: AppTextStyles.secondaryBodyText,
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _deepPillowHeight,
                    min: 8.0,
                    max: 16.0,
                    divisions: 8,
                    activeColor: AppColors.primaryNavy,
                    onChanged: (double newValue) {
                      setState(() {
                        _deepPillowHeight = newValue;
                      });
                    },
                  ),
                  Text(
                    '목표 높이: ${_deepPillowHeight.toStringAsFixed(0)}cm',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.primaryNavy,
                    ),
                  ),
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
                    '자동 조절이 활성화되면 수면 단계를 감지하여 최적의 높이로 조절합니다. 조절 중에도 베개가 되지 않도록 매우 부드럽게 움직입니다.',
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

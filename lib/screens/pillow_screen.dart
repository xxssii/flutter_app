// lib/screens/pillow_screen.dart
// lib/screens/pillow_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/settings_state.dart';
import '../services/ble_service.dart';

class PillowScreen extends StatefulWidget {
  const PillowScreen({super.key});

  @override
  _PillowScreenState createState() => _PillowScreenState();
}

class _PillowScreenState extends State<PillowScreen> {
  final double _currentPillowHeight = 12.0;
  double _targetPillowHeight = 12.0;
  String _adjustmentSpeed = '보통';
  double _remPillowHeight = 11.0;
  double _deepPillowHeight = 12.0;

  // ✅ 개선된 권한 요청 함수 (위치 권한 선택사항)
  Future<bool> _requestPermissions() async {
    print("\n" + "=" * 50);
    print("📱 권한 요청 시작...");
    print("=" * 50);

    // ✅ 필수 권한만 체크
    PermissionStatus bluetoothScan = await Permission.bluetoothScan.request();
    PermissionStatus bluetoothConnect =
        await Permission.bluetoothConnect.request();

    // ✅ 위치는 선택사항으로 (Android 12 미만에서만 필요)
    PermissionStatus location = await Permission.location.request();

    print("\n📋 권한 상태:");
    print("   🔵 bluetoothScan: $bluetoothScan");
    print("   🔵 bluetoothConnect: $bluetoothConnect");
    print("   📍 location: $location (선택사항)");
    print("");

    // ✅ 필수 권한만 확인 (위치는 제외)
    List<String> deniedPermissions = [];

    if (!bluetoothScan.isGranted) {
      deniedPermissions.add("블루투스 스캔");
      print("   ❌ 블루투스 스캔 권한 거부됨");
    }
    if (!bluetoothConnect.isGranted) {
      deniedPermissions.add("블루투스 연결");
      print("   ❌ 블루투스 연결 권한 거부됨");
    }

    // ✅ 위치 권한은 경고만 출력
    if (!location.isGranted) {
      print("   ⚠️ 위치 권한 거부됨 (선택사항, Android 12+ 에서는 불필요)");
    }

    if (deniedPermissions.isNotEmpty) {
      print("\n💥 거부된 필수 권한: ${deniedPermissions.join(', ')}");
      print("=" * 50 + "\n");

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('권한이 필요합니다'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '다음 필수 권한이 거부되었습니다:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...deniedPermissions
                    .map((perm) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.close,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Text(perm),
                            ],
                          ),
                        ))
                    .toList(),
                const SizedBox(height: 16),
                const Text(
                  '앱 설정에서 권한을 허용해주세요.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('설정 열기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }

      return false;
    }

    // ✅ 필수 권한(bluetoothScan, bluetoothConnect)만 허용되면 OK!
    print("✅ 필수 권한 허용됨! 스캔 가능!");
    if (!location.isGranted) {
      print("ℹ️ 위치 권한은 없지만 Android 12+ 에서는 문제없습니다.");
    }
    print("=" * 50 + "\n");
    return true;
  }

  @override
  Widget build(BuildContext context) {
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
                        Text('베개 및 팔찌 제어', style: AppTextStyles.heading1),
                        Text('스마트 기기를 연결하고 설정을 관리하세요',
                            style: AppTextStyles.secondaryBodyText),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildConnectionStatusCard(context, bleService),
                const SizedBox(height: 16),
                _buildHeightSettingsCard(context, bleService),
                const SizedBox(height: 16),
                _buildAutoAdjustmentCard(context, settingsState),
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
                Flexible(
                  child: Text(
                    bleService.pillowConnectionStatus,
                    style: AppTextStyles.bodyText.copyWith(
                      color: bleService.isPillowConnected
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 팔찌 상태
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
                Flexible(
                  child: Text(
                    bleService.watchConnectionStatus,
                    style: AppTextStyles.bodyText.copyWith(
                      color: bleService.isWatchConnected
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // ✅ 스캔 버튼
            Center(
              child: ElevatedButton.icon(
                onPressed: (bleService.isPillowConnected &&
                        bleService.isWatchConnected)
                    ? null
                    : () async {
                        print("\n🔵 [사용자 액션] 스캔 버튼 클릭됨");

                        bool hasPermission = await _requestPermissions();

                        if (hasPermission) {
                          print("✅ 권한 확인 완료. 스캔 시작...\n");
                          await bleService.startScan();
                        } else {
                          print("❌ 권한 없음. 스캔 취소.\n");
                        }
                      },
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('기기 스캔하기'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('권한 수동 설정', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... 나머지 위젯들은 이전과 동일 ...

  Widget _buildHeightSettingsCard(BuildContext context, BleService bleService) {
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
            _buildHeightControlButtons(bleService),
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

  Widget _buildHeightControlButtons(BleService bleService) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: bleService.isPillowConnected
                ? () {
                    setState(() {
                      _targetPillowHeight =
                          (_targetPillowHeight - 1).clamp(8.0, 16.0);
                    });
                    bleService.adjustHeight(4);
                  }
                : null,
            child: const Text('↓ 1cm 내리기'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: bleService.isPillowConnected
                ? () {
                    setState(() {
                      _targetPillowHeight =
                          (_targetPillowHeight + 1).clamp(8.0, 16.0);
                    });
                    bleService.adjustHeight(1);
                  }
                : null,
            child: const Text('↑ 1cm 올리기'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: bleService.isPillowConnected
                ? () {
                    setState(() {
                      _targetPillowHeight = 12.0;
                    });
                    bleService.adjustHeight(2);
                  }
                : null,
            child: const Text('◎ 최적 높이'),
          ),
        ),
      ],
    );
  }

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
                          Text('수면 시 높이 자동 조절 활성화',
                              style: AppTextStyles.bodyText),
                          Text('수면 단계에 따라 자동으로 베개 높이를 조절합니다.',
                              style: AppTextStyles.secondaryBodyText),
                        ],
                      ),
                    ),
                    Switch(
                      value: settingsState.isAutoAdjustOn,
                      onChanged: (bool value) {
                        settingsState.toggleAutoAdjust(value);
                      },
                      activeThumbColor: AppColors.primaryNavy,
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
                  Text('REM 수면 단계',
                      style: AppTextStyles.bodyText
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('꿈을 꾸는 단계에서 베개를 약간 낮춤',
                      style: AppTextStyles.secondaryBodyText),
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
                  Text('깊은 수면 단계',
                      style: AppTextStyles.bodyText
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('깊은 잠에서 최적의 높이 유지',
                      style: AppTextStyles.secondaryBodyText),
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
            const Icon(Icons.info_outline,
                color: AppColors.primaryNavy, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('스마트 조절 안내',
                      style: AppTextStyles.bodyText
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      '자동 조절이 활성화되면 수면 단계를 감지하여 최적의 높이로 조절합니다. 조절 중에도 잠이 깨지 않도록 매우 부드럽게 움직입니다.',
                      style: AppTextStyles.secondaryBodyText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

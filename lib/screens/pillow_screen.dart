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
  // ✅ [테마 적용] 색상 팔레트 정의
  final Color _mainDeepColor = const Color(0xFF011F25);
  final Color _lightSleepColor = const Color(0xFF1B4561);
  final Color _remSleepColor = const Color(0xFF6292BE);
  final Color _awakeColor = const Color(0xFFBD9A8E);
  final Color _themeLightGray = const Color(0xFFB5C1D4);

  // ✅ 통합된 베개 높이 단계 (1: 낮음, 2: 보통, 3: 높음)
  int _pillowHeightStage = 2; // 기본값: 보통

  // 각 단계별 텍스트 및 대략적인 높이 (예시)
  final Map<int, String> _stageTextMap = {
    1: '낮음 (약 10cm)',
    2: '보통 (약 12cm)',
    3: '높음 (약 14cm)',
  };

  // ... (권한 요청 함수 _requestPermissions는 그대로 유지) ...
  Future<bool> _requestPermissions() async {
    // (기존 코드와 동일)
    print("\n" + "=" * 50);
    print("📱 권한 요청 시작...");
    print("=" * 50);

    PermissionStatus bluetoothScan = await Permission.bluetoothScan.request();
    PermissionStatus bluetoothConnect = await Permission.bluetoothConnect
        .request();
    PermissionStatus location = await Permission.location.request();

    print("\n📋 권한 상태:");
    print("   🔵 bluetoothScan: $bluetoothScan");
    print("   🔵 bluetoothConnect: $bluetoothConnect");
    print("   📍 location: $location (선택사항)");
    print("");

    List<String> deniedPermissions = [];
    if (!bluetoothScan.isGranted) deniedPermissions.add("블루투스 스캔");
    if (!bluetoothConnect.isGranted) deniedPermissions.add("블루투스 연결");

    if (deniedPermissions.isNotEmpty) {
      print("\n💥 거부된 필수 권한: ${deniedPermissions.join(', ')}");
      print("=" * 50 + "\n");
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('권한이 필요합니다'),
            content: Text('필수 권한이 거부되었습니다.\n설정에서 권한을 허용해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('설정 열기'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    print("✅ 필수 권한 허용됨! 스캔 가능!");
    print("=" * 50 + "\n");
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BleService, SettingsState>(
      builder: (context, bleService, settingsState, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
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
                        Text(
                          '스마트 기기를 연결하고 설정을 관리하세요',
                          style: AppTextStyles.secondaryBodyText,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildConnectionStatusCard(context, bleService),
                const SizedBox(height: 16),
                // ✅ 수정된 높이 조절 카드
                _buildPillowHeightControlCard(context, bleService),
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

  // ... (_buildConnectionStatusCard는 그대로 유지) ...
  Widget _buildConnectionStatusCard(
    BuildContext context,
    BleService bleService,
  ) {
    // (기존 코드와 동일)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기기 연결 관리', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
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
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (bleService.isPillowConnected ||
                      bleService.isWatchConnected) {
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('연결 해제'),
                        content: const Text('모든 기기의 연결을 해제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              '해제',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await bleService.disconnectAll();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('기기 연결이 해제되었습니다'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    }
                  } else {
                    bool hasPermission = await _requestPermissions();
                    if (hasPermission) {
                      await bleService.startScan();
                    }
                  }
                },
                icon: Icon(
                  (bleService.isPillowConnected || bleService.isWatchConnected)
                      ? Icons.link_off
                      : Icons.bluetooth_searching,
                ),
                label: Text(
                  (bleService.isPillowConnected || bleService.isWatchConnected)
                      ? '스캔 종료 (연결 해제)'
                      : '기기 스캔하기',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  backgroundColor:
                      (bleService.isPillowConnected ||
                          bleService.isWatchConnected)
                      ? Colors.red
                      : _mainDeepColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('권한 수동 설정', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: _mainDeepColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ [새로운 함수] 통합된 베개 높이 조절 카드
  Widget _buildPillowHeightControlCard(
    BuildContext context,
    BleService bleService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 제목 변경
            Text('베개 높이 조절', style: AppTextStyles.heading3),
            const SizedBox(height: 20),

            // 현재 단계 표시 및 조절 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 낮추기 버튼
                ElevatedButton(
                  onPressed:
                      bleService.isPillowConnected && _pillowHeightStage > 1
                      ? () {
                          setState(() => _pillowHeightStage--);
                          _showHeightChangeSnackBar(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lightSleepColor,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.remove, size: 28),
                ),

                // 현재 단계 및 텍스트 표시
                Column(
                  children: [
                    Text(
                      '$_pillowHeightStage단계',
                      style: AppTextStyles.heading1.copyWith(
                        color: _mainDeepColor,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stageTextMap[_pillowHeightStage] ?? '',
                      style: AppTextStyles.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // 높이기 버튼
                ElevatedButton(
                  onPressed:
                      bleService.isPillowConnected && _pillowHeightStage < 3
                      ? () {
                          setState(() => _pillowHeightStage++);
                          _showHeightChangeSnackBar(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mainDeepColor,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 설명 텍스트
            Center(
              child: Text(
                '베개를 연결하면 높이를 조절할 수 있습니다.',
                style: AppTextStyles.secondaryBodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 높이 변경 시 스낵바 표시 도우미 함수
  void _showHeightChangeSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '베개 높이를 ${_stageTextMap[_pillowHeightStage]}로 설정합니다 (UI만 변경)',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ... (_buildAutoAdjustmentCard, _buildSleepModeSettings, _buildGuideCard는 그대로 유지) ...
  Widget _buildAutoAdjustmentCard(
    BuildContext context,
    SettingsState settingsState,
  ) {
    // (기존 코드와 동일)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: _mainDeepColor, size: 24),
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
                      Text('수면 시 높이 자동 조절 활성화', style: AppTextStyles.bodyText),
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
                  activeColor: _mainDeepColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepModeSettings(BuildContext context) {
    // (기존 코드와 동일)
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard(BuildContext context) {
    // (기존 코드와 동일)
    return Card(
      color: _mainDeepColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: _mainDeepColor, size: 24),
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

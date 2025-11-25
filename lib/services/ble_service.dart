// lib/services/ble_service.dart

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ 추가: kIsWeb 사용

// --- 베개 UUID ---
const String PILLOW_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String PRESSURE_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String SNORING_CHAR_UUID = "1c95d5e2-0a21-48e6-86cf-1a6f0542d4a6";
const String ALARM_CHAR_UUID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";

// --- 팔찌 UUID ---
const String WRISTBAND_SERVICE_UUID = "0000180d-0000-1000-8000-00805f9b34fb";
const String HEART_RATE_CHAR_UUID = "00002a37-0000-1000-8000-00805f9b34fb";
const String SPO2_CHAR_UUID = "00002a5f-0000-1000-8000-00805f9b34fb";

class BleService extends ChangeNotifier {
  // 장치 분리
  BluetoothDevice? _pillowDevice;
  BluetoothDevice? _watchDevice;

  // 특성 분리
  BluetoothCharacteristic? _pressureChar;
  BluetoothCharacteristic? _snoringChar;
  BluetoothCharacteristic? _heartRateChar;
  BluetoothCharacteristic? _spo2Char;
  BluetoothCharacteristic? _alarmChar;

  // 상태 분리
  String _pillowStatus = "베개 연결 끊김";
  String _watchStatus = "팔찌 연결 끊김";
  bool _isPillowConnected = false;
  bool _isWatchConnected = false;

  // 데이터 변수
  double pressureValue = 0.0;
  bool isSnoring = false;
  double heartRate = 0.0;
  double spo2 = 0.0;

  String get pillowConnectionStatus => _pillowStatus;
  String get watchConnectionStatus => _watchStatus;
  bool get isPillowConnected => _isPillowConnected;
  bool get isWatchConnected => _isWatchConnected;

  // ----------------------------------------------------
  // 1. 스캔 및 연결 로직 (✅ 웹 호환성 추가)
  // ----------------------------------------------------
  Future<void> startScan() async {
    // ✅ 웹 환경 체크
    if (kIsWeb) {
      _pillowStatus = "웹 환경: BLE 비활성화";
      _watchStatus = "웹 환경: BLE 비활성화";
      notifyListeners();
      print("🌐 웹 환경에서는 BLE를 사용할 수 없습니다.");
      return;
    }

    _pillowStatus = "베개 스캔 중...";
    _watchStatus = "팔찌 스캔 중...";
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(PILLOW_SERVICE_UUID), Guid(WRISTBAND_SERVICE_UUID)],
        timeout: const Duration(seconds: 10),
      );

      // 스캔 결과 리스닝
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          // 1. 베개 찾기
          if (r.advertisementData.serviceUuids.contains(
                Guid(PILLOW_SERVICE_UUID),
              ) &&
              _pillowDevice == null) {
            print("베개 찾음: ${r.device.platformName}");
            _pillowDevice = r.device;
            connectToPillow();
          }
          // 2. 팔찌 찾기
          if (r.advertisementData.serviceUuids.contains(
                Guid(WRISTBAND_SERVICE_UUID),
              ) &&
              _watchDevice == null) {
            print("팔찌 찾음: ${r.device.platformName}");
            _watchDevice = r.device;
            connectToWatch();
          }
        }
      });

      // 10초 후 스캔 자동 종료
      await Future.delayed(const Duration(seconds: 10));
      FlutterBluePlus.stopScan();

      if (_pillowDevice == null) _pillowStatus = "베개 없음";
      if (_watchDevice == null) _watchStatus = "팔찌 없음";
    } catch (e) {
      print("⚠️ BLE 스캔 오류: $e");
      _pillowStatus = "스캔 실패";
      _watchStatus = "스캔 실패";
    }

    notifyListeners();
  }

  // --- 베개 연결 (✅ 웹 체크 추가) ---
  Future<void> connectToPillow() async {
    if (kIsWeb) {
      print("🌐 웹에서는 BLE 연결 불가");
      return;
    }

    if (_pillowDevice == null) return;
    _pillowStatus = "베개 연결 시도 중...";
    notifyListeners();

    try {
      await _pillowDevice!.connect();
      _isPillowConnected = true;
      _pillowStatus = "베개 연결 성공";
      await _discoverPillowServices();
    } catch (e) {
      _isPillowConnected = false;
      _pillowStatus = "베개 연결 실패: $e";
      print("⚠️ 베개 연결 오류: $e");
    }
    notifyListeners();
  }

  // --- 워치 연결 (✅ 웹 체크 추가) ---
  Future<void> connectToWatch() async {
    if (kIsWeb) {
      print("🌐 웹에서는 BLE 연결 불가");
      return;
    }

    if (_watchDevice == null) return;
    _watchStatus = "팔찌 연결 시도 중...";
    notifyListeners();

    try {
      await _watchDevice!.connect();
      _isWatchConnected = true;
      _watchStatus = "팔찌 연결 성공";
      await _discoverWatchServices();
    } catch (e) {
      _isWatchConnected = false;
      _watchStatus = "팔찌 연결 실패: $e";
      print("⚠️ 팔찌 연결 오류: $e");
    }
    notifyListeners();
  }

  // ----------------------------------------------------
  // 2. 서비스 검색 및 구독
  // ----------------------------------------------------

  // 공통 구독 헬퍼 함수
  Future<void> _subscribeToCharacteristic(
    BluetoothCharacteristic char,
    Function(List<int>) onData,
  ) async {
    try {
      await char.setNotifyValue(true);
      char.onValueReceived.listen(onData);
    } catch (e) {
      print("⚠️ 구독 실패: $e");
    }
  }

  // --- 베개 서비스 검색 ---
  Future<void> _discoverPillowServices() async {
    try {
      List<BluetoothService> services = await _pillowDevice!.discoverServices();
      for (var s in services) {
        if (s.uuid == Guid(PILLOW_SERVICE_UUID)) {
          for (var c in s.characteristics) {
            if (c.uuid == Guid(PRESSURE_CHAR_UUID)) {
              _pressureChar = c;
              await _subscribeToCharacteristic(_pressureChar!, (value) {
                pressureValue = value.length.toDouble();
                notifyListeners();
              });
            }
            if (c.uuid == Guid(SNORING_CHAR_UUID)) {
              _snoringChar = c;
              await _subscribeToCharacteristic(_snoringChar!, (value) {
                isSnoring = value.isNotEmpty && value[0] > 0;
                notifyListeners();
              });
            }
            if (c.uuid == Guid(ALARM_CHAR_UUID)) {
              _alarmChar = c;
              print("✅ 베개 알람 특성 발견");
            }
          }
        }
      }
    } catch (e) {
      print("⚠️ 베개 서비스 검색 오류: $e");
    }
  }

  // --- 워치 서비스 검색 ---
  Future<void> _discoverWatchServices() async {
    try {
      List<BluetoothService> services = await _watchDevice!.discoverServices();
      for (var s in services) {
        if (s.uuid == Guid(WRISTBAND_SERVICE_UUID)) {
          for (var c in s.characteristics) {
            if (c.uuid == Guid(HEART_RATE_CHAR_UUID)) {
              _heartRateChar = c;
              await _subscribeToCharacteristic(_heartRateChar!, (value) {
                heartRate = value.length.toDouble() + 60;
                notifyListeners();
              });
            }
            if (c.uuid == Guid(SPO2_CHAR_UUID)) {
              _spo2Char = c;
              await _subscribeToCharacteristic(_spo2Char!, (value) {
                spo2 = value.length.toDouble() + 95;
                notifyListeners();
              });
            }
          }
        }
      }
    } catch (e) {
      print("⚠️ 워치 서비스 검색 오류: $e");
    }
  }

  // ----------------------------------------------------
  // 3. 알람 진동 명령 (✅ 웹 체크 추가)
  // ----------------------------------------------------
  Future<void> sendVibrationCommand() async {
    // ✅ 웹 환경 체크
    if (kIsWeb) {
      print("🌐 웹에서는 진동 명령 불가");
      return;
    }

    if (_alarmChar == null || !_isPillowConnected) {
      print("⚠️ 알람 실패: 베개 미연결 또는 특성 없음");
      return;
    }

    try {
      await _alarmChar!.write([0x01], withoutResponse: true);
      print("✅ 베개 진동 명령 전송 성공");
    } catch (e) {
      print("⚠️ 알람 명령 전송 실패: $e");
    }
  }

  // ----------------------------------------------------
  // 4. 연결 해제 (✅ 추가)
  // ----------------------------------------------------
  Future<void> disconnectAll() async {
    if (kIsWeb) return;

    try {
      if (_pillowDevice != null && _isPillowConnected) {
        await _pillowDevice!.disconnect();
        _isPillowConnected = false;
        _pillowStatus = "베개 연결 끊김";
      }

      if (_watchDevice != null && _isWatchConnected) {
        await _watchDevice!.disconnect();
        _isWatchConnected = false;
        _watchStatus = "팔찌 연결 끊김";
      }

      notifyListeners();
      print("✅ 모든 장치 연결 해제");
    } catch (e) {
      print("⚠️ 연결 해제 오류: $e");
    }
  }

  // ----------------------------------------------------
  // 5. 정리 (✅ 추가)
  // ----------------------------------------------------
  @override
  void dispose() {
    disconnectAll();
    super.dispose();
  }
}

// lib/services/ble_service.dart

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';

// --- 베개 UUID ---
const String PILLOW_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String PRESSURE_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String SNORING_CHAR_UUID = "1c95d5e2-0a21-48e6-86cf-1a6f0542d4a6";
// ✅ 1. 알람(진동) UUID는 베개 서비스에 포함되어야 함 (하드웨어 팀과 확정 필요)
const String ALARM_CHAR_UUID =
    "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"; // <-- [중요] 임시 UUID, 친구 B에게 받아야 함

// --- 팔찌 UUID ---
const String WRISTBAND_SERVICE_UUID =
    "0000180d-0000-1000-8000-00805f9b34fb"; // 예시: Heart Rate Service
const String HEART_RATE_CHAR_UUID =
    "00002a37-0000-1000-8000-00805f9b34fb"; // 예시: Heart Rate Measurement
const String SPO2_CHAR_UUID =
    "00002a5f-0000-1000-8000-00805f9b34fb"; // 예시: SpO2

class BleService extends ChangeNotifier {
  // 장치 분리
  BluetoothDevice? _pillowDevice;
  BluetoothDevice? _watchDevice; // '팔찌' -> '워치'

  // 특성 분리
  BluetoothCharacteristic? _pressureChar;
  BluetoothCharacteristic? _snoringChar;
  BluetoothCharacteristic? _heartRateChar;
  BluetoothCharacteristic? _spo2Char;
  BluetoothCharacteristic? _alarmChar; // '베개'의 알람 특성

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
  // 1. 스캔 및 연결 로직
  // ----------------------------------------------------
  Future<void> startScan() async {
    _pillowStatus = "베개 스캔 중...";
    _watchStatus = "팔찌 스캔 중...";
    notifyListeners();

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
          connectToPillow(); // 베개 연결 시도
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
    notifyListeners();
  }

  // --- 베개 연결 ---
  Future<void> connectToPillow() async {
    if (_pillowDevice == null) return;
    _pillowStatus = "베개 연결 시도 중...";
    notifyListeners();
    try {
      await _pillowDevice!.connect();
      _isPillowConnected = true;
      _pillowStatus = "베개 연결 성공";
      await _discoverPillowServices(); // 베개 서비스 검색
    } catch (e) {
      _isPillowConnected = false;
      _pillowStatus = "베개 연결 실패: $e";
    }
    notifyListeners();
  }

  // --- 워치 연결 ---
  Future<void> connectToWatch() async {
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
    }
    notifyListeners();
  }

  // ----------------------------------------------------
  // 2. 서비스 검색 및 구독 (로직 오류 수정)
  // ----------------------------------------------------

  // 공통 구독 헬퍼 함수
  Future<void> _subscribeToCharacteristic(
    BluetoothCharacteristic char,
    Function(List<int>) onData,
  ) async {
    await char.setNotifyValue(true);
    char.onValueReceived.listen(onData);
  }

  // --- 베개 서비스 검색 (알람 특성 찾기 추가) ---
  Future<void> _discoverPillowServices() async {
    List<BluetoothService> services = await _pillowDevice!.discoverServices();
    for (var s in services) {
      if (s.uuid == Guid(PILLOW_SERVICE_UUID)) {
        for (var c in s.characteristics) {
          if (c.uuid == Guid(PRESSURE_CHAR_UUID)) {
            _pressureChar = c;
            await _subscribeToCharacteristic(_pressureChar!, (value) {
              // TODO: 실제 ESP32 데이터 파싱 로직 구현
              pressureValue = value.length.toDouble();
              notifyListeners();
            });
          }
          if (c.uuid == Guid(SNORING_CHAR_UUID)) {
            _snoringChar = c;
            await _subscribeToCharacteristic(_snoringChar!, (value) {
              // TODO: 실제 ESP32 데이터 파싱 로직 구현
              isSnoring = value.isNotEmpty && value[0] > 0;
              notifyListeners();
            });
          }
          // ✅ 3. 알람(진동) 특성을 '베개' 서비스에서 찾도록 수정
          if (c.uuid == Guid(ALARM_CHAR_UUID)) {
            _alarmChar = c;
            print("베개에서 알람 특성을 찾았습니다.");
          }
        }
      }
    }
  }

  // --- 워치 서비스 검색 (복사-붙여넣기 오류 수정) ---
  Future<void> _discoverWatchServices() async {
    List<BluetoothService> services = await _watchDevice!.discoverServices();
    for (var s in services) {
      // ✅ 4. PILLOW_SERVICE_UUID -> WRISTBAND_SERVICE_UUID로 수정
      if (s.uuid == Guid(WRISTBAND_SERVICE_UUID)) {
        for (var c in s.characteristics) {
          // 심박수 구독
          if (c.uuid == Guid(HEART_RATE_CHAR_UUID)) {
            _heartRateChar = c;
            await _subscribeToCharacteristic(_heartRateChar!, (value) {
              // TODO: 실제 워치 데이터 파싱 로직 구현
              heartRate = value.length.toDouble() + 60; // 임시 파싱
              notifyListeners();
            });
          }
          // SpO2 구독
          if (c.uuid == Guid(SPO2_CHAR_UUID)) {
            _spo2Char = c;
            await _subscribeToCharacteristic(_spo2Char!, (value) {
              // TODO: 실제 워치 데이터 파싱 로직 구현
              spo2 = value.length.toDouble() + 95; // 임시 파싱
              notifyListeners();
            });
          }
          // ❌ 알람(진동) 특성은 베개로 이동했으므로 여기서 삭제
        }
      }
    }
  }

  // ----------------------------------------------------
  // 3. 알람 진동 명령 (Write) - 대상이 베개인지 확인
  // ----------------------------------------------------
  Future<void> sendVibrationCommand() async {
    // ⚠️ 연결 확인 대상이 _isPillowConnected인지 확인 (정상)
    if (_alarmChar == null || !_isPillowConnected) {
      print("알람 실패: 베개가 연결되지 않았거나 알람 특성을 찾지 못했습니다.");
      return;
    }

    try {
      // "진동 시작" 명령 (예: 1바이트 값 [0x01] 전송)
      await _alarmChar!.write([0x01], withoutResponse: true);
      print("✅ 베개로 알람(진동) 명령 전송 성공");
    } catch (e) {
      print("알람 명령 전송 실패: $e");
    }
  }
}

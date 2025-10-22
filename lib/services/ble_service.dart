// lib/services/ble_service.dart

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';

// ESP32 BLE 서비스 및 특성(Characteristic) UUID 정의
// 이 값들은 ESP32 펌웨어와 반드시 일치해야 합니다.
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String PRESSURE_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String SNORING_CHAR_UUID = "1c95d5e2-0a21-48e6-86cf-1a6f0542d4a6";

class BleService extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _pressureCharacteristic;
  BluetoothCharacteristic? _snoringCharacteristic;
  bool _isConnected = false;
  String _connectionStatus = "연결 끊김";

  // 현재 센서 값 (AppState와 동기화될 값)
  double pressureValue = 0.0;
  bool isSnoring = false;

  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  // ----------------------------------------------------
  // 1. BLE 스캔 및 장치 연결 (최신 문법 적용)
  // ----------------------------------------------------
  Future<void> startScanAndConnect() async {
    _connectionStatus = "스캔 중...";
    notifyListeners();

    // ✅ 최신 문법: startScan에 필터와 타임아웃을 전달합니다.
    await FlutterBluePlus.startScan(
      withServices: [Guid(SERVICE_UUID)],
      timeout: const Duration(seconds: 5),
    );

    // 스캔 결과를 리스트로 가져옵니다.
    // 5초 동안 스캔 후 결과를 가져오는 방식으로 변경했습니다.
    await Future.delayed(const Duration(seconds: 5));
    List<ScanResult> scanResults = FlutterBluePlus.lastScanResults;

    for (ScanResult result in scanResults) {
      if (result.device.platformName.startsWith("ESP32")) {
        // ESP32 장치 이름으로 가정
        _connectedDevice = result.device;
        await FlutterBluePlus.stopScan(); // 장치를 찾으면 스캔 중지
        await connectToDevice();
        return;
      }
    }

    // 장치를 못 찾았을 경우
    await FlutterBluePlus.stopScan();
    _connectionStatus = "장치 없음";
    notifyListeners();
  }

  Future<void> connectToDevice() async {
    if (_connectedDevice == null) return;

    _connectionStatus = "연결 시도 중...";
    notifyListeners();

    try {
      await _connectedDevice!.connect();
      _isConnected = true;
      _connectionStatus = "연결 성공";
      notifyListeners();
      await _discoverServices(); // 서비스 검색 시작
    } catch (e) {
      _isConnected = false;
      _connectionStatus = "연결 실패: $e";
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // 2. 서비스와 특성(Characteristic) 검색 및 구독
  // ----------------------------------------------------
  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    List<BluetoothService> services = await _connectedDevice!
        .discoverServices();

    for (var service in services) {
      if (service.uuid == Guid(SERVICE_UUID)) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == Guid(PRESSURE_CHAR_UUID)) {
            _pressureCharacteristic = characteristic;
            await _subscribeToPressure(); // 압력 데이터 구독 시작
          } else if (characteristic.uuid == Guid(SNORING_CHAR_UUID)) {
            _snoringCharacteristic = characteristic;
            await _subscribeToSnoring(); // 코골이 데이터 구독 시작
          }
        }
      }
    }
    notifyListeners();
  }

  // 3. 압력 데이터 구독 로직
  Future<void> _subscribeToPressure() async {
    if (_pressureCharacteristic == null) return;

    await _pressureCharacteristic!.setNotifyValue(true);
    _pressureCharacteristic!.lastValueStream.listen((value) {
      // 받은 바이트 데이터를 앱이 사용할 double 형태로 변환 (ESP32 통신 규격에 맞게 파싱 필요)
      // 여기서는 임시로 값의 길이를 사용합니다.
      pressureValue = value.length.toDouble() * 10;
      // 이 값을 AppState의 심박수/압력 값으로 업데이트하는 로직이 필요합니다.
      notifyListeners();
    });
  }

  // 4. 코골이 데이터 구독 로직
  Future<void> _subscribeToSnoring() async {
    if (_snoringCharacteristic == null) return;

    await _snoringCharacteristic!.setNotifyValue(true);
    _snoringCharacteristic!.lastValueStream.listen((value) {
      // 받은 바이트 데이터를 앱이 사용할 boolean 형태로 변환
      isSnoring = value.isNotEmpty && value[0] > 0;
      notifyListeners();
    });
  }
}

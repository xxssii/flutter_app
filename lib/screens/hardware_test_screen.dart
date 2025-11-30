import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class HardwareTestScreen extends StatefulWidget {
  const HardwareTestScreen({super.key});

  @override
  State<HardwareTestScreen> createState() => _HardwareTestScreenState();
}

class _HardwareTestScreenState extends State<HardwareTestScreen> {
  // ⏱️ 스톱워치 관련 변수
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = "0.0초";
  String _lastAction = "대기 중";

  // 타이머 시작 함수
  void _startTimer(String actionName) {
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {
      _lastAction = "$actionName 중...";
    });

    _timer?.cancel(); // 기존 타이머 취소
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        // 0.1초 단위로 업데이트
        _elapsedTime = "${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}초";
      });
    });
  }

  // 타이머 정지 함수
  void _stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _lastAction = "종료됨 (작동 시간: $_elapsedTime)";
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleService = Provider.of<BleService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("⏱️ 에어백 시간 측정 테스트"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 상태 및 타이머 카드
            _buildStatusAndTimerCard(bleService),
            const SizedBox(height: 20),

            // 2. 전체 정지 버튼
            ElevatedButton.icon(
              onPressed: () {
                bleService.sendRawCommand("0");
                _stopTimer(); // ⏹️ 정지 누르면 타이머 멈춤
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.stop_circle, size: 30),
              label: const Text("⛔ 전체 정지 & 타이머 종료",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),

            // 3. 셀 제어 버튼들
            _buildControlRow(context, bleService, "Cell 1 (목)", "1", "4"),
            const Divider(),
            _buildControlRow(context, bleService, "Cell 2 (머리)", "2", "5"),
            const Divider(),
            _buildControlRow(context, bleService, "Cell 3 (전체)", "3", "6"),
            
            const Divider(),
            const SizedBox(height: 10),
            
            // 4. 진동 모터
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => bleService.sendRawCommand("7"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text("진동 ON"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => bleService.sendRawCommand("8"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text("진동 OFF"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAndTimerCard(BleService bleService) {
    bool isConnected = bleService.isPillowConnected;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // 연결 상태
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: isConnected ? Colors.green : Colors.red),
              const SizedBox(width: 10),
              Text(isConnected ? "연결됨" : "연결 안 됨",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          
          // ⏱️ 타이머 표시부 (핵심!)
          Text(_lastAction, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            _elapsedTime,
            style: const TextStyle(
              fontSize: 48, 
              fontWeight: FontWeight.bold, 
              color: Colors.indigo,
              fontFamily: "monospace" // 숫자 폭 일정하게
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(BuildContext context, BleService ble, String title,
      String inflateCmd, String deflateCmd) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ble.sendRawCommand(inflateCmd);
                    _startTimer("$title 부풀리기"); // ▶️ 타이머 시작
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text("주입 (Start)"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ble.sendRawCommand(deflateCmd);
                    _stopTimer(); // ⏹️ 타이머 정지 (시간 기록됨)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text("배출 (Stop)"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
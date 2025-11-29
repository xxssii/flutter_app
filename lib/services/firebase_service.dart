import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String userId = "demoUser";
  String sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";

  // raw_data에 전송
  Future<void> sendSensorData({
    required double heartRate,
    required double spo2,
    required double pressure,
    required double micLevel,
  }) async {
    try {
      await _db.collection('raw_data').add({
        'userId': userId,
        'sessionId': sessionId,
        'ts': FieldValue.serverTimestamp(),
        'hr': heartRate,
        'spo2': spo2,
        'pressure_level': pressure,
        'mic_level': micLevel,
      });

      print("✅ Firebase 전송 성공");
    } catch (e) {
      print("⚠️ Firebase 전송 실패: $e");
    }
  }
}

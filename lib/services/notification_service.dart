import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // 1. 초기화
  Future<void> init() async {
    debugPrint("🔔 [Dummy] 알림 서비스 초기화됨");
  }

  // 2. 테스트 알림
  Future<void> showTestNotification() async {
    debugPrint("🔔 [Dummy] 테스트 알림 요청됨");
  }

  // 3. 리포트 알림 (⚠️ 여기가 문제였음! String으로 수정)
  Future<void> scheduleDailyReportNotification(
    String title,
    String body,
  ) async {
    debugPrint("🔔 [Dummy] 리포트 알림 예약됨: $title - $body");
  }

  // 4. 경고 알림 (⚠️ id 포함하도록 수정)
  Future<void> showImmediateWarning(
    int id,
    String title,
    String body,
  ) async {
    debugPrint("🔔 [Dummy] 경고 알림($id) 요청됨: $title - $body");
  }

  // 5. 수면 팁 알림
  Future<void> scheduleDailySleepTip() async {
    debugPrint("🔔 [Dummy] 수면 팁 알림 예약됨");
  }

  // 6. 취소
  Future<void> cancelAllNotifications() async {
    debugPrint("🔔 [Dummy] 모든 알림 취소됨");
  }
}

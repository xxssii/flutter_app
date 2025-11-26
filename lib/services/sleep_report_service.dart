// lib/services/sleep_report_service.dart

import 'package:cloud_functions/cloud_functions.dart';

class SleepReportService {
  final functions = FirebaseFunctions.instance;

  // 1. 수면 점수 조회 (기존 코드 유지)
  Future<Map<String, dynamic>> getSleepScore(String sessionId) async {
    try {
      final result = await functions
          .httpsCallable('calculate_sleep_score')
          .call({'session_id': sessionId});

      return result.data;
    } catch (e) {
      print('수면 점수 조회 오류: $e');
      rethrow;
    }
  }

  // 2. 주간 통계 조회 (기존 코드 유지)
  Future<Map<String, dynamic>> getWeeklyStats(String userId) async {
    try {
      final result = await functions
          .httpsCallable('calculate_weekly_stats')
          .call({'user_id': userId});

      return result.data;
    } catch (e) {
      print('주간 통계 조회 오류: $e');
      rethrow;
    }
  }

  // ✅ 3. 인사이트 조회 (새로 추가)
  Future<Map<String, dynamic>> getInsights(String sessionId) async {
    try {
      final result = await functions
          .httpsCallable('generate_sleep_insights')
          .call({'session_id': sessionId});

      return result.data;
    } catch (e) {
      print('인사이트 조회 오류: $e');
      rethrow;
    }
  }

  // ✅ 4. 월간 트렌드 조회 (새로 추가)
  Future<Map<String, dynamic>> getMonthlyTrends(String userId) async {
    try {
      final result = await functions
          .httpsCallable('calculate_monthly_trends')
          .call({
            'user_id': userId,
            'days': 30, // 30일간의 데이터 조회
          });

      return result.data;
    } catch (e) {
      print('월간 트렌드 조회 오류: $e');
      rethrow;
    }
  }

  // ✅ 5. 세션 종료 시 자동 리포트 생성 (새로 추가)
  Future<void> autoGenerateReport(String userId, String sessionId) async {
    try {
      await functions.httpsCallable('auto_generate_report').call({
        'user_id': userId,
        'session_id': sessionId,
      });
      print('자동 리포트 생성 완료');
    } catch (e) {
      print('자동 리포트 생성 오류: $e');
      rethrow;
    }
  }
}

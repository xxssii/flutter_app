// lib/services/sleep_api_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import '../models/sleep_report_model.dart';

class SleepApiService {
  // ✅ 중요: 백엔드 코드에 설정된 리전과 맞춰야 합니다. (main.py에 asia-northeast3로 되어 있음)
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-northeast3',
  );

  /// [calculate_sleep_score] Cloud Function 호출
  Future<SleepReport> fetchSleepScore(
    String sessionId, {
    String? userId,
  }) async {
    try {
      print('📡 API 호출 시작: calculate_sleep_score (Session: $sessionId)');

      final HttpsCallable callable = _functions.httpsCallable(
        'calculate_sleep_score',
      );

      final result = await callable.call(<String, dynamic>{
        'session_id': sessionId,
        if (userId != null) 'user_id': userId,
      });

      print('✅ API 호출 성공! 데이터 파싱 시작');
      // 결과 data를 Map으로 형변환 후 모델 팩토리 생성자에 전달
      final dataMap = Map<String, dynamic>.from(result.data);
      return SleepReport.fromJson(dataMap);
    } on FirebaseFunctionsException catch (e) {
      print('🔥 Firebase Function 에러: ${e.code} - ${e.message}');
      // 필요에 따라 커스텀 예외를 던질 수 있음
      throw Exception('수면 데이터를 분석하는 중 문제가 발생했습니다: ${e.message}');
    } catch (e) {
      print('🔥 알 수 없는 에러: $e');
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }

  // TODO: 여기에 calculate_weekly_stats, generate_sleep_insights 등 다른 API 함수들도 추가
}

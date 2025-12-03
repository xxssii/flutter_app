// lib/models/sleep_report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ 수면 리포트 데이터 모델
class SleepReport {
  final String sessionId;
  final String userId;
  final DateTime createdAt;
  final int totalScore;
  final String grade;
  final String message;
  final SleepSummary summary;
  final Breakdown breakdown;

  SleepReport({
    required this.sessionId,
    required this.userId,
    required this.createdAt,
    required this.totalScore,
    required this.grade,
    required this.message,
    required this.summary,
    required this.breakdown,
  });

  // 1. Cloud Functions API 응답(JSON Map)으로부터 객체 생성
  factory SleepReport.fromJson(Map<String, dynamic> json) {
    return SleepReport(
      sessionId: json['sessionId'] ?? '',
      userId: json['userId'] ?? '',
      // Cloud Functions는 날짜를 ISO 8601 문자열로 반환하므로 DateTime.parse 사용
      createdAt: DateTime.parse(json['created_at']),
      totalScore: json['total_score'] ?? 0,
      grade: json['grade'] ?? '',
      message: json['message'] ?? '',
      summary: SleepSummary.fromMap(json['summary'] ?? {}),
      breakdown: Breakdown.fromMap(json['breakdown'] ?? {}),
    );
  }

  // 2. Firestore 문서(DocumentSnapshot)로부터 객체 생성
  factory SleepReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SleepReport(
      sessionId: doc.id,
      userId: data['userId'] ?? '',
      // Firestore는 날짜를 Timestamp 객체로 저장하므로 toDate() 사용
      createdAt: (data['created_at'] as Timestamp).toDate(),
      totalScore: data['total_score'] ?? 0,
      grade: data['grade'] ?? '',
      message: data['message'] ?? '',
      summary: SleepSummary.fromMap(data['summary'] ?? {}),
      breakdown: Breakdown.fromMap(data['breakdown'] ?? {}),
    );
  }

  // ---------------------------------------------------------
  // ✅ UI에서 사용하기 위한 편의 Getter
  // ---------------------------------------------------------

  /// 1. 실제 수면 시간 (UI 연결용)
  double get totalSleepDuration => summary.totalDurationHours;

  /// 2. 누운 시간 계산 로직 (핵심 수정 사항!)
  /// 공식: 실 수면 시간 + 깬 시간 = 총 누운 시간
  double get timeInBed => summary.totalDurationHours + summary.awakeHours;

  /// 3. 수면 효율 (자동 계산)
  /// 공식: (실 수면 / 누운 시간) * 100
  double get sleepEfficiency {
    if (timeInBed == 0) return 0.0;
    return (totalSleepDuration / timeInBed) * 100;
  }

  /// 4. 기타 비율 데이터 연결
  double get remRatio => summary.remRatio;
  double get deepSleepRatio => summary.deepRatio;

  /// 5. 날짜 정보 (sessionId가 'session-2024-11-27' 형식이므로 그대로 사용)
  String get reportDate => sessionId;
}

// 수면 요약 데이터 모델
class SleepSummary {
  final double totalDurationHours;
  final double deepSleepHours;
  final double remSleepHours;
  final double lightSleepHours;
  final double awakeHours;
  final double deepRatio;
  final double remRatio;
  final double awakeRatio;
  final int apneaCount;
  final double snoringDuration;

  SleepSummary({
    required this.totalDurationHours,
    required this.deepSleepHours,
    required this.remSleepHours,
    required this.lightSleepHours,
    required this.awakeHours,
    required this.deepRatio,
    required this.remRatio,
    required this.awakeRatio,
    required this.apneaCount,
    required this.snoringDuration,
  });

  factory SleepSummary.fromMap(Map<String, dynamic> data) {
    // 👇 1. 디버깅용 로그 - 수면 데이터 확인
    print('🔍 수면 데이터 확인: $data');
    
    return SleepSummary(
      totalDurationHours: (data['total_duration_hours'] ?? 0).toDouble(),
      deepSleepHours: (data['deep_sleep_hours'] ?? 0).toDouble(),
      remSleepHours: (data['rem_sleep_hours'] ?? 0).toDouble(),
      lightSleepHours: (data['light_sleep_hours'] ?? 0).toDouble(),
      
      // 👇 2. awake_hours 키 값 확인 필요
      awakeHours: (data['awake_hours'] ?? 0).toDouble(),
      
      deepRatio: (data['deep_ratio'] ?? 0).toDouble(),
      remRatio: (data['rem_ratio'] ?? 0).toDouble(),
      awakeRatio: (data['awake_ratio'] ?? 0).toDouble(),
      apneaCount: data['apnea_count'] ?? 0,
      snoringDuration: (data['snoring_duration'] ?? 0).toDouble(),
    );
  }
}

// 세부 점수 데이터 모델
class Breakdown {
  final int durationScore;
  final int deepScore;
  final int remScore;
  final int efficiencyScore;

  Breakdown({
    required this.durationScore,
    required this.deepScore,
    required this.remScore,
    required this.efficiencyScore,
  });

  factory Breakdown.fromMap(Map<String, dynamic> data) {
    return Breakdown(
      durationScore: data['duration_score'] ?? 0,
      deepScore: data['deep_score'] ?? 0,
      remScore: data['rem_score'] ?? 0,
      efficiencyScore: data['efficiency_score'] ?? 0,
    );
  }
}

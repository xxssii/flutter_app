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

  factory SleepReport.fromJson(Map<String, dynamic> json) {
    return SleepReport(
      sessionId: json['sessionId'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      totalScore: json['total_score'] ?? 0,
      grade: json['grade'] ?? '',
      message: json['message'] ?? '',
      summary: SleepSummary.fromMap(json['summary'] ?? {}),
      breakdown: Breakdown.fromMap(json['breakdown'] ?? {}),
    );
  }

  factory SleepReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SleepReport(
      sessionId: doc.id,
      userId: data['userId'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      totalScore: data['total_score'] ?? 0,
      grade: data['grade'] ?? '',
      message: data['message'] ?? '',
      summary: SleepSummary.fromMap(data['summary'] ?? {}),
      breakdown: Breakdown.fromMap(data['breakdown'] ?? {}),
    );
  }

  // 편의 Getter
  double get totalSleepDuration => summary.totalDurationHours; // 실제 수면 시간 (TIB 아님)
  
  // 💡 수정됨: Time In Bed 계산 (수면 시간 + 깬 시간)
  double get timeInBed => summary.totalDurationHours + summary.awakeHours;

  double get sleepEfficiency {
    if (timeInBed == 0) return 0.0;
    double eff = (totalSleepDuration / timeInBed) * 100;
    return eff > 100 ? 100 : eff; // 100% 초과 방지
  }

  double get remRatio => summary.remRatio;
  double get deepSleepRatio => summary.deepRatio;
  String get reportDate => sessionId;
}

// ✅ 수면 요약 데이터 모델 (수정된 로직 포함)
class SleepSummary {
  final double totalDurationHours; // 여기서는 '실제 수면 시간' 혹은 '기록된 총 시간'
  final double deepSleepHours;
  final double remSleepHours;
  final double lightSleepHours;
  final double awakeHours; // 💡 0일 경우 자동 보정됨
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
    // 1. 수면 시간 파싱
    double total = (data['total_duration_hours'] ?? 0).toDouble();
    double deep = (data['deep_sleep_hours'] ?? 0).toDouble();
    double rem = (data['rem_sleep_hours'] ?? 0).toDouble();
    double light = (data['light_sleep_hours'] ?? 0).toDouble();
    
    // 2. 깬 시간 파싱 및 자동 보정
    double parsedAwake = (data['awake_hours'] ?? 0).toDouble();
    double actualSleep = deep + rem + light;
    
    // 데이터에 awake_hours가 0인데, 총 시간이 수면 시간보다 길다면 그 차이를 깬 시간으로 간주
    if (parsedAwake <= 0 && total > actualSleep) {
      parsedAwake = total - actualSleep;
      if (parsedAwake < 0) parsedAwake = 0;
    }

    // 3. 만약 'total_duration_hours'가 실제 수면 시간의 합보다 작다면(데이터 오류), 실제 수면 시간 합으로 대체
    if (total < actualSleep) {
      total = actualSleep;
    }

    return SleepSummary(
      totalDurationHours: actualSleep, // 실제 수면 시간으로 매핑
      deepSleepHours: deep,
      remSleepHours: rem,
      lightSleepHours: light,
      awakeHours: parsedAwake,
      
      deepRatio: (data['deep_ratio'] ?? 0).toDouble(),
      remRatio: (data['rem_ratio'] ?? 0).toDouble(),
      awakeRatio: (data['awake_ratio'] ?? 0).toDouble(),
      apneaCount: data['apnea_count'] ?? 0,
      snoringDuration: (data['snoring_duration'] ?? 0).toDouble(),
    );
  }
}

// ✅ 세부 점수 데이터 모델 (누락되었던 부분)
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
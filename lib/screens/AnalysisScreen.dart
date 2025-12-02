// lib/screens/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // pubspec.yaml에 intl 패키지 추가 필요 (없으면 flutter pub add intl)
import '../utils/app_text_styles.dart';
import '../utils/app_colors.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 데모 유저 ID (AppState와 동일하게)
    const String userId = "demoUser"; // 또는 "demo_user" (데이터 생성기와 일치시킬것!)

    return Scaffold(
      appBar: AppBar(title: const Text('수면 분석 (최근 7일)')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sleep_reports')
            // .where('userId', isEqualTo: userId) // 필요시 주석 해제
            .orderBy('created_at', descending: true)
            .limit(7)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('오류: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('데이터가 없습니다. 홈에서 데이터를 생성해주세요.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildReportCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data) {
    // 데이터 파싱
    final summary = data['summary'] as Map<String, dynamic>;
    final breakdown = data['breakdown'] as Map<String, dynamic>?;
    
    final dateStr = data['created_at']?.toString().split('T')[0] ?? '날짜 없음';
    final score = data['total_score'] ?? 0;
    final totalSleep = summary['total_duration_hours'] ?? 0.0;
    final efficiency = summary['awake_ratio'] != null ? (100 - (summary['awake_ratio'] as num)) : 0; // Awake 비율 역산
    final remRatio = summary['rem_ratio'] ?? 0;

    // 누운 시간 대비 실 수면 시간 (간단히 계산)
    // 실제로는 누운 시간 데이터가 따로 있어야 하지만, 여기선 총 수면 / (총 수면 + Awake) 로 근사치 표현
    // 혹은 total_duration_hours를 실 수면 시간으로 가정.

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: AppTextStyles.heading3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: score >= 80 ? Colors.blue : (score >= 60 ? Colors.orange : Colors.red),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$score점', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildRow('총 수면 시간', '${totalSleep.toStringAsFixed(1)} 시간'),
            _buildRow('수면 효율', '${efficiency.toStringAsFixed(1)} %'),
            _buildRow('REM 수면 비율', '${remRatio.toStringAsFixed(1)} %'),
            const SizedBox(height: 8),
            const Text("수면 단계 분포:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _buildBarChart(summary),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.secondaryBodyText),
          Text(value, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> summary) {
    final deep = (summary['deep_ratio'] as num?)?.toDouble() ?? 0;
    final light = (summary['light_sleep_hours'] as num?)?.toDouble() ?? 0; // 비율이 없으면 시간으로라도.. (데이터 구조 확인 필요)
    // 여기선 summary에 ratio가 있다고 가정 (main.py에서 deep_ratio, rem_ratio 등 넣어줌)
    final rem = (summary['rem_ratio'] as num?)?.toDouble() ?? 0;
    final awake = (summary['awake_ratio'] as num?)?.toDouble() ?? 0;
    
    // Light 비율 역산 (전체 100에서 나머지 뺌)
    double lightRatio = 100 - (deep + rem + awake);
    if (lightRatio < 0) lightRatio = 0;

    return SizedBox(
      height: 20,
      child: Row(
        children: [
          if (deep > 0) Expanded(flex: deep.toInt(), child: Container(color: Colors.indigo, child: const Center(child: Text('Deep', style: TextStyle(fontSize: 8, color: Colors.white))))),
          if (lightRatio > 0) Expanded(flex: lightRatio.toInt(), child: Container(color: Colors.blue, child: const Center(child: Text('Light', style: TextStyle(fontSize: 8, color: Colors.white))))),
          if (rem > 0) Expanded(flex: rem.toInt(), child: Container(color: Colors.purple, child: const Center(child: Text('REM', style: TextStyle(fontSize: 8, color: Colors.white))))),
          if (awake > 0) Expanded(flex: awake.toInt(), child: Container(color: Colors.orange, child: const Center(child: Text('Awake', style: TextStyle(fontSize: 8, color: Colors.white))))),
        ],
      ),
    );
  }
}
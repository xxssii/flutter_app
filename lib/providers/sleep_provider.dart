// lib/providers/sleep_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ✅ 올바른 모델 파일 임포트
import '../models/sleep_report_model.dart';

class SleepProvider with ChangeNotifier {
  SleepReport? _latestSleepReport;
  bool _isLoading = false;
  String? _errorMessage;

  SleepReport? get latestSleepReport => _latestSleepReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 최신 수면 리포트 가져오기
  Future<void> fetchLatestSleepReport(String sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 'sleep_reports' 컬렉션에서 데이터 가져오기
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('sleep_reports')
          .doc(sessionId)
          .get();

      if (doc.exists) {
        // ✅ SleepReport.fromFirestore 사용
        _latestSleepReport = SleepReport.fromFirestore(doc);
      } else {
        // 문서가 없을 경우 에러 메시지 설정 (image_0.png 상황)
        _errorMessage = '해당 세션의 수면 리포트를 찾을 수 없습니다.';
      }
    } catch (e) {
      _errorMessage = '수면 리포트를 불러오는 중 오류가 발생했습니다: $e';
      print('Error fetching sleep report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ [추가] 사용자의 가장 최근 수면 리포트 가져오기
  Future<void> fetchMostRecentSleepReport(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sleep_reports')
          .where('userId', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _latestSleepReport = SleepReport.fromFirestore(snapshot.docs.first);
      } else {
        _latestSleepReport = null;
        _errorMessage = '아직 수면 기록이 없습니다.';
      }
    } catch (e) {
      _errorMessage = '최신 수면 리포트를 불러오는 중 오류가 발생했습니다: $e';
      print('Error fetching most recent sleep report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

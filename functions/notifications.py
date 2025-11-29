from firebase_admin import messaging
from google.cloud import firestore as gcf

def get_user_fcm_token(db: gcf.Client, user_id: str) -> str | None:
    """사용자 FCM 토큰 가져오기"""
    user_doc = db.collection("users").document(user_id).get()
    if user_doc.exists:
        user_data = user_doc.to_dict()
        return user_data.get("fcmToken")
    return None

def get_notification_settings(db: gcf.Client, user_id: str) -> dict:
    """사용자 알림 설정 가져오기"""
    user_doc = db.collection("users").document(user_id).get()
    if user_doc.exists:
        user_data = user_doc.to_dict()
        return user_data.get("notificationSettings", {
            "sleepReport": True,
            "sleepScore": True,
            "snoring": True,
            "guide": True,
        })
    return {}

def send_push_notification(
    user_fcm_token: str, 
    title: str, 
    body: str,
    data: dict = None,
    image_url: str = None
):
    """푸시 알림 보내기"""
    
    # 알림 메시지 생성
    notification = messaging.Notification(
        title=title,
        body=body,
        image=image_url  # 선택: 이미지 URL
    )
    
    message = messaging.Message(
        notification=notification,
        data=data or {},  # 추가 데이터 (화면 이동용)
        token=user_fcm_token,
        # Android 설정
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='sleep_channel',  # Flutter 설정과 동일해야 함!
                sound='default',
                color='#1E3A8A',  # AppColors.primaryNavy
            ),
        ),
        # iOS 설정
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    sound='default',
                    badge=1,
                ),
            ),
        ),
    )
    
    try:
        response = messaging.send(message)
        print(f"✅ [푸시 알림 성공] response: {response}")
        return True
    except Exception as e:
        print(f"❌ [푸시 알림 실패] {e}")
        return False

# ========================================
# ✨ 알림 타입별 함수들
# ========================================

def send_sleep_report_notification(db: gcf.Client, user_id: str, score: int, message: str):
    """1. 수면 리포트 알림"""
    settings = get_notification_settings(db, user_id)
    if not settings.get("sleepReport", True):
        print(f"[알림 스킵] {user_id}는 수면 리포트 알림 OFF")
        return
    
    token = get_user_fcm_token(db, user_id)
    if token:
        send_push_notification(
            user_fcm_token=token,
            title="💤 수면 리포트 완성!",
            body=f"오늘 수면 점수는 {score}점이에요. {message}",
            data={
                "type": "sleep_report",
                "userId": user_id,
                "score": str(score),
            }
        )

def send_sleep_efficiency_notification(db: gcf.Client, user_id: str, efficiency: float):
    """2. 수면 효율 알림 (낮을 때만)"""
    settings = get_notification_settings(db, user_id)
    if not settings.get("sleepScore", True):
        return
    
    if efficiency < 75:  # 효율이 75% 미만일 때만
        token = get_user_fcm_token(db, user_id)
        if token:
            send_push_notification(
                user_fcm_token=token,
                title="😴 수면 효율 개선 필요",
                body=f"수면 효율이 {efficiency:.1f}%로 낮아요. 환경을 점검하세요.",
                data={"type": "sleep_efficiency"}
            )

def send_snoring_notification(db: gcf.Client, user_id: str, duration_min: float):
    """3. 코골이 심할 때 알림"""
    settings = get_notification_settings(db, user_id)
    if not settings.get("snoring", True):
        return
    
    if duration_min > 30:  # 30분 이상 코골이
        token = get_user_fcm_token(db, user_id)
        if token:
            send_push_notification(
                user_fcm_token=token,
                title="😮 코골이 감지",
                body=f"{duration_min:.0f}분 이상 코를 골았어요. 수면 자세를 확인하세요.",
                data={"type": "snoring"}
            )

def send_bedtime_reminder(db: gcf.Client, user_id: str):
    """4. 수면 가이드 알림 (취침 1시간 전)"""
    settings = get_notification_settings(db, user_id)
    if not settings.get("guide", True):
        return
    
    token = get_user_fcm_token(db, user_id)
    if token:
        send_push_notification(
            user_fcm_token=token,
            title="🌙 수면 가이드",
            body="1시간 후 취침 시간이에요. 준비하세요!",
            data={"type": "guide"}
        )
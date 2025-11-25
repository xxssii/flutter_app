# # === 0. 기본 라이브러리 임포트 ===
# import os
# import firebase_admin as fa
# from firebase_admin import firestore as fa_firestore
# from google.cloud import firestore as gc_firestore
# from firebase_functions.firestore_fn import on_document_created# ✅ 파이썬용 Firestore 트리거
# from datetime import datetime, timezone
# import hashlib
# import json


# if not fa._apps:
#     fa.initialize_app()

# db = fa_firestore.client() 
# # === 1. 지연 초기화(Lazy Initialization) 유틸 (GPT 해결책) ===
# # "db = firestore.client()"를 파일 상단에서 실행하지 않고,
# # 함수가 "실제로" 호출될 때만 초기화하도록 함.
# _app = None
# _db = None

# def get_db():
#     """첫 호출 때만 firebase_admin을 초기화하고 Firestore 클라이언트를 만듭니다."""
#     global _app, _db
#     if _db is None:
#         try:
#             # 앱이 이미 초기화되었는지 확인
#             _app = firebase_admin.get_app()
#         except ValueError:
#             # 초기화되지 않았다면, 지금 초기화
#             _app = firebase_admin.initialize_app()
#         _db = firestore.client()
#     return _db

# # === 2. 안정화 파라미터 ===
# DEFAULT_MIN_STAGE_DURATION_SEC = 30  # 기본 30초

# def now_utc():
#     return datetime.now(timezone.utc)

# # === 3. 의사결정트리 규칙 이식부 (스타터 뇌) ===
# # (나중에 JupyterLab에서 생성된 코드로 이 함수를 교체하면 됩니다)
# def predict_stage_by_tree(hr: float, motion: float, pressure: float) -> str:
#     # auto-generated from 4-class starter profiles (Awake/Light/Deep/REM)
#     if motion <= 11.5:
#         if motion <= 5.5:
#             return "Deep"
#         else:
#             return "REM"
#     else:
#         if motion <= 35.0:
#             return "Light"
#         else:
#             return "Awake"

# def stage_confidence(stage: str) -> float:
#     return {"Deep": 0.78, "REM": 0.72, "Light": 0.65, "Awake": 0.60}.get(stage, 0.55)

# def min_duration_sec_for(prev_stable_stage: str | None) -> int:
#     # v1: 모두 30초. (v2에서 단계별 차등 적용 가능)
#     return DEFAULT_MIN_STAGE_DURATION_SEC

# # === 4. 명령 정책 ===
# def command_policy(stage: str) -> dict | None:
#     if stage == "Awake":
#         return {"type": "VIBRATE", "payload": {"intensity": 30, "durationMs": 500}, "ttlSec": 8}
#     if stage == "Light":
#         return {"type": "SET_HEIGHT", "payload": {"heightMm": 45}, "ttlSec": 10}
#     if stage == "Deep":
#         return {"type": "SET_HEIGHT", "payload": {"heightMm": 55}, "ttlSec": 10}
#     return None  # REM: 명령 없음

# # === 5. 세션 상태 트랜잭션 (핵심 로직) ===
# @gcf.transactional
# def _update_session_state(
#     tx: firestore.Transaction,
#     state_ref: firestore.DocumentReference,
#     *,
#     user_id: str,
#     session_id: str,
#     raw_stage: str,
#     source_ts: datetime,
#     now: datetime,
# ):
#     snap = tx.get(state_ref)
    
#     if not snap.exists:
#         # Cold start: 세션 첫 데이터 -> 즉시 확정 (전이로 간주)
#         new_state = {
#             "userId": user_id,
#             "sessionId": session_id,
#             "stage": raw_stage,
#             "raw_stage": raw_stage,
#             "last_change_ts": now,
#             "updated_at": now,
#             "last_source_ts": source_ts,
#         }
#         tx.set(state_ref, new_state)
#         return True, raw_stage, now  # (전이 발생, 안정화 단계, 변경 시각)

#     st = snap.to_dict()
#     stable_stage = st.get("stage")
#     last_change_ts = st.get("last_change_ts")
#     if isinstance(last_change_ts, str):
#         last_change_ts = datetime.fromisoformat(last_change_ts)

#     min_needed = min_duration_sec_for(stable_stage)

#     if raw_stage == stable_stage:
#         # 변화 없음: 하트비트만 갱신
#         tx.update(state_ref, {
#             "raw_stage": raw_stage,
#             "updated_at": now,
#             "last_source_ts": source_ts,
#         })
#         return False, stable_stage, last_change_ts

#     # 변화 후보: 경과시간 체크
#     elapsed = (now - last_change_ts).total_seconds() if last_change_ts else 10**9
#     if elapsed >= min_needed:
#         # 전이 승인
#         tx.update(state_ref, {
#             "stage": raw_stage,
#             "raw_stage": raw_stage,
#             "last_change_ts": now,
#             "updated_at": now,
#             "last_source_ts": source_ts,
#         })
#         return True, raw_stage, now
#     else:
#         # 깜빡임 -> 유지 + 하트비트
#         tx.update(state_ref, {
#             "raw_stage": raw_stage,
#             "updated_at": now,
#             "last_source_ts": source_ts,
#         })
#         return False, stable_stage, last_change_ts

# # === 6. 명령 생성 유틸 ===
# def create_command_for_stage(db, user_id, session_id, stable_stage, changed_at):
#     policy = command_policy(stable_stage)
#     if policy:
#         # 멱등키(중복 방지 키) 생성
#         core = json.dumps({
#             "u": user_id, "s": session_id, "stg": stable_stage,
#             "t": int(changed_at.timestamp()),
#         }, sort_keys=True).encode()
#         dkey = hashlib.sha1(core).hexdigest()[:12]
#         cmd_ref = db.collection("commands").document(dkey)
        
#         try:
#             if not cmd_ref.get().exists:
#                 cmd_ref.set({
#                     "userId": user_id,
#                     "sessionId": session_id,
#                     "type": policy["type"],
#                     "payload": policy["payload"],
#                     "status": "PENDING",
#                     "ttlSec": policy["ttlSec"],
#                     "ts": firestore.SERVER_TIMESTAMP,
#                     "dedupKey": dkey,
#                 })
#         except Exception as e:
#             print(f"로그: 커맨드 생성 실패 (중복 가능성): {e}")
#             pass # 중복 생성 시도 등은 무시

# # === 7. 엔트리포인트 (1세대 트리거) ===
# @firestore_fn.on_document_created(document="raw_data/{docId}")
# def on_new_data(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]):
    
#     # ✅ 1. 지연 초기화 실행 (GPT 해결책)
#     db = get_db()

#     # 2. 데이터 추출
#     doc = snap.to_dict() or {}
#     hr        = float(data.get("hr", 0.0))
#     motion    = float(data.get("motion", 0.0))
#     pressure  = float(data.get("pressure", 0.0))
#     user_id   = data.get("userId", "demoUser")
#     session_id= data.get("sessionId", "demoSession")
#     source_ts = data.get("ts", now_utc())
    
#     # 3. '날것' 예측
#     raw_stage = predict_stage_by_tree(hr, motion, pressure)

#     # 4. 세션 상태 문서(단일) 갱신 (트랜잭션)
#     now = now_utc()
#     state_ref = db.collection("session_state").document(f"{user_id}__{session_id}")
    
#     # 트랜잭션 실행
#     transaction = db.transaction()
#     stage_changed, stable_stage, changed_at = _update_session_state(
#         transaction, state_ref,
#         user_id=user_id, session_id=session_id,
#         raw_stage=raw_stage, source_ts=source_ts, now=now,
#     )

#     # 5. 전이 승인 시에만 로그/명령 생성
#     if stage_changed:
#         # processed_data: "전이 이벤트"만 기록
#         db.collection("processed_data").add({
#             "userId": user_id,
#             "sessionId": session_id,
#             "stage": stable_stage,
#             "raw_stage": raw_stage,
#             "confidence": stage_confidence(stable_stage),
#             "ts": firestore.SERVER_TIMESTAMP,
#             "changed_at": changed_at,
#             "source_ts": source_ts,
#         })
        
#         # commands: 정책에 따라 1회 생성
#         create_command_for_stage(db, user_id, session_id, stable_stage, changed_at)

#     print(f"세션 {session_id} 처리 완료: {stable_stage} (변경: {stage_changed})")
#     return

# === Gen2 Cloud Functions for Firebase (Python) ===
# Firestore 트리거(문서 생성) → 세션 상태 갱신 + 명령 생성
import json
import hashlib
from datetime import datetime, timezone, timedelta

import firebase_admin
from firebase_functions import firestore_fn, options, https_fn
from firebase_admin import firestore

# google-cloud-firestore(v2) 타입/트랜잭션 데코레이터는 여기서 가져오는 것이 안전하다
from google.cloud import firestore as gcf  # gcf.Transaction, gcf.DocumentReference, gcf.transactional


# ---------- lazy init ----------
_app_inited = False

def get_db() -> gcf.Client:
    global _app_inited
    if not _app_inited:
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app()
        _app_inited = True
    # Admin 초기화 이후에는 google-cloud-firestore 클라이언트를 그대로 씀
    return gcf.Client()


# ---------- utility ----------
DEFAULT_MIN_STAGE_DURATION_SEC = 30

def now_utc() -> datetime:
    return datetime.now(timezone.utc)

def predict_stage_by_tree(hr: float, spo2: float, mic_level: float, pressure_level: float) -> str:
    """Auto-generated tree classifier (accuracy 100% on training set of 2220 samples)."""
    if hr <= 59.5:
        return "Deep"
    else:  # hr > 59.5
        if spo2 <= 91.9683:
            return "Apnea"
        else:  # spo2 > 91.9683
            if pressure_level <= 1493.5:
                if mic_level <= 109.5:
                    if pressure_level <= 505.0:
                        return "REM"
                    else:  # pressure_level > 505.0
                        return "Light"
                else:  # mic_level > 109.5
                    return "Snoring"
            else:  # pressure_level > 1493.5
                if pressure_level <= 2749.5:
                    return "Awake"
                else:  # pressure_level > 2749.5
                    if spo2 <= 97.1172:
                        return "Tossing"
                    else:  # spo2 > 97.1172
                        return "Tossing"

def stage_confidence(stage: str) -> float:
    return {"Deep": 0.78, "REM": 0.72, "Light": 0.65, "Awake": 0.60}.get(stage, 0.55)

def min_duration_sec_for(prev_stable_stage: str | None) -> int:
    return DEFAULT_MIN_STAGE_DURATION_SEC


def command_policy(stage: str) -> dict | None:
    # 1순위: 위험 이벤트 처리
    if stage == "Apnea":
        return {"type": "VIBRATE_STRONG", "payload": {"level": 10, "durationMs": 3000}, "ttlSec": 20}

    if stage == "Snoring":
        return {"type": "VIBRATE_GENTLY", "payload": {"level": 3, "durationMs": 500}, "ttlSec": 15}

    # 2순위: 수면 단계에 따른 높이 조절
    if stage == "Light":
        return {"type": "SET_HEIGHT", "payload": {"heightMm": 45}, "ttlSec": 10}

    if stage == "Deep":
        return {"type": "SET_HEIGHT", "payload": {"heightMm": 55}, "ttlSec": 10}

    # 3순위: 명령 없음 (Awake, REM, Tossing 등)
    return None


# ---------- transactional session-state update ----------
@gcf.transactional
def _update_session_state(
    tx: gcf.Transaction,
    state_ref: gcf.DocumentReference,
    *,
    user_id: str,
    session_id: str,
    raw_stage: str,
    source_ts: datetime,
    now: datetime,
):
    # 트랜잭션 데코레이터 모드의 올바른 읽기 방법
    snap = state_ref.get(transaction=tx)
    if not snap.exists:
        # cold start
        new_state = {
            "userId": user_id,
            "sessionId": session_id,
            "stage": raw_stage,
            "raw_stage": raw_stage,
            "last_change_ts": now,
            "updated_at": now,
            "last_source_ts": source_ts,
        }
        tx.set(state_ref, new_state)
        return True, raw_stage, now

    st = snap.to_dict() or {}
    stable_stage = st.get("stage")
    last_change_ts = st.get("last_change_ts")

    # Firestore Timestamp → datetime 보정 (안전 처리)
    if isinstance(last_change_ts, datetime):
        pass
    elif last_change_ts is not None and hasattr(last_change_ts, "to_datetime"):
        last_change_ts = last_change_ts.to_datetime().astimezone(timezone.utc)
    else:
        last_change_ts = None

    min_needed = min_duration_sec_for(stable_stage)
    elapsed = (now - last_change_ts).total_seconds() if last_change_ts else 10**9

    if raw_stage == stable_stage:
        # 변화 없음: raw만 갱신
        tx.update(state_ref, {"raw_stage": raw_stage, "updated_at": now, "last_source_ts": source_ts})
        return False, stable_stage, last_change_ts

    if elapsed >= min_needed:
        # 전이 승인
        tx.update(
            state_ref,
            {
                "stage": raw_stage,
                "raw_stage": raw_stage,
                "last_change_ts": now,
                "updated_at": now,
                "last_source_ts": source_ts,
            },
        )
        return True, raw_stage, now
    else:
        # 플리커(깜빡임): 안정화 대기
        tx.update(state_ref, {"raw_stage": raw_stage, "updated_at": now, "last_source_ts": source_ts})
        return False, stable_stage, last_change_ts


def create_command_for_stage(db: gcf.Client, user_id: str, session_id: str, stable_stage: str, changed_at: datetime):
    policy = command_policy(stable_stage)
    if not policy:
        return  # 정책이 없으면 즉시 종료

    # --- ▼ 디버깅: 현재 적용된 정책 출력 ▼ ---
    print(f"[DEBUG_CMD_POLICY] policy: {policy}")
    # --- ▲ 디버깅 라인 끝 ▲ ---

    core = json.dumps(
        {"u": user_id, "s": session_id, "stg": stable_stage, "t": int(changed_at.timestamp())},
        sort_keys=True,
    ).encode()
    dkey = hashlib.sha1(core).hexdigest()[:12]
    cmd_ref = db.collection("commands").document(dkey)

    try:
        cmd_ref.create(
            {
                "userId": user_id,
                "sessionId": session_id,
                "type": policy["type"],
                "payload": policy.get("payload", {}),
                "status": "PENDING",
                "ttlSec": policy["ttlSec"],
                "ts": gcf.SERVER_TIMESTAMP,
                "dedupKey": dkey,
            }
        )
        print(f"[명령 생성 성공] type: {policy['type']}, dkey: {dkey}")
    except Exception as e:
        print(f"[명령 생성 실패] (아마도 중복): {e}")
        pass


# ---------- Gen2 options + Firestore trigger ----------
# 함수 실행 리전(Cloud Run 위치): us-central1 (이미 서비스가 거기에 있음)
options.set_global_options(region="asia-northeast3")

# 이벤트 구독 리전(Eventarc/Firestore 위치): asia-northeast3 (프로젝트 Firestore가 서울)
@firestore_fn.on_document_created(document="raw_data/{docId}", region="asia-northeast3")
def on_new_data(event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None]):
    db = get_db()

    if event.data is None:
        print("no event data; skip")
        return

    data = event.data.to_dict() or {}
    hr = float(data.get("hr", 0.0))
    spo2 = float(data.get("spo2", 98.0))
    mic_level = float(data.get("mic_level", data.get("motion", 0.0)))
    pressure_level = float(data.get("pressure_level", data.get("pressure", 0.0)))
    user_id = data.get("userId", "demoUser")
    session_id = data.get("sessionId", "demoSession")

    # ts는 여러 형태로 들어올 수 있음: Firestore Timestamp, ISO 문자열, epoch(ms/sec), dict {seconds,nanos}
    source_ts_raw = data.get("ts")
    if source_ts_raw is None:
        source_ts = now_utc()
    elif isinstance(source_ts_raw, datetime):
        source_ts = source_ts_raw.astimezone(timezone.utc)
    else:
        try:
            # Firestore Timestamp 타입 처리
            try:
                from google.cloud.firestore_v1 import Timestamp as FsTimestamp  # type: ignore
            except Exception:
                FsTimestamp = None  # type: ignore

            if FsTimestamp is not None and isinstance(source_ts_raw, FsTimestamp):
                source_ts = source_ts_raw.to_datetime().astimezone(timezone.utc)
            elif isinstance(source_ts_raw, dict) and "seconds" in source_ts_raw:
                source_ts = datetime.fromtimestamp(source_ts_raw["seconds"], tz=timezone.utc)
            elif isinstance(source_ts_raw, (int, float)):
                # 값이 매우 크면 ms로 간주
                divisor = 1000.0 if source_ts_raw > 1e12 else 1.0
                source_ts = datetime.fromtimestamp(source_ts_raw / divisor, tz=timezone.utc)
            elif isinstance(source_ts_raw, str):
                try:
                    parsed = datetime.fromisoformat(source_ts_raw)
                    source_ts = parsed.astimezone(timezone.utc) if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
                except Exception:
                    source_ts = now_utc()
            else:
                source_ts = now_utc()
        except Exception:
            source_ts = now_utc()

    raw_stage = predict_stage_by_tree(hr, spo2, mic_level, pressure_level)

    now = now_utc()
    state_ref = db.collection("session_state").document(f"{user_id}__{session_id}")

    try:
        tx = db.transaction()
        stage_changed, stable_stage, changed_at = _update_session_state(
            tx,
            state_ref,
            user_id=user_id,
            session_id=session_id,
            raw_stage=raw_stage,
            source_ts=source_ts,
            now=now,
        )
    except Exception as e:
        print(f"[state] transaction failed: {e}")
        return

    if stage_changed:
        db.collection("processed_data").add(
            {
                "userId": user_id,
                "sessionId": session_id,
                "stage": stable_stage,
                "raw_stage": raw_stage,
                "confidence": stage_confidence(stable_stage),
                "ts": gcf.SERVER_TIMESTAMP,
                "changed_at": changed_at,
                "source_ts": source_ts,
            }
        )
        create_command_for_stage(db, user_id, session_id, stable_stage, changed_at)

    print(f"[session {session_id}] stable={stable_stage}, changed={stage_changed}")


# ========================================
# ✨ E단계: 수면 점수 계산 함수 (수정!)
# ========================================

@https_fn.on_call()
def calculate_sleep_score(req: https_fn.CallableRequest):
    """
    특정 세션의 수면 점수를 계산
    
    요청 파라미터:
    - session_id: 세션 ID (필수)
    - user_id: 사용자 ID (선택, 없으면 세션에서 추출)
    
    반환:
    - total_score: 총점 (100점 만점)
    - breakdown: 세부 점수
    - summary: 수면 요약
    - message: 평가 메시지
    """
    db = get_db()
    
    # 파라미터 추출
    session_id = req.data.get("session_id")
    if not session_id:
        raise https_fn.HttpsError("invalid-argument", "session_id is required")
    
    user_id = req.data.get("user_id")
    
    print(f"[수면 점수 계산 시작] session_id: {session_id}")
    
    try:
        # processed_data에서 세션 데이터 조회
        processed_docs = db.collection("processed_data")\
            .where("sessionId", "==", session_id)\
            .order_by("changed_at", direction=firestore.Query.ASCENDING)\
            .stream()
        
        # 데이터 수집
        stages_data = []
        for doc in processed_docs:
            data = doc.to_dict()
            stages_data.append(data)
            
            # user_id 추출 (파라미터로 안 넘어왔을 때)
            if not user_id:
                user_id = data.get("userId")
        
        if not stages_data:
            return {
                "error": "No data found",
                "session_id": session_id,
                "total_score": 0,
                "message": "데이터가 없습니다"
            }
        
        # 1. 수면 시간 계산
        first_ts = stages_data[0]["changed_at"]
        last_ts = stages_data[-1]["changed_at"]
        
        # Timestamp 변환
        if hasattr(first_ts, "to_datetime"):
            first_ts = first_ts.to_datetime()
        if hasattr(last_ts, "to_datetime"):
            last_ts = last_ts.to_datetime()
        
        total_duration_sec = (last_ts - first_ts).total_seconds()
        total_duration_hours = total_duration_sec / 3600
        
        # 2. 단계별 시간 계산
        stage_durations = {"Deep": 0, "Light": 0, "REM": 0, "Awake": 0, "Apnea": 0, "Snoring": 0}
        
        for i in range(len(stages_data) - 1):
            current = stages_data[i]
            next_item = stages_data[i + 1]
            
            current_ts = current["changed_at"]
            next_ts = next_item["changed_at"]
            
            if hasattr(current_ts, "to_datetime"):
                current_ts = current_ts.to_datetime()
            if hasattr(next_ts, "to_datetime"):
                next_ts = next_ts.to_datetime()
            
            duration = (next_ts - current_ts).total_seconds()
            stage = current.get("stage", "Unknown")
            
            if stage in stage_durations:
                stage_durations[stage] += duration
        
        # 3. 점수 계산
        
        # 3-1. 수면 시간 점수 (40점) - 7~9시간이 이상적
        if 7 <= total_duration_hours <= 9:
            duration_score = 40
        elif 6 <= total_duration_hours < 7:
            duration_score = 30
        elif 9 < total_duration_hours <= 10:
            duration_score = 35
        elif 5 <= total_duration_hours < 6:
            duration_score = 20
        else:
            duration_score = 10
        
        # 3-2. 깊은 수면 점수 (25점) - 전체의 15~25%가 이상적
        deep_ratio = stage_durations["Deep"] / total_duration_sec if total_duration_sec > 0 else 0
        if 0.15 <= deep_ratio <= 0.25:
            deep_score = 25
        elif 0.10 <= deep_ratio < 0.15:
            deep_score = 20
        elif 0.25 < deep_ratio <= 0.30:
            deep_score = 20
        else:
            deep_score = 10
        
        # 3-3. REM 수면 점수 (20점) - 전체의 20~25%가 이상적
        rem_ratio = stage_durations["REM"] / total_duration_sec if total_duration_sec > 0 else 0
        if 0.20 <= rem_ratio <= 0.25:
            rem_score = 20
        elif 0.15 <= rem_ratio < 0.20:
            rem_score = 15
        elif 0.25 < rem_ratio <= 0.30:
            rem_score = 15
        else:
            rem_score = 8
        
        # 3-4. 수면 효율 점수 (15점) - Awake 시간이 적을수록 좋음
        awake_ratio = stage_durations["Awake"] / total_duration_sec if total_duration_sec > 0 else 0
        if awake_ratio < 0.05:
            efficiency_score = 15
        elif awake_ratio < 0.10:
            efficiency_score = 12
        elif awake_ratio < 0.15:
            efficiency_score = 8
        else:
            efficiency_score = 3
        
        # 총점
        total_score = duration_score + deep_score + rem_score + efficiency_score
        
        # 4. 평가 메시지
        if total_score >= 90:
            message = "훌륭한 수면이었습니다! 🌟"
            grade = "S"
        elif total_score >= 80:
            message = "좋은 수면입니다 😊"
            grade = "A"
        elif total_score >= 70:
            message = "양호한 수면입니다 👍"
            grade = "B"
        elif total_score >= 60:
            message = "수면이 부족합니다 😐"
            grade = "C"
        else:
            message = "수면 개선이 필요합니다 ⚠️"
            grade = "D"
        
        # ✅ 5. 현재 시간 (ISO 문자열)
        current_time = now_utc()
        
        # ✅ 6. 결과 데이터 (반환용 - JSON 직렬화 가능)
        report_data = {
            "userId": user_id,
            "sessionId": session_id,
            "created_at": current_time.isoformat(),  # ✅ ISO 문자열
            
            # 점수
            "total_score": round(total_score),
            "grade": grade,
            "message": message,
            
            # 세부 점수
            "breakdown": {
                "duration_score": duration_score,
                "deep_score": deep_score,
                "rem_score": rem_score,
                "efficiency_score": efficiency_score
            },
            
            # 수면 요약
            "summary": {
                "total_duration_hours": round(total_duration_hours, 2),
                "deep_sleep_hours": round(stage_durations["Deep"] / 3600, 2),
                "rem_sleep_hours": round(stage_durations["REM"] / 3600, 2),
                "light_sleep_hours": round(stage_durations["Light"] / 3600, 2),
                "awake_hours": round(stage_durations["Awake"] / 3600, 2),
                
                "deep_ratio": round(deep_ratio * 100, 1),
                "rem_ratio": round(rem_ratio * 100, 1),
                "awake_ratio": round(awake_ratio * 100, 1),
                
                "apnea_count": sum(1 for s in stages_data if s.get("stage") == "Apnea"),
                "snoring_duration": round(stage_durations["Snoring"] / 60, 1)  # 분 단위
            }
        }
        
        # ✅ 7. Firestore에 저장 (SERVER_TIMESTAMP 사용)
        db.collection("sleep_reports").document(session_id).set({
            **report_data,
            "created_at": gcf.SERVER_TIMESTAMP  # Firestore용으로만
        })
        
        print(f"[수면 점수 계산 완료] session: {session_id}, score: {total_score}")
        
        # ✅ 8. 반환 (ISO 문자열 포함)
        return report_data
        
    except Exception as e:
        print(f"[수면 점수 계산 오류] {e}")
        raise https_fn.HttpsError("internal", f"Score calculation failed: {str(e)}")


# ========================================
# ✨ E단계: 주간 통계 계산
# ========================================

@https_fn.on_call()
def calculate_weekly_stats(req: https_fn.CallableRequest):
    """
    사용자의 주간 수면 통계 계산
    
    요청 파라미터:
    - user_id: 사용자 ID (필수)
    - week_start: 주 시작일 (선택, ISO 형식, 기본: 7일 전)
    
    반환:
    - 주간 평균 점수, 수면 시간, 트렌드 등
    """
    db = get_db()
    
    user_id = req.data.get("user_id")
    if not user_id:
        raise https_fn.HttpsError("invalid-argument", "user_id is required")
    
    # 주 시작일 파싱
    week_start_str = req.data.get("week_start")
    if week_start_str:
        try:
            week_start = datetime.fromisoformat(week_start_str).replace(tzinfo=timezone.utc)
        except:
            week_start = datetime.now(timezone.utc) - timedelta(days=7)
    else:
        week_start = datetime.now(timezone.utc) - timedelta(days=7)
    
    print(f"[주간 통계 계산] user: {user_id}, from: {week_start}")
    
    try:
        # 해당 기간의 리포트 조회
        reports = db.collection("sleep_reports")\
            .where("userId", "==", user_id)\
            .where("created_at", ">=", week_start)\
            .stream()
        
        report_list = [doc.to_dict() for doc in reports]
        
        if not report_list:
            return {
                "user_id": user_id,
                "week_start": week_start.isoformat(),
                "report_count": 0,
                "message": "데이터가 없습니다"
            }
        
        # 통계 계산
        total_scores = [r["total_score"] for r in report_list]
        sleep_hours = [r["summary"]["total_duration_hours"] for r in report_list]
        
        avg_score = sum(total_scores) / len(total_scores)
        avg_sleep = sum(sleep_hours) / len(sleep_hours)
        
        # 최고/최악일
        best_day = max(report_list, key=lambda x: x["total_score"])
        worst_day = min(report_list, key=lambda x: x["total_score"])
        
        # 트렌드 (간단 버전: 전반부 vs 후반부)
        mid = len(total_scores) // 2
        if mid > 0:
            first_half_avg = sum(total_scores[:mid]) / mid
            second_half_avg = sum(total_scores[mid:]) / (len(total_scores) - mid)
            
            if second_half_avg > first_half_avg + 5:
                trend = "improving"
            elif second_half_avg < first_half_avg - 5:
                trend = "declining"
            else:
                trend = "stable"
        else:
            trend = "insufficient_data"
        
        result = {
            "user_id": user_id,
            "week_start": week_start.isoformat(),
            "report_count": len(report_list),
            
            "averages": {
                "score": round(avg_score, 1),
                "sleep_hours": round(avg_sleep, 2)
            },
            
            "best_day": {
                "session_id": best_day["sessionId"],
                "score": best_day["total_score"],
                "sleep_hours": best_day["summary"]["total_duration_hours"]
            },
            
            "worst_day": {
                "session_id": worst_day["sessionId"],
                "score": worst_day["total_score"],
                "sleep_hours": worst_day["summary"]["total_duration_hours"]
            },
            
            "trend": trend
        }
        
        print(f"[주간 통계 완료] {len(report_list)}개 리포트, 평균 점수: {avg_score:.1f}")
        
        return result
        
    except Exception as e:
        print(f"[주간 통계 오류] {e}")
        raise https_fn.HttpsError("internal", f"Stats calculation failed: {str(e)}")
    
    # ========================================
# ✨ Phase 3: 인사이트 생성
# ========================================

@https_fn.on_call()
def generate_sleep_insights(req: https_fn.CallableRequest):
    """
    수면 리포트 기반 맞춤형 인사이트 및 개선 제안 생성
    
    요청 파라미터:
    - session_id: 세션 ID (필수)
    
    반환:
    - insights: 인사이트 목록 (우선순위 순)
    - overall: 종합 평가
    - action_plan: 실행 계획
    """
    db = get_db()
    
    session_id = req.data.get("session_id")
    if not session_id:
        raise https_fn.HttpsError("invalid-argument", "session_id is required")
    
    print(f"[인사이트 생성 시작] session: {session_id}")
    
    try:
        # 리포트 가져오기
        report_doc = db.collection("sleep_reports").document(session_id).get()
        
        if not report_doc.exists:
            raise https_fn.HttpsError("not-found", f"Report not found for session: {session_id}")
        
        report = report_doc.to_dict()
        
        # 인사이트 수집
        insights = []
        
        # 1. 수면 시간 분석
        sleep_hours = report["summary"]["total_duration_hours"]
        
        if sleep_hours < 5:
            insights.append({
                "type": "critical",
                "category": "duration",
                "title": "심각한 수면 부족",
                "message": f"현재 {sleep_hours:.1f}시간으로 건강에 위험할 수 있어요",
                "priority": 1,
                "impact": "건강, 집중력, 면역력",
                "actions": [
                    "오늘 밤 최소 7시간 수면 목표 설정",
                    "취침 시간 2시간 앞당기기",
                    "낮잠 20분 이내로 제한"
                ]
            })
        elif sleep_hours < 6:
            insights.append({
                "type": "warning",
                "category": "duration",
                "title": "수면 시간 부족",
                "message": f"현재 {sleep_hours:.1f}시간으로 권장(7-9시간)보다 부족해요",
                "priority": 2,
                "impact": "피로 누적, 업무 효율 저하",
                "actions": [
                    "취침 시간을 1시간 앞당기기",
                    "기상 알람 30분 늦추기",
                    "주말에 보충 수면"
                ]
            })
        elif sleep_hours > 10:
            insights.append({
                "type": "info",
                "category": "duration",
                "title": "과도한 수면",
                "message": f"{sleep_hours:.1f}시간은 권장(7-9시간)보다 많아요",
                "priority": 3,
                "impact": "낮 동안 졸림, 운동 부족",
                "actions": [
                    "규칙적인 기상 시간 설정",
                    "낮 활동량 늘리기",
                    "카페인 섭취 줄이기"
                ]
            })
        
        # 2. 깊은 수면 분석
        deep_ratio = report["summary"]["deep_ratio"]
        deep_hours = report["summary"]["deep_sleep_hours"]
        
        if deep_ratio < 5:
            insights.append({
                "type": "critical",
                "category": "quality",
                "title": "깊은 수면 심각 부족",
                "message": f"깊은 수면이 {deep_ratio:.1f}%로 매우 부족해요 (권장: 15-25%)",
                "priority": 1,
                "impact": "회복력, 성장호르몬, 면역력",
                "actions": [
                    "저녁 6시 이후 카페인 금지",
                    "오후 3-5시에 30분 유산소 운동",
                    "취침 2시간 전 따뜻한 샤워",
                    "침실 온도 18-20도 유지"
                ]
            })
        elif deep_ratio < 10:
            insights.append({
                "type": "warning",
                "category": "quality",
                "title": "깊은 수면 부족",
                "message": f"깊은 수면이 {deep_ratio:.1f}% ({deep_hours:.1f}시간)로 부족해요",
                "priority": 2,
                "impact": "피로 회복, 기억력",
                "actions": [
                    "낮에 20-30분 가벼운 운동",
                    "저녁 식사 취침 3시간 전",
                    "취침 전 스트레칭 10분"
                ]
            })
        
        # 3. REM 수면 분석
        rem_ratio = report["summary"]["rem_ratio"]
        rem_hours = report["summary"]["rem_sleep_hours"]
        
        if rem_ratio < 10:
            insights.append({
                "type": "warning",
                "category": "quality",
                "title": "REM 수면 부족",
                "message": f"REM 수면이 {rem_ratio:.1f}% ({rem_hours:.1f}시간)로 부족해요 (권장: 20-25%)",
                "priority": 2,
                "impact": "학습, 기억력, 감정 조절",
                "actions": [
                    "규칙적인 수면 스케줄 유지",
                    "알코올 섭취 줄이기",
                    "충분한 총 수면 시간 확보"
                ]
            })
        
        # 4. 수면 효율 분석
        awake_ratio = report["summary"]["awake_ratio"]
        awake_hours = report["summary"]["awake_hours"]
        
        if awake_ratio > 20:
            insights.append({
                "type": "warning",
                "category": "efficiency",
                "title": "수면 효율 매우 낮음",
                "message": f"수면 중 {awake_ratio:.1f}% ({awake_hours:.1f}시간) 깨어있었어요",
                "priority": 2,
                "impact": "수면의 질, 낮 피로",
                "actions": [
                    "침실을 완전히 어둡게",
                    "소음 차단 (귀마개 사용)",
                    "취침 1시간 전 스마트폰/TV 끄기",
                    "침대는 수면용으로만 사용"
                ]
            })
        elif awake_ratio > 10:
            insights.append({
                "type": "info",
                "category": "efficiency",
                "title": "수면 효율 개선 필요",
                "message": f"수면 중 {awake_ratio:.1f}% 깨어있었어요 (권장: 5% 이하)",
                "priority": 3,
                "impact": "수면의 질",
                "actions": [
                    "취침 환경 점검 (온도, 소음, 빛)",
                    "규칙적인 취침 루틴 만들기"
                ]
            })
        
        # 5. 무호흡 경고
        apnea_count = report["summary"]["apnea_count"]
        
        if apnea_count > 15:
            insights.append({
                "type": "critical",
                "category": "health",
                "title": "⚠️ 수면 무호흡 위험",
                "message": f"수면 중 {apnea_count}회 무호흡이 감지됐어요",
                "priority": 1,
                "impact": "심혈관 건강, 뇌 산소 공급",
                "actions": [
                    "즉시 수면 전문의 상담 예약",
                    "수면다원검사 권장",
                    "당분간 옆으로 자기"
                ]
            })
        elif apnea_count > 5:
            insights.append({
                "type": "warning",
                "category": "health",
                "title": "무호흡 감지",
                "message": f"수면 중 {apnea_count}회 무호흡이 감지됐어요",
                "priority": 2,
                "impact": "수면의 질, 피로",
                "actions": [
                    "체중 관리 (BMI 정상 범위)",
                    "금연 및 음주 제한",
                    "옆으로 자는 습관 들이기",
                    "2주 후에도 지속되면 병원 상담"
                ]
            })
        
        # 6. 코골이 분석
        snoring_duration = report["summary"]["snoring_duration"]
        
        if snoring_duration > 60:
            insights.append({
                "type": "warning",
                "category": "health",
                "title": "심한 코골이 감지",
                "message": f"수면 중 {snoring_duration:.0f}분 동안 코를 골았어요",
                "priority": 2,
                "impact": "수면의 질, 주변 사람",
                "actions": [
                    "옆으로 자기 (등 받침 베개 사용)",
                    "비강 확장 스트립 사용",
                    "체중 감량 (과체중인 경우)",
                    "알코올 섭취 줄이기"
                ]
            })
        elif snoring_duration > 30:
            insights.append({
                "type": "info",
                "category": "health",
                "title": "코골이 감지",
                "message": f"수면 중 {snoring_duration:.0f}분 동안 코를 골았어요",
                "priority": 3,
                "impact": "수면의 질",
                "actions": [
                    "옆으로 자는 습관",
                    "베개 높이 조절"
                ]
            })
        
        # 우선순위 순으로 정렬
        insights.sort(key=lambda x: x["priority"])
        
        # 7. 종합 평가
        score = report["total_score"]
        
        if score >= 90:
            overall = {
                "grade": "S",
                "message": "완벽한 수면입니다! 🌟",
                "summary": "모든 지표가 이상적입니다. 현재 수면 습관을 꾸준히 유지하세요.",
                "emoji": "🌟"
            }
        elif score >= 80:
            overall = {
                "grade": "A",
                "message": "좋은 수면입니다 😊",
                "summary": "대부분의 지표가 양호합니다. 몇 가지만 개선하면 완벽해질 수 있어요.",
                "emoji": "😊"
            }
        elif score >= 70:
            overall = {
                "grade": "B",
                "message": "양호한 수면입니다 👍",
                "summary": "기본은 갖췄지만 개선할 부분이 있어요. 아래 조언을 참고하세요.",
                "emoji": "👍"
            }
        elif score >= 60:
            overall = {
                "grade": "C",
                "message": "수면 개선이 필요합니다 😐",
                "summary": "여러 지표에서 개선이 필요해요. 우선순위가 높은 것부터 실천하세요.",
                "emoji": "😐"
            }
        else:
            overall = {
                "grade": "D",
                "message": "수면에 적극적인 관리가 필요합니다 ⚠️",
                "summary": "건강에 영향을 줄 수 있는 심각한 문제들이 있어요. 즉시 개선이 필요합니다.",
                "emoji": "⚠️"
            }
        
        # 8. 오늘의 실행 계획 (우선순위 Top 3)
        action_plan = {
            "today": [],
            "this_week": [],
            "long_term": []
        }
        
        # 우선순위 1 (critical) - 오늘 당장
        critical_insights = [i for i in insights if i["type"] == "critical"]
        for insight in critical_insights[:2]:  # 최대 2개
            action_plan["today"].extend(insight["actions"][:2])
        
        # 우선순위 2 (warning) - 이번 주
        warning_insights = [i for i in insights if i["type"] == "warning"]
        for insight in warning_insights[:2]:  # 최대 2개
            action_plan["this_week"].extend(insight["actions"][:1])
        
        # 우선순위 3 (info) - 장기
        info_insights = [i for i in insights if i["type"] == "info"]
        for insight in info_insights[:1]:  # 최대 1개
            action_plan["long_term"].extend(insight["actions"][:1])
        
        result = {
            "session_id": session_id,
            "score": score,
            "overall": overall,
            "insights": insights,
            "insights_count": len(insights),
            "action_plan": action_plan,
            "generated_at": now_utc().isoformat()
        }
        
        # Firestore에 저장
        db.collection("sleep_insights").document(session_id).set(result)
        
        print(f"[인사이트 생성 완료] session: {session_id}, insights: {len(insights)}")
        
        return result
        
    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"[인사이트 생성 오류] {e}")
        raise https_fn.HttpsError("internal", f"Insights generation failed: {str(e)}")
    
# ========================================
# ✨ Phase 4: 월간 트렌드 분석
# ========================================

@https_fn.on_call()
def calculate_monthly_trends(req: https_fn.CallableRequest):
    """
    최근 30일 수면 패턴 및 트렌드 분석
    
    요청 파라미터:
    - user_id: 사용자 ID (필수)
    - days: 분석 기간 (선택, 기본: 30)
    
    반환:
    - 월간 평균 통계
    - 주중/주말 비교
    - 요일별 분석
    - 개선 추세
    """
    db = get_db()
    
    user_id = req.data.get("user_id")
    if not user_id:
        raise https_fn.HttpsError("invalid-argument", "user_id is required")
    
    days = req.data.get("days", 30)
    start_date = datetime.now(timezone.utc) - timedelta(days=days)
    
    print(f"[월간 트렌드 분석] user: {user_id}, days: {days}")
    
    try:
        # 기간 내 리포트 조회
        reports = db.collection("sleep_reports")\
            .where("userId", "==", user_id)\
            .where("created_at", ">=", start_date)\
            .stream()
        
        report_list = []
        for doc in reports:
            data = doc.to_dict()
            # created_at을 datetime으로 변환
            created_at = data.get("created_at")
            if hasattr(created_at, "to_datetime"):
                created_at = created_at.to_datetime()
            elif isinstance(created_at, str):
                created_at = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
            data["created_at_dt"] = created_at
            report_list.append(data)
        
        if not report_list:
            return {
                "user_id": user_id,
                "period_days": days,
                "report_count": 0,
                "message": "데이터가 없습니다"
            }
        
        # 1. 전체 평균
        total_scores = [r["total_score"] for r in report_list]
        sleep_hours = [r["summary"]["total_duration_hours"] for r in report_list]
        deep_ratios = [r["summary"]["deep_ratio"] for r in report_list]
        rem_ratios = [r["summary"]["rem_ratio"] for r in report_list]
        
        overall_avg = {
            "score": round(sum(total_scores) / len(total_scores), 1),
            "sleep_hours": round(sum(sleep_hours) / len(sleep_hours), 2),
            "deep_ratio": round(sum(deep_ratios) / len(deep_ratios), 1),
            "rem_ratio": round(sum(rem_ratios) / len(rem_ratios), 1)
        }
        
        # 2. 주중/주말 비교
        weekday_reports = []
        weekend_reports = []
        
        for report in report_list:
            dt = report["created_at_dt"]
            if dt.weekday() < 5:  # 0=월, 4=금
                weekday_reports.append(report)
            else:  # 5=토, 6=일
                weekend_reports.append(report)
        
        weekday_vs_weekend = {}
        
        if weekday_reports:
            weekday_scores = [r["total_score"] for r in weekday_reports]
            weekday_hours = [r["summary"]["total_duration_hours"] for r in weekday_reports]
            weekday_vs_weekend["weekday"] = {
                "count": len(weekday_reports),
                "avg_score": round(sum(weekday_scores) / len(weekday_scores), 1),
                "avg_hours": round(sum(weekday_hours) / len(weekday_hours), 2)
            }
        
        if weekend_reports:
            weekend_scores = [r["total_score"] for r in weekend_reports]
            weekend_hours = [r["summary"]["total_duration_hours"] for r in weekend_reports]
            weekday_vs_weekend["weekend"] = {
                "count": len(weekend_reports),
                "avg_score": round(sum(weekend_scores) / len(weekend_scores), 1),
                "avg_hours": round(sum(weekend_hours) / len(weekend_hours), 2)
            }
        
        # 3. 요일별 분석
        weekday_names = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"]
        by_weekday = {}
        
        for i in range(7):
            day_reports = [r for r in report_list if r["created_at_dt"].weekday() == i]
            if day_reports:
                day_scores = [r["total_score"] for r in day_reports]
                day_hours = [r["summary"]["total_duration_hours"] for r in day_reports]
                by_weekday[weekday_names[i]] = {
                    "count": len(day_reports),
                    "avg_score": round(sum(day_scores) / len(day_scores), 1),
                    "avg_hours": round(sum(day_hours) / len(day_hours), 2)
                }
        
        # 4. 주별 트렌드 (최근 4주)
        weekly_trends = []
        for week in range(4):
            week_start = datetime.now(timezone.utc) - timedelta(days=(week+1)*7)
            week_end = datetime.now(timezone.utc) - timedelta(days=week*7)
            
            week_reports = [
                r for r in report_list 
                if week_start <= r["created_at_dt"] < week_end
            ]
            
            if week_reports:
                week_scores = [r["total_score"] for r in week_reports]
                weekly_trends.insert(0, {
                    "week": f"{week+1}주 전",
                    "avg_score": round(sum(week_scores) / len(week_scores), 1),
                    "count": len(week_reports)
                })
        
        # 5. 개선 추세 계산
        if len(weekly_trends) >= 2:
            first_week_score = weekly_trends[0]["avg_score"]
            last_week_score = weekly_trends[-1]["avg_score"]
            score_change = last_week_score - first_week_score
            
            if score_change > 5:
                trend = "improving"
                trend_message = f"지난 4주간 {score_change:.1f}점 개선됐어요! 📈"
            elif score_change < -5:
                trend = "declining"
                trend_message = f"지난 4주간 {abs(score_change):.1f}점 하락했어요 📉"
            else:
                trend = "stable"
                trend_message = "지난 4주간 안정적입니다 ➡️"
        else:
            trend = "insufficient_data"
            trend_message = "트렌드 분석을 위한 데이터가 부족해요"
        
        # 6. 인사이트
        insights = []
        
        # 주중/주말 비교
        if "weekday" in weekday_vs_weekend and "weekend" in weekday_vs_weekend:
            weekday_score = weekday_vs_weekend["weekday"]["avg_score"]
            weekend_score = weekday_vs_weekend["weekend"]["avg_score"]
            score_diff = weekend_score - weekday_score
            
            if score_diff > 10:
                insights.append({
                    "type": "info",
                    "message": f"주말 수면이 주중보다 {score_diff:.0f}점 더 좋아요",
                    "suggestion": "주중 수면 습관을 주말처럼 유지해보세요"
                })
            elif score_diff < -10:
                insights.append({
                    "type": "warning",
                    "message": f"주말 수면이 주중보다 {abs(score_diff):.0f}점 낮아요",
                    "suggestion": "주말에도 규칙적인 수면 시간을 유지하세요"
                })
        
        # 요일별 패턴
        if by_weekday:
            best_day = max(by_weekday.items(), key=lambda x: x[1]["avg_score"])
            worst_day = min(by_weekday.items(), key=lambda x: x[1]["avg_score"])
            
            insights.append({
                "type": "info",
                "message": f"{best_day[0]}이 가장 좋아요 ({best_day[1]['avg_score']}점)",
                "suggestion": f"{best_day[0]}의 습관을 다른 요일에도 적용해보세요"
            })
            
            if worst_day[1]["avg_score"] < 60:
                insights.append({
                    "type": "warning",
                    "message": f"{worst_day[0]}이 가장 나빠요 ({worst_day[1]['avg_score']}점)",
                    "suggestion": f"{worst_day[0]} 전날 특별히 주의하세요"
                })
        
        result = {
            "user_id": user_id,
            "period_days": days,
            "report_count": len(report_list),
            "date_range": {
                "start": start_date.isoformat(),
                "end": datetime.now(timezone.utc).isoformat()
            },
            
            "overall_average": overall_avg,
            "weekday_vs_weekend": weekday_vs_weekend,
            "by_weekday": by_weekday,
            "weekly_trends": weekly_trends,
            
            "trend": trend,
            "trend_message": trend_message,
            "insights": insights
        }
        
        print(f"[월간 트렌드 완료] {len(report_list)}개 리포트, 평균: {overall_avg['score']:.1f}점")
        
        return result
        
    except Exception as e:
        print(f"[월간 트렌드 오류] {e}")
        raise https_fn.HttpsError("internal", f"Trends calculation failed: {str(e)}")


# ========================================
# ✨ Phase 5: 자동 리포트 생성
# ========================================

@https_fn.on_call()
def auto_generate_report(req: https_fn.CallableRequest):
    """
    세션 종료 시 자동으로 리포트 생성
    
    요청 파라미터:
    - user_id: 사용자 ID (필수)
    - session_id: 세션 ID (필수)
    
    반환:
    - 수면 점수
    - 인사이트
    """
    db = get_db()
    
    user_id = req.data.get("user_id")
    session_id = req.data.get("session_id")
    
    if not user_id or not session_id:
        raise https_fn.HttpsError("invalid-argument", "user_id and session_id are required")
    
    print(f"[자동 리포트 생성] user: {user_id}, session: {session_id}")
    
    try:
        # 1. 수면 점수 계산
        score_result = calculate_sleep_score.call({"data": {"session_id": session_id}})
        
        # 2. 인사이트 생성
        insights_result = generate_sleep_insights.call({"data": {"session_id": session_id}})
        
        # 3. 통합 결과
        result = {
            "user_id": user_id,
            "session_id": session_id,
            "score": score_result,
            "insights": insights_result,
            "generated_at": now_utc().isoformat(),
            "auto_generated": True
        }
        
        print(f"[자동 리포트 완료] session: {session_id}, score: {score_result.get('total_score')}")
        
        return result
        
    except Exception as e:
        print(f"[자동 리포트 오류] {e}")
        raise https_fn.HttpsError("internal", f"Auto report generation failed: {str(e)}")


# ========================================
# ✨ Phase 5: 세션 종료 감지 (트리거)
# ========================================

@firestore_fn.on_document_updated(document="session_state/{stateId}", region="asia-northeast3")
def on_session_end(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot | None]]):
    """
    세션 상태 변경 감지 → 종료 시 자동 리포트 생성
    """
    db = get_db()
    
    if event.data is None:
        return
    
    before = event.data.before
    after = event.data.after
    
    if before is None or after is None:
        return
    
    before_data = before.to_dict() or {}
    after_data = after.to_dict() or {}
    
    # 세션이 활성 → 종료로 변경되었는지 확인
    # (예: stage가 "Awake"가 30분 이상 지속되면 종료로 간주)
    
    before_stage = before_data.get("stage")
    after_stage = after_data.get("stage")
    
    # 예시: Awake 상태로 변경되고 충분한 시간이 지났다면
    if after_stage == "Awake":
        last_change = after_data.get("last_change_ts")
        if hasattr(last_change, "to_datetime"):
            last_change = last_change.to_datetime()
        
        now = now_utc()
        
        # 30분 이상 Awake 상태면 세션 종료로 간주
        if last_change and (now - last_change).total_seconds() > 1800:  # 30분
            user_id = after_data.get("userId")
            session_id = after_data.get("sessionId")
            
            # 이미 리포트가 생성되었는지 확인
            report_exists = db.collection("sleep_reports").document(session_id).get().exists
            
            if not report_exists:
                print(f"[세션 종료 감지] user: {user_id}, session: {session_id}")
                
                try:
                    # 자동 리포트 생성 (내부 호출)
                    # 실제로는 Cloud Tasks로 비동기 처리하는 게 좋음
                    print(f"[자동 리포트 트리거] session: {session_id}")
                    # 여기서는 로그만 남기고, 실제 생성은 프론트엔드가 호출하도록
                    
                except Exception as e:
                    print(f"[자동 리포트 트리거 오류] {e}")
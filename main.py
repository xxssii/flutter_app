# main.py
# requirements.txt:
# google-cloud-firestore==2.17.3
# cloudevents==1.11.0
# functions-framework==3.5.0

from datetime import datetime, timezone
import hashlib, json

from cloudevents.http import CloudEvent
import functions_framework
from google.cloud import firestore

db = firestore.Client()

# === 안정화 파라미터 ===
DEFAULT_MIN_STAGE_DURATION_SEC = 30  # 기본 30초 (v2에서 단계별로 다르게 줄 수 있음)

def now_utc():
    return datetime.now(timezone.utc)

# === (1) 의사결정트리 규칙 이식부 ===
# [수정 완료] 1단계 데이터 프로필 기반의 "스타터 뇌"를 여기에 이식했습니다.
# (나중에 JupyterLab을 설치하면 이 함수만 교체하면 됩니다)
def predict_stage_by_tree(hr: float, motion: float, pressure: float) -> str:
    # auto-generated from 4-class starter profiles (Awake/Light/Deep/REM)
    
    # 이 로직은 1단계에서 정의한 데이터 프로필을 기반으로 합니다.
    # (예: Awake는 motion이 45~75, Light는 12~25...)
    
    if motion <= 11.5:
        # motion이 11.5 이하 (Deep 또는 REM 후보)
        if motion <= 5.5:
            # motion이 5.5 이하 (Deep)
            return "Deep"
        else:
            # motion이 5.5 ~ 11.5 (REM)
            return "REM"
    else:
        # motion이 11.5 초과 (Light 또는 Awake 후보)
        if motion <= 35.0:
            # motion이 11.5 ~ 35.0 (Light)
            return "Light"
        else:
            # motion이 35.0 초과 (Awake)
            return "Awake"
# === (1) 끝 ===

def stage_confidence(stage: str) -> float:
    # 간단 매핑(원하면 조정)
    return {"Deep": 0.78, "REM": 0.72, "Light": 0.65, "Awake": 0.60}.get(stage, 0.55)

def min_duration_sec_for(prev_stable_stage: str | None) -> int:
    # v1: 모두 30초. v2에서 단계별 차등 적용하려면 아래 주석 해제/조정
    return DEFAULT_MIN_STAGE_DURATION_SEC
    # if prev_stable_stage == "Deep": return 60
    # if prev_stable_stage == "Awake": return 60
    # if prev_stable_stage == "Light": return 20
    # return 30

# === (2) Firestore CloudEvent 유틸 ===
# Firestore 이벤트 페이로드를 파싱하는 헬퍼 함수들
def _num(field_obj):
    return float(field_obj.get("doubleValue") or field_obj.get("integerValue") or 0.0)

def _str(field_obj):
    return field_obj.get("stringValue") or ""

def _ts(field_obj):
    v = field_obj.get("timestampValue")
    if not v:
        return None
    # e.g. "2025-10-25T06:05:01.123Z"
    return datetime.fromisoformat(v.replace("Z", "+00:00")).astimezone(timezone.utc)

# === (3) 명령 정책 (안정화된 단계에만 적용) ===
def command_policy(stage: str) -> dict | None:
    if stage == "Awake":
        return {"type": "VIBRATE", "payload": {"intensity": 30, "durationMs": 500}, "ttlSec": 8}
    if stage == "Light":
        return {"type": "SET_HEIGHT", "payload": {"heightMm": 45}, "ttlSec": 10}
    if stage == "Deep":
        return {"type": "SET_HEIGHT", "payload": {"heightMm": 55}, "ttlSec": 10}
    return None  # REM: 명령 없음

# === (4) 세션 상태 트랜잭션 (콜드스타트 포함) ===
@firestore.transactional
def _update_session_state(
    tx: firestore.Transaction,
    state_ref: firestore.DocumentReference,
    *,
    user_id: str,
    session_id: str,
    raw_stage: str,
    source_ts: datetime,
    now: datetime,
):
    snap = tx.get(state_ref)
    if not snap.exists:
        # Cold start: 세션의 첫 데이터 → 곧바로 확정(전이로 간주)
        new_state = {
            "userId": user_id,
            "sessionId": session_id,
            "stage": raw_stage,          # 안정화된 최종 단계
            "raw_stage": raw_stage,      # 마지막 날것
            "last_change_ts": now,       # 안정화 단계 시작 시각
            "updated_at": now,           # 마지막 하트비트
            "last_source_ts": source_ts, # 원본 데이터 시각(디버깅용)
        }
        tx.set(state_ref, new_state)
        return True, raw_stage, now  # (전이 발생, 안정화 단계, 변경 시각)

    st = snap.to_dict()
    stable_stage = st.get("stage")
    last_change_ts = st.get("last_change_ts")
    # Firestore가 문자열로 들어오는 경우 방어
    if isinstance(last_change_ts, str):
        last_change_ts = datetime.fromisoformat(last_change_ts)

    # 최솟지속시간(단계별 차등 적용 가능)
    min_needed = min_duration_sec_for(stable_stage)

    if raw_stage == stable_stage:
        # 변화 없음: 하트비트만 갱신
        tx.update(state_ref, {
            "raw_stage": raw_stage,
            "updated_at": now,
            "last_source_ts": source_ts,
        })
        return False, stable_stage, last_change_ts

    # 변화 후보: 경과시간 체크
    elapsed = (now - last_change_ts).total_seconds() if last_change_ts else 10**9
    if elapsed >= min_needed:
        # 전이 승인
        tx.update(state_ref, {
            "stage": raw_stage,
            "raw_stage": raw_stage,
            "last_change_ts": now,
            "updated_at": now,
            "last_source_ts": source_ts,
        })
        return True, raw_stage, now
    else:
        # 깜빡임 → 유지 + 하트비트
        tx.update(state_ref, {
            "raw_stage": raw_stage,
            "updated_at": now,
            "last_source_ts": source_ts,
        })
        return False, stable_stage, last_change_ts

# === (5) 엔트리포인트: raw_data 트리거 ===
# 이 함수가 raw_data 컬렉션에 새 문서가 생길 때마다 실행됩니다.
@functions_framework.cloud_event
def on_raw_data_write(event: CloudEvent):
    # subject 예: projects/.../documents/raw_data/{docId}
    data = event.data or {}
    val = data.get("value", {})
    fields = val.get("fields", {})
    if not fields:
        print("이벤트 데이터에 'fields'가 없어 스킵합니다.")
        return "skip"

    # 1. 이벤트 데이터 파싱
    try:
        hr        = _num(fields.get("hr", {}))
        motion    = _num(fields.get("motion", {}))
        pressure  = _num(fields.get("pressure", {}))
        user_id   = _str(fields.get("userId", {})) or "demoUser"
        session_id= _str(fields.get("sessionId", {})) or "demoSession"
        source_ts = _ts(fields.get("ts", {})) or now_utc()
    except Exception as e:
        print(f"데이터 파싱 중 오류 발생: {e}, data: {fields}")
        return "error"

    # 2) '스타터 뇌'로 날것 예측
    raw_stage = predict_stage_by_tree(hr, motion, pressure)

    # 3) 세션 상태 문서(단일) 갱신 (트랜잭션)
    now = now_utc()
    state_ref = db.collection("session_state").document(f"{user_id}__{session_id}")
    try:
        stage_changed, stable_stage, changed_at = _update_session_state(
            db.transaction(), state_ref,
            user_id=user_id, session_id=session_id,
            raw_stage=raw_stage, source_ts=source_ts, now=now,
        )
    except Exception as e:
        print(f"트랜잭션 실패: {e}")
        return "error"

    # 4) 전이 승인 시에만 로그/명령 생성
    if stage_changed:
        try:
            # processed_data: "전이 이벤트"만 기록
            db.collection("processed_data").add({
                "userId": user_id,
                "sessionId": session_id,
                "stage": stable_stage,                 # 안정화 결과
                "raw_stage": raw_stage,                # 전이 시점의 날것
                "confidence": stage_confidence(stable_stage),
                "ts": firestore.SERVER_TIMESTAMP,      # 기록 시간
                "changed_at": changed_at,              # 안정 단계 시작 시각
                "source_ts": source_ts,                # 원본 데이터 시간
            })

            # commands: 정책에 따라 1회 생성(멱등키)
            policy = command_policy(stable_stage)
            if policy:
                core = json.dumps({
                    "u": user_id, "s": session_id, "stg": stable_stage,
                    "t": int(changed_at.timestamp()),
                }, sort_keys=True).encode()
                dkey = hashlib.sha1(core).hexdigest()[:12]
                cmd_ref = db.collection("commands").document(dkey)
                
                # 멱등성 보장: 이미 이 명령이 생성되지 않았을 때만 생성
                if not cmd_ref.get().exists:
                    cmd_ref.set({
                        "userId": user_id,
                        "sessionId": session_id,
                        "type": policy["type"],
                        "payload": policy["payload"],
                        "status": "PENDING",
                        "ttlSec": policy["ttlSec"],
                        "ts": firestore.SERVER_TIMESTAMP,
                        "dedupKey": dkey,
                    })
        except Exception as e:
            print(f"로그 또는 커맨드 생성 실패: {e}")
            return "error"

    return "ok"

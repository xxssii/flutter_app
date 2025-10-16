# 이 함수는 센서 데이터(딕셔너리 형태)를 입력받아 수면 단계를 반환합니다.
def analyze_sleep_stage(sensor_data):
    # 데이터에서 심박수와 압력 값을 가져옵니다. 값이 없으면 기본값 0을 사용합니다.
    heart_rate = sensor_data.get('heart_rate', 0)
    pressure = sensor_data.get('pressure', 0)

    print(f"--- 분석 시작: 심박수={heart_rate}, 압력={pressure} ---")

    # [여기에 당신만의 분석 규칙을 추가/수정해 보세요]
    # 예시: 매우 단순한 규칙
    if heart_rate < 60 and pressure < 15:
        stage = '깊은 수면 (Deep Sleep)'
    elif heart_rate < 75:
        stage = '얕은 수면 (Light Sleep)'
    else:
        stage = '깨어있음 (Awake)'

    print(f"--- 분석 결과: {stage} ---")
    return stage

# 이 파일("main.py")을 직접 실행했을 때만 아래 코드가 작동합니다. (테스트용)
if __name__ == '__main__':
    print("로컬에서 Python 함수를 테스트합니다.")

    # Firestore에 저장된 것과 유사한 가짜 데이터를 만듭니다.
    fake_sensor_data_1 = {'heart_rate': 58, 'pressure': 12.0}
    analyze_sleep_stage(fake_sensor_data_1)

    print("-" * 20)

    fake_sensor_data_2 = {'heart_rate': 72, 'pressure': 30.0}
    analyze_sleep_stage(fake_sensor_data_2)
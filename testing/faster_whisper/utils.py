import os
import json
import re
import subprocess
import requests
import time

import soundfile as sf
import scipy.signal as signal
import numpy as np

from datetime import datetime
from scipy.io import wavfile
from math import gcd

from config import *


def log(msg: str, level: str = "INFO"):
    timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    color = {
        "INFO": "36",  # Cyan
        "STT": "32",  # Green
        "TTS": "35",  # Magenta
        "RASA": "33",  # Yellow
        "ERROR": "31",  # Red
        "AUDIO": "34",  # Blue
    }.get(level, "37")
    print(f"\033[{color}m[{timestamp}] {level:5} | {msg}\033[0m")


def resample(data: np.ndarray, sr_from: int, sr_to: int) -> np.ndarray:
    """Resample chính xác bằng resample_poly, rút gọn tỉ lệ up/down theo GCD
    (vd 8000→48000 dùng up=6/down=1 thay vì up=48000/down=8000)."""
    if sr_from == sr_to or len(data) == 0:
        return data.astype(np.float32)
    g = gcd(sr_from, sr_to)
    up, down = sr_to // g, sr_from // g
    return signal.resample_poly(data, up=up, down=down).astype(np.float32)


def run_rasa():
    subprocess.Popen(
        'start "Rasa API" cmd /k "cd /d D:\\softphone\\rasa && call .venv_rasa\\Scripts\\activate && rasa run --enable-api --cors \\"*\\" -vv"',
        shell=True,
    )
    subprocess.Popen(
        'start "Rasa Actions" cmd /k "cd /d D:\\softphone\\rasa && call .venv_rasa\\Scripts\\activate && rasa run actions -vv"',
        shell=True,
    )

    start_time = time.time()
    while time.time() - start_time < 180:
        try:
            response = requests.get(f"{RASA_BASE_URL}/", timeout=3)  # ← đổi ở đây
            if response.status_code == 200:
                rasa_test_session = requests.Session()
                start = time.perf_counter()
                payload = {"sender": "ăáàạảã", "message": "xin chào"}

                res_post = rasa_test_session.post(RASA_URL, json=payload, timeout=8)
                if res_post.status_code == 200:
                    response_data = res_post.json()

                    rasa_text = ""
                    for msg in response_data:
                        if "text" in msg:
                            rasa_text += msg["text"] + " "

                    log(f"  ↳ response: {rasa_text.strip()[:100]}", "RASA")
                    log(f"Rasa: xử lý={time.perf_counter()-start:.2f}s", "RASA")
                    print("Rasa API đã sẵn sàng!")

                break

        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
            pass

        time.sleep(2)
    else:
        print("Cảnh báo: Quá thời gian chờ Rasa API khởi động!")


def save_turn_result(
    turn_id: str,
    client_addr,
    input_audio: np.ndarray,
    transcript: str,
    state: str,
    rasa_text: str,
    wav_bytes: bytes,
    total_time: float,
):
    try:
        os.makedirs(SAVE_DIR, exist_ok=True)

        input_wav_path = os.path.join(SAVE_DIR, f"{turn_id}_input.wav")
        wavfile.write(input_wav_path, TARGET_SR, input_audio)

        output_wav_path = os.path.join(SAVE_DIR, f"{turn_id}_output.wav")
        with open(output_wav_path, "wb") as f:
            f.write(wav_bytes)

        record = {
            "turn_id": turn_id,
            "timestamp": datetime.now().isoformat(timespec="milliseconds"),
            "client": str(client_addr),
            "stt_text": transcript,
            "rasa_state": state,
            "rasa_text": rasa_text,
            "input_wav": input_wav_path,
            "output_wav": output_wav_path,
            "total_time_s": round(total_time, 2),
        }
        log_path = os.path.join(SAVE_DIR, "turns.txt")
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except Exception as e:
        log(f"Lỗi lưu turn result: {e}", "ERROR")


def clean_text(text):
    """
    Xóa dấu câu và từ vô nghĩa (stop words) khỏi văn bản.
    """
    # Đảm bảo đầu vào là kiểu chuỗi, tránh lỗi nếu gặp None hoặc kiểu dữ liệu khác
    if not isinstance(text, str):
        return ""

    vn_nonsense = {"àm", "ừm", "ờ", "unk"}  # Dùng set thay vì list để tra cứu nhanh hơn

    # 1. Chuyển về chữ thường
    text = text.lower()

    # 2. Xóa dấu câu bằng Regex
    # Sử dụng space thay vì chuỗi rỗng giúp tránh trường hợp dính từ (ví dụ: 'hello,world' -> 'hello world' thay vì 'helloworld')
    text = re.sub(r"[^\w\s]", " ", text)

    # 3. Chia nhỏ văn bản và lọc
    words = text.split()

    # 4. Lọc các từ vô nghĩa (dùng set giúp tốc độ xử lý nhanh hơn với dữ liệu lớn)
    cleaned_words = [word for word in words if word not in vn_nonsense]

    # 5. Kết nối lại
    return " ".join(cleaned_words)

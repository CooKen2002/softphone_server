import os
import subprocess
import requests
import time

import soundfile as sf

from datetime import datetime
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

def run_rasa():
    rasa_test_session = requests.Session()
    payload = {"sender": SENDER_ID, "message": "xin chào"}
    res_post = rasa_test_session.post(RASA_URL, json=payload, timeout=8)
    if res_post.status_code == 200:
        pass
    else:
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
                    start = time.perf_counter()
                    if res_post == 200:
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

def save_audio_result(audio_array, process: str, sr=16000, folder="./result"):
    # Đảm bảo thư mục tồn tại
    if not os.path.exists(folder):
        os.makedirs(folder)

    filename = f"{folder}/{process}_{datetime.now().strftime('%H-%M-%S')}.wav"

    # Lưu file (audio_array phải là float32 hoặc int16)
    # sr=8000 là sample rate bạn đã chọn
    sf.write(filename, audio_array, sr)
    return filename


def save_text_rasa(text1: str, text2: str, filename: str, folder: str = "./result"):
    """Lưu văn bản vào file, tự động tạo thư mục nếu chưa có."""
    if not os.path.exists(folder):
        os.makedirs(folder)

    file_path = os.path.join(folder, filename)
    with open(file_path, "a", encoding="utf-8") as f:
        f.write(f"{datetime.now().strftime('%Y-%m-%d %H-%M-%S')} | STT : {text1}\n")
        f.write(f"{datetime.now().strftime('%Y-%m-%d %H-%M-%S')} | RASA: {text2}\n")

    return filename


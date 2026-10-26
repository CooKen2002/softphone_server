from datetime import datetime
import numpy as np
import wave
import json
from pathlib import Path
import subprocess
import requests
import time
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

def load_json(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return json.load(file)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return {}

# MARK: RASA UTILS
def rasa_scripts(rasa_session=None, wait_seconds=90, poll_interval=3):
    if rasa_session is None:
        rasa_session = requests.Session()

    payload = {"sender": SENDER_ID, "message": "xin chào"}

    def ping():
        try:
            res = rasa_session.post(RASA_URL, json=payload, timeout=3)
            return res.status_code == 200
        except Exception:
            return False

    if ping():
        return True

    subprocess.Popen(
        f'start "Rasa API" cmd /k "cd /d {RASA_PATH} && call .venv\\Scripts\\activate && rasa run --enable-api --cors \\"*\\" -vv"',
        shell=True,
    )
    subprocess.Popen(
        f'start "Rasa Actions" cmd /k "cd /d {RASA_PATH} && call .venv\\Scripts\\activate && rasa run actions -vv"',
        shell=True,
    )

    elapsed = 0
    while elapsed < wait_seconds:
        time.sleep(poll_interval)
        elapsed += poll_interval
        if ping():
            return True
    return False

def parse_nlu_with_rasa(text, rasa_url="http://localhost:5005"):
    endpoint = f"{rasa_url}/model/parse"
    payload = {
        "text": text
    }
    
    try:
        response = requests.post(endpoint, json=payload)
        
        # Kiểm tra nếu request thành công (HTTP Status Code 200)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Lỗi từ Rasa server: {response.status_code} - {response.text}")
            return None
            
    except requests.exceptions.ConnectionError:
        print("Lỗi: Không thể kết nối đến Rasa server. Hãy đảm bảo server đang chạy.")
        return None
    except Exception as e:
        print(f"Đã xảy ra lỗi: {e}")
        return None

# def save_audio(audio_data, name: str, output_path: str, samplerate: int = 16000):
#     """
#     Hàm tổng quát lưu mọi loại dữ liệu âm thanh ra file WAV 16-bit.
#     Hỗ trợ: numpy.ndarray, torch.Tensor, bytes (WAV hoặc raw PCM), list.
#     """
#     output_dir = Path(output_path)
#     output_dir.mkdir(parents=True, exist_ok=True)
    
#     # 1. Xử lý nếu đầu vào là PyTorch Tensor
#     if "torch" in str(type(audio_data)):
#         audio_data = audio_data.detach().cpu().numpy()

#     # 2. Xử lý nếu đầu vào là List / Tuple
#     elif isinstance(audio_data, (list, tuple)):
#         audio_data = np.array(audio_data, dtype=np.float32)

#     # 3. Xử lý nếu đầu vào là Bytes (có thể là file WAV đầy đủ hoặc chuỗi raw PCM)
#     elif isinstance(audio_data, bytes):
#         # Nếu đã có sẵn header WAV hoàn chỉnh, ghi trực tiếp ra file
#         if audio_data[:4] == b'RIFF':
#             with open(output_path, "wb") as f:
#                 f.write(audio_data)
#             return
#         else:
#             # Nếu là raw PCM bytes, chuyển thành mảng numpy int16 hoặc float32
#             audio_data = np.frombuffer(audio_data, dtype=np.int16).astype(np.float32) / 32768.0

#     # 4. Xử lý nếu đầu vào là NumPy Array
#     elif isinstance(audio_data, np.ndarray):
#         audio_data = audio_data.copy()
#     else:
#         raise TypeError(f"Không hỗ trợ kiểu dữ liệu đầu vào: {type(audio_data)}")

#     # Xử lý đa kênh hoặc dồn chiều (squeeze nếu là mảng nhiều chiều dạng (1, N))
#     if audio_data.ndim > 1:
#         audio_data = audio_data.squeeze()

#     # Chuẩn hóa giá trị float về dải [-1.0, 1.0] để tránh méo tiếng
#     if np.issubdtype(audio_data.dtype, np.floating):
#         audio_data = np.clip(audio_data, -1.0, 1.0)
#         pcm_data = (audio_data * 32767.0).astype(np.int16)
#     else:
#         # Nếu mảng đã ở dạng số nguyên (int16), giữ nguyên
#         pcm_data = audio_data.astype(np.int16)

#     # Ghi ra file WAV chuẩn bằng thư viện wave
#     filename = f"./{output_path}/{name}_{datetime.now().strftime('%d_%m_%y_%H_%M_%S.%f')}.wav"

#     with wave.open(filename, "wb") as wf:
#         wf.setnchannels(1)             # Mặc định Mono
#         wf.setsampwidth(2)             # 16-bit (2 bytes)
#         wf.setframerate(samplerate)    # Tần số lấy mẫu
#         wf.writeframes(pcm_data.tobytes())
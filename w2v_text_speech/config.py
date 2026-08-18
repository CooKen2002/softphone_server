import os
import torch

# ============================== DEVICE ==============================
DEVICE = "gpu" if torch.cuda.is_available() else "cpu"

# ============================== AUDIO / SERVER ==============================
SAMPLE_RATE = 16000
MIN_N_SAMPLES = int(0.3 * 16000)   # sàn ~0.3s, tránh input quá ngắn vỡ conv layer
MAX_N_SAMPLES = int(20 * 16000)

# Adaptive VAD
CALIBRATE_SECONDS = 3.0  # đo noise floor lúc khởi động
SPEECH_RATIO = 2.0  # RMS phải gấp N lần noise floor mới tính là tiếng nói
ZCR_MAX = 0.30  # zero-crossing rate tối đa
SPEECH_BAND_MIN = 0.40  # tối thiểu 40% năng lượng trong 300-3400 Hz

# rasa
RASA_PATH = "../rasa"
SENDER_ID = "hà lan"
RASA_URL = "http://localhost:5005/webhooks/rest/webhook"
RASA_BASE_URL = "http://localhost:5005"
HOST = "127.0.0.1"
PORT = 8000

DEBUG = True
SHOW_TIMING = True

RESULT_PATH = "./results"
ASSETS_PATH = "./assets"
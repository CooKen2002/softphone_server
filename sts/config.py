import os
import torch

# ============================== DEVICE ==============================
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# ==================== MODEL / WHISPER CONFIG (theo device) ====================
# Beam search rẻ trên GPU (song song hoá tốt) nhưng đắt trên CPU (gần như tuyến tính
# theo beam_size), nên tách hẳn 2 bộ tham số thay vì dùng chung 1 config cho cả 2 máy.
if DEVICE == "cuda":
    MODEL_PATH = (
        r"./models/PhoWhisper-medium-ct2-fasterWhisper"  # GPU rảnh tay -> model to hơn, WER tốt hơn
    )
    COMPUTE_TYPE = "float16" # float16 / float32
    BEAM_SIZE = 5  # GPU: giữ beam cao lấy accuracy vì chi phí không đáng kể
    CPU_THREADS = 0  # không có tác dụng khi DEVICE=cuda
    NUM_WORKERS = (
        4  # cho phép pipeline nhiều request qua CUDA streams khi có nhiều client 
    )
else:
    MODEL_PATH = r"./models/PhoWhisper-small-ct2-fasterWhisper"
    COMPUTE_TYPE = (
        "int8"  # tối ưu nhất cho CPU (CTranslate2 dùng VNNI/AVX512 nếu CPU hỗ trợ)
    )
    BEAM_SIZE = (
        5  # CPU: beam search đắt -> greedy (beam=1) cho domain hẹp (ride-booking)
    )
    try:
        import psutil

        CPU_THREADS = (
            psutil.cpu_count(logical=False) or 4
        )  # số CORE VẬT LÝ, không phải logical/hyperthread
    except ImportError:
        CPU_THREADS = max(
            1, (os.cpu_count() or 4) // 2
        )  # fallback thô nếu chưa cài psutil
    NUM_WORKERS = 1  # tránh contend thread với CPU_THREADS (pipeline đang chạy tuần tự qua 1 executor)

# Chặn các thư viện BLAS bên dưới (numpy/scipy/noisereduce...) tự spawn thêm thread
# chồng lên CPU_THREADS đã set cho CTranslate2 -> tránh oversubscribe khi DEVICE=cpu.
# Phải set TRƯỚC khi các thư viện đó được import lần đầu.
_omp_threads = str(CPU_THREADS if DEVICE == "cpu" else (os.cpu_count() or 4))
os.environ.setdefault("OMP_NUM_THREADS", _omp_threads)
os.environ.setdefault("MKL_NUM_THREADS", _omp_threads)

# ============================== AUDIO / SERVER ==============================
BLOCK_SECONDS = 3.0
SAVE_DIR = "./result"
SAMPLE_RATE = 16000
TARGET_SR = 16000

# Whisper transcribe config (không phụ thuộc device)
VAD_FILTER = True  # audio đã được trim silence ở preprocess_audio() -> tắt để tránh chạy Silero VAD 2 lần
CHUNK_LENGTH = 1
LANGUAGE = "vi"
NO_SPEECH_THRESHHOLD = 0.6  # ngưỡng phát hiện khoảng lặng
ENABLE_DENOISE = False
CHUNK_SAMPLES = 512  # 32ms @ 16kHz, đúng window_size_samples mà Silero VAD khuyến nghị
VAD_THRESHOLD = 0.5
MIN_SILENCE_MS = 500  # im lặng bao lâu thì coi là kết thúc câu
SPEECH_PAD_MS = 100  # đệm thêm ở 2 đầu segment
PRE_ROLL_CHUNKS = 10  # ~320ms buffer trước khi phát hiện speech, chống mất âm đầu câu
MIN_SPEECH_SEC = 0.3

# Adaptive VAD
CALIBRATE_SECONDS = 3.0  # đo noise floor lúc khởi động
SPEECH_RATIO = 2.0  # RMS phải gấp N lần noise floor mới tính là tiếng nói
ZCR_MAX = 0.30  # zero-crossing rate tối đa
SPEECH_BAND_MIN = 0.40  # tối thiểu 40% năng lượng trong 300-3400 Hz

# rasa
SENDER_ID = "hà lan"
RASA_URL = "http://localhost:5005/webhooks/rest/webhook"
RASA_BASE_URL = "http://localhost:5005"
HOST = "127.0.0.1"
PORT = 8000

DEBUG = True
SHOW_TIMING = True

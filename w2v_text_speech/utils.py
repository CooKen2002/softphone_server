from datetime import datetime
import numpy as np
import wave
from pathlib import Path

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



def save_audio(audio_data, name: str, output_path: str, samplerate: int = 16000):
    """
    Hàm tổng quát lưu mọi loại dữ liệu âm thanh ra file WAV 16-bit.
    Hỗ trợ: numpy.ndarray, torch.Tensor, bytes (WAV hoặc raw PCM), list.
    """
    output_dir = Path(output_path)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 1. Xử lý nếu đầu vào là PyTorch Tensor
    if "torch" in str(type(audio_data)):
        audio_data = audio_data.detach().cpu().numpy()

    # 2. Xử lý nếu đầu vào là List / Tuple
    elif isinstance(audio_data, (list, tuple)):
        audio_data = np.array(audio_data, dtype=np.float32)

    # 3. Xử lý nếu đầu vào là Bytes (có thể là file WAV đầy đủ hoặc chuỗi raw PCM)
    elif isinstance(audio_data, bytes):
        # Nếu đã có sẵn header WAV hoàn chỉnh, ghi trực tiếp ra file
        if audio_data[:4] == b'RIFF':
            with open(output_path, "wb") as f:
                f.write(audio_data)
            return
        else:
            # Nếu là raw PCM bytes, chuyển thành mảng numpy int16 hoặc float32
            audio_data = np.frombuffer(audio_data, dtype=np.int16).astype(np.float32) / 32768.0

    # 4. Xử lý nếu đầu vào là NumPy Array
    elif isinstance(audio_data, np.ndarray):
        audio_data = audio_data.copy()
    else:
        raise TypeError(f"Không hỗ trợ kiểu dữ liệu đầu vào: {type(audio_data)}")

    # Xử lý đa kênh hoặc dồn chiều (squeeze nếu là mảng nhiều chiều dạng (1, N))
    if audio_data.ndim > 1:
        audio_data = audio_data.squeeze()

    # Chuẩn hóa giá trị float về dải [-1.0, 1.0] để tránh méo tiếng
    if np.issubdtype(audio_data.dtype, np.floating):
        audio_data = np.clip(audio_data, -1.0, 1.0)
        pcm_data = (audio_data * 32767.0).astype(np.int16)
    else:
        # Nếu mảng đã ở dạng số nguyên (int16), giữ nguyên
        pcm_data = audio_data.astype(np.int16)

    # Ghi ra file WAV chuẩn bằng thư viện wave
    filename = f"{output_path}_{name}_{datetime.now().strftime('%d_%m_%y_%H_%M_%S.%f')}.wav"

    with wave.open(filename, "wb") as wf:
        wf.setnchannels(1)             # Mặc định Mono
        wf.setsampwidth(2)             # 16-bit (2 bytes)
        wf.setframerate(samplerate)    # Tần số lấy mẫu
        wf.writeframes(pcm_data.tobytes())
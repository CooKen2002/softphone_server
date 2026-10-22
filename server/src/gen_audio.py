import json
from pathlib import Path
from vieneu import Vieneu
import numpy as np
import scipy.signal
import scipy.io.wavfile as wav
from utils import *

tts = Vieneu()

def resample_audio(audio_data, orig_sr=48000, target_sr=8000):
    """Resample audio từ tần số gốc sang 8kHz cho tổng đài"""
    if orig_sr == target_sr:
        return audio_data
    num_output_samples = int(len(audio_data) * target_sr / orig_sr)
    return scipy.signal.resample(audio_data, num_output_samples)

def gen_all_audio(audio_folder_path):
    subfolders = [f for f in audio_folder_path.iterdir() if f.is_dir()]
    
    for subfolder in subfolders:
        audio_json_path = subfolder / "audio.json"
        list_audio = load_json(audio_json_path)
        
        if not list_audio:
            continue
            
        for text, audio in list_audio.items():
            print(f"Generating (8kHz / 16-bit): {text} -> {audio}")
            
            # 1. Infer lấy mảng âm thanh dạng float
            audio_data = tts.infer(text=text, voice="Đoan Trang")
            
            # 2. Resample về 8000 Hz (giả định Vieneu gốc chạy ở 24000Hz)
            target_sr = 8000
            orig_sr = 48000  # Thay đổi nếu Vieneu của bạn dùng sample rate khác (vd: 22050)
            resampled_audio = resample_audio(audio_data, orig_sr=orig_sr, target_sr=target_sr)
            
            # 3. Chuẩn hóa biên độ và đổi sang int16 để nghe rõ tiếng (tránh bị im lặng)
            audio_normalized = np.clip(resampled_audio, -1.0, 1.0)
            audio_int16 = (audio_normalized * 32767).astype(np.int16)
            
            # 4. Lưu file WAV chuẩn 8kHz, Mono, 16-bit
            filename = subfolder / audio
            wav.write(filename, target_sr, audio_int16)

if __name__ == "__main__":
    audio_folder_path = Path("./assets/audio")
    print(audio_folder_path)
    if audio_folder_path.is_dir():
        gen_all_audio(audio_folder_path)
    else:
        print("assets/audio not exist")
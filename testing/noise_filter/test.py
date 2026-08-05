import os
import time
import librosa
import numpy as np
import sounddevice as sd
import soundfile as sf
import torch

from faster_whisper import WhisperModel
from df.enhance import enhance, init_df, load_audio
import noisereduce as nr

# --- CẤU HÌNH ---
MODEL_PATH = "./models/PhoWhisper-small-ct2-fasterWhisper"
DEVICE = "cpu"
COMPUTE_TYPE = "int8"
CPU_THREADS = 4
NUM_WORKERS = 1

SAMPLE_RATE = 16000       # Tần số lấy mẫu chuẩn cho Whisper
MIC_OUTPUT_PATH = "./assets/mix/mic_test.wav"


def record_from_mic(output_path, samplerate=16000):
    """Ghi âm từ microphone: nhấn Enter để bắt đầu, nhấn Enter lần nữa để dừng."""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    input("\n🎙️ Nhấn Enter để bắt đầu ghi âm...")

    frames = []

    def callback(indata, frame_count, time_info, status):
        if status:
            print(status)
        frames.append(indata.copy())

    print("🔴 Đang ghi âm... Nhấn Enter để dừng.")
    stream = sd.InputStream(
        samplerate=samplerate,
        channels=1,
        dtype='float32',
        callback=callback,
    )
    with stream:
        input()  # Chờ Enter để dừng ghi âm

    if not frames:
        raise RuntimeError("⚠️ Không ghi được dữ liệu âm thanh nào (micro có thể chưa sẵn sàng).")

    audio_data = np.concatenate(frames, axis=0)
    duration = len(audio_data) / samplerate

    sf.write(output_path, audio_data, samplerate)
    print(f"✅ Đã lưu file ghi âm tại: {output_path} (thời lượng: {duration:.2f}s)")
    return output_path


def noise_reduce(data, rate, mix_name):
    start_time = time.time()
    nr_audio = nr.reduce_noise(
        y=data, 
        sr=rate,
        stationary=False,        # Phù hợp với tiếng ồn biến đổi (đường phố, quán cafe,...)
        prop_decrease=0.8,       # Giữ lại một phần để giọng nói không bị bóp méo quá mức
        n_std_thresh_stationary=1.5
    )
    nr_duration = time.time() - start_time
    
    nr_result_path = f"./results/nr_{mix_name}.wav"
    sf.write(nr_result_path, nr_audio, rate)
    print(f"🔹 [NR] Thời gian lọc nhiễu: {nr_duration:.4f} giây")
    return nr_result_path  # Trả về đường dẫn file kết quả


def dfn(model_df, df_state, audio_path, mix_name):
    start_time = time.time()
    
    audio_df, _ = load_audio(audio_path, sr=df_state.sr())
    enhanced_audio = enhance(model_df, df_state, audio_df)
    
    df_duration = time.time() - start_time
    
    if isinstance(enhanced_audio, torch.Tensor):
        df_audio = enhanced_audio.squeeze().detach().cpu().numpy()
    else:
        df_audio = enhanced_audio

    df_result_path = f"./results/df_{mix_name}.wav"
    # DeepFilterNet trả về sample rate của model (thường là 48000 hoặc theo cấu hình model)
    sf.write(df_result_path, df_audio, df_state.sr())
    print(f"🔹 [DFN] Thời gian lọc nhiễu: {df_duration:.4f} giây")
    return df_result_path  # Trả về đường dẫn file kết quả


def transcribe_with_fw(model, audio_path):
    """Thực hiện nhận diện giọng nói bằng Faster-Whisper."""
    y, sr = librosa.load(audio_path, sr=16000)
    
    segments, _ = model.transcribe(
        audio=y,
        language="vi",
        beam_size=5,
        no_speech_threshold=0.6,
        initial_prompt="không mấy chốc sau văn vương tỉnh trở lại và nói với thái công hãy mau cho truyền y pháp vào ý kiến"
    )
    
    text = "".join(seg.text.strip() + " " for seg in segments)
    return text.strip()


if __name__ == "__main__":
    os.makedirs("./results", exist_ok=True)
    
    # Khởi tạo mô hình
    model = WhisperModel(
        MODEL_PATH,
        device=DEVICE,
        compute_type=COMPUTE_TYPE,
        cpu_threads=(CPU_THREADS if DEVICE == "cpu" else 0),
        num_workers=NUM_WORKERS,
    )
    model_df, df_state, _ = init_df()
    
    # 1. Ghi âm từ mic
    input_path = record_from_mic(MIC_OUTPUT_PATH, samplerate=SAMPLE_RATE)
    
    data, rate = librosa.load(input_path, sr=SAMPLE_RATE)
    mix_name = os.path.splitext(os.path.basename(input_path))[0]
    
    print("\n" + "="*40)
    print("BẮT ĐẦU XỬ LÝ KHỬ NHIỄU")
    print("="*40)
    
    # 2. Chạy khử nhiễu và lấy đường dẫn file kết quả
    dfn_result_path = dfn(model_df, df_state, input_path, mix_name)
    nr_result_path = noise_reduce(data, rate, mix_name)

    print("\n" + "="*40)
    print("BẮT ĐẦU NHẬN DIỆN VĂN BẢN VỚI WHISPER")
    print("="*40)

    # 3. Transcribe kết quả
    print(f"\n📂 [DeepFilterNet - DFN]")
    print(f"   ↳ Kết quả: {transcribe_with_fw(model, dfn_result_path)}")
    
    print(f"\n📂 [NoiseReduce - NR]")
    print(f"   ↳ Kết quả: {transcribe_with_fw(model, nr_result_path)}")

    print("\n--- HOÀN TẤT ---")
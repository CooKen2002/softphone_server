"""
SERVER PYTHON - VOICE BOT (wav2vec + Rasa + TTS)
CREATED: 17/08/2026
UPDATED: 17/08/2026
"""

import asyncio
import io
import librosa
import requests
import time
import wave
import websockets

import scipy.signal as signal
import noisereduce as nr
import numpy as np

from vieneu import Vieneu

from rasa_utils import *
from config import *
from utils import *
from wav2vec import *

# MARK: LOAD MODELS

model = init_model("./models/wav2vec2_vietnamese.onnx", None, None)
log(f"LOADED model W2V", "INFO")

if DEVICE == "cpu":
    tts = Vieneu()
else:
    tts = Vieneu(
        mode="v3turbo"
        # v3turbo (Mặc định): Sử dụng V3TurboVieNeuTTS (48 kHz, chạy CPU qua ONNX Runtime không cần torch, GPU dùng PyTorch).
        # remote hoặc api: Sử dụng RemoteVieNeuTTS (chạy qua API).
        # fast hoặc gpu: Sử dụng FastVieNeuTTS (dùng GPU-LMDeploy).
        # turbo: Sử dụng TurboVieNeuTTS.
        # turbo_gpu: Sử dụng TurboGPUVieNeuTTS.
        # xpu: Sử dụng XPUVieNeuTTS (dành cho GPU Intel, yêu cầu cài đặt driver và torch.xpu).
        # standard: Sử dụng VieNeuTTS (CPU/GPU-GGUF).
    )
log(f"LOADED model Vieneu", "INFO")

rasa_session = requests.Session()
log(f"CREATED RASA SESSION", "INFO")


# MARK: STS FLOW
def load_and_validate_audio_buffer(raw_bytes: bytes, expected_sr: int = 16000):
    if raw_bytes[:4] == b'RIFF':
        # Trường hợp có WAV header đầy đủ — parse như cũ
        """Đọc buffer WAV và trả về numpy array"""
        with wave.open(io.BytesIO(raw_bytes), "r") as wf:
            sr = wf.getframerate()
            channels = wf.getnchannels()
            sampwidth = wf.getsampwidth()
            frames = wf.readframes(wf.getnframes())

        data = np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0

        log(
            f"Nhận audio: {len(raw_bytes)/1024:.1f} KB | {sr}Hz | {channels}ch | {len(data)/sr:.2f}s",
            "AUDIO",
        )

        # FIX #3: trước đây chỉ log warning khi channels != 1 nhưng không thực
        # sự downmix — data vẫn là chuỗi interleaved L/R, nghe như nhiễu.
        # Reshape về (n_frames, channels) rồi dùng ensure_channels (từ wav2vec.py)
        # để mix trung bình về mono thật sự.
        if channels != 1:
            log(f"Audio không phải Mono ({channels} channels), đang downmix...", "AUDIO")
            data = data.reshape(-1, channels)
            data, channels = ensure_channels(data, channels)

        if sr != expected_sr:
            log(f"Resampling {sr}Hz → {expected_sr}Hz bằng scipy...", "AUDIO")
            data = signal.resample_poly(data, up=expected_sr, down=sr).astype(np.float32)
            sr = expected_sr
            log(f"Resample xong: {len(data)/sr:.2f}s", "AUDIO")

        return data, sr
    else:
        # Không có RIFF header -> coi là raw PCM 16-bit mono
        if len(raw_bytes) % 2 != 0:
            # PCM 16-bit phải là số byte chẵn, lệch 1 byte thường do frame bị cắt giữa chừng
            raw_bytes = raw_bytes[:-1]

        pcm = np.frombuffer(raw_bytes, dtype=np.int16)
        data = pcm.astype(np.float32) / 32768.0
        sr = expected_sr  # raw PCM không mang sample rate, buộc phải giả định cố định

        log(
            f"Nhận audio (raw PCM): {len(raw_bytes)/1024:.1f} KB | {sr}Hz (giả định) | 1ch | {len(data)/sr:.2f}s",
            "AUDIO",
        )

        # Không cần resample vì client luôn gửi đúng expected_sr (16kHz),
        # nhưng nếu sau này client đổi sample rate mà quên báo, hàm này sẽ ÂM THẦM sai
        # (không crash, nhưng audio bị méo tốc độ) — không có cách nào phát hiện được ở đây.

        return data, sr


def preprocess_audio(audio_data: np.ndarray, sr: int) -> np.ndarray:
    """Tiền xử lý audio (audio đã ở 16kHz mono từ load_and_validate_audio_buffer):
    1. Khử nhiễu bằng `noisereduce` (spectral gating, thuần CPU, không cần model/GPU riêng
       như DeepFilterNet) — nhẹ và đơn giản hơn nhiều để chạy trên máy CPU-only.
    2. Normalize biên độ.
    3. Trim khoảng lặng ở đầu/cuối.
    Fail-safe: nếu bước khử nhiễu lỗi thì bỏ qua bước đó, dùng audio gốc.
    """

    # Khử nhiễu (spectral gating, stationary noise estimate)
    try:
        audio_data = nr.reduce_noise(
            y=audio_data,
            sr=sr,
            stationary=True,
            prop_decrease=0.8,
        )
    except Exception as e:
        log(f"noisereduce lỗi, bỏ qua bước khử nhiễu: {e}", "ERROR")

    # Normalize
    max_val = np.max(np.abs(audio_data))
    if max_val > 0:
        audio_data = audio_data / max_val

    # Trim silence
    threshold = 0.008
    non_silent = np.where(np.abs(audio_data) > threshold)[0]
    if len(non_silent) > 0:
        start = max(0, non_silent[0] - sr // 10)
        end = min(len(audio_data), non_silent[-1] + sr // 10)
        audio_data = audio_data[start:end]
    return audio_data


def wav_bytes_to_text(audio_data: np.ndarray) -> str:
    audio_array = np.array(audio_data, dtype=np.float32)

    if len(audio_array) < MIN_N_SAMPLES:
        audio_array = np.pad(audio_array, (0, MIN_N_SAMPLES - len(audio_array)))
    elif len(audio_array) > MAX_N_SAMPLES:
        log(f"Audio {len(audio_array)/16000:.1f}s vượt trần, cắt còn {MAX_N_SAMPLES/16000:.0f}s", "ERROR")
        audio_array = audio_array[:MAX_N_SAMPLES]

    audio_array = np.expand_dims(audio_array, axis=0)  # bắt buộc phải có nếu model rank-2
    outputs = run_model(model, audio_array)
    return post_process(outputs)


def request_to_rasa(text: str, sender_id: str) -> str:
    if not text or not text.strip():
        return "Bạn nói gì vậy?"

    try:
        payload = {"sender": sender_id, "message": text.strip()}
        response = rasa_session.post(RASA_URL, json=payload, timeout=8)
        response_data = response.json()

        rasa_text = ""
        for msg in response_data:
            if "text" in msg:
                rasa_text += msg["text"] + " "
        return rasa_text.strip()

    except Exception as e:
        log(f"Lỗi kết nối Rasa: {e}", "ERROR")
        return "Xin lỗi, tôi đang gặp vấn đề kỹ thuật. Bạn nói lại được không?"


async def text_to_wav_bytes(text: str) -> bytes:
    # 1. Synthesize (từ vieNeu tts)
    # voice_codes = tts.get_preset_voice("Ly")
    audio = tts.infer(text=text, voice="Ngọc Linh")

    # 2. Xử lý khoảng lặng (padding) 350ms
    sample_rate = 48000
    padding_samples = int(0.35 * sample_rate)
    silence = np.zeros(padding_samples, dtype=np.float32)
    audio = np.concatenate([silence, audio, silence])

    # 3. Chuyển đổi về 8kHz (Resampling)
    # Dùng librosa.resample thay vì librosa.load vì audio đã ở dạng array rồi
    audio_8k = librosa.resample(audio, orig_sr=sample_rate, target_sr=8000)

    # 4. Chuyển đổi về 16-bit PCM (int16)
    audio_int16 = np.clip(audio_8k * 32767, -32768, 32767).astype(np.int16)

    # 5. Ghi vào bytes (Memory Buffer) thay vì file vật lý
    wav_io = io.BytesIO()
    with wave.open(wav_io, "wb") as wf:
        wf.setnchannels(1)  # Mono
        wf.setsampwidth(2)  # 16-bit = 2 bytes
        wf.setframerate(8000)  # 8kHz
        wf.writeframes(audio_int16.tobytes())

    return wav_io.getvalue()


# MARK: WARMUP
def warmup_models():
    """Chạy 1 lượt inference 'mồi' cho từng model để CUDA kernel/cudnn autotune xảy ra
    lúc khởi động thay vì ở request đầu tiên của người dùng thật (tránh spike latency).
    """
    try:
        dummy = np.zeros(SAMPLE_RATE, dtype=np.float32)  # 1s silence @ 16kHz
        processed = preprocess_audio(dummy, SAMPLE_RATE)

        t0 = time.perf_counter()
        wav_bytes_to_text(processed)
        log(f" Warmup W2V : {time.perf_counter() - t0:.2f}s", "STT")

        t0 = time.perf_counter()
        tts.infer(text="xin chào", voice="Ngọc Linh")
        log(f" Warmup TTS : {time.perf_counter() - t0:.2f}s", "TTS")

        log(f"Warmup models hoàn tất!", "INFO")
    except Exception as e:
        log(f"Warmup lỗi (bỏ qua): {e}", "ERROR")


def warmup_rasa():
    payload = {"sender": SENDER_ID, "message": "xin chào"}
    res_post = rasa_session.post(RASA_URL, json=payload, timeout=8)
    if res_post.status_code == 200:
        log(f"Warmup RASA session thành công", "RASA")
    else:
        log(f"PORT: {RASA_BASE_URL} not available", "ERROR")


# MARK: WEBSOCKET
# ====================== WEBSOCKET HANDLER ======================
async def handle_client(websocket):
    client_addr = websocket.remote_address
    log(f"Client connected: {client_addr}", "INFO")

    loop = asyncio.get_running_loop()

    try:
        async for message in websocket:
            # Try/except riêng cho từng message: 1 audio/model lỗi không làm
            # rớt kết nối, server tiếp tục chờ message tiếp theo của client này.
            try:
                if not isinstance(message, bytes):
                    log("Nhận dữ liệu không phải bytes!", "ERROR")
                    continue

                # ==================== PIPELINE ====================
                # 1. Nhận & validate audio
                audio_data, sr = load_and_validate_audio_buffer(message)
                save_audio(audio_data, "load", RESULT_PATH, sr)

                # 2. Preprocess
                processed = preprocess_audio(audio_data, sr)
                save_audio(audio_data, "preprocess", RESULT_PATH, sr)

                # 3. Speech-to-Text
                t0 = time.perf_counter()
                transcript = await loop.run_in_executor(None, wav_bytes_to_text, processed)
                log(f"STT : {time.perf_counter() - t0:.2f}s", "STT")
                log(f"↳ response: {transcript.strip()}", "STT")

                # 4. Rasa Dialog
                t0 = time.perf_counter()
                rasa_text = await loop.run_in_executor(
                    None, request_to_rasa, transcript, SENDER_ID
                )
                log(f"↳ response: {rasa_text.strip()[:100]}", "RASA")
                log(f"Rasa : {time.perf_counter() - t0:.2f}s", "RASA")

                # 5. Text-to-Speech
                t0 = time.perf_counter()
                wav_bytes = await text_to_wav_bytes(rasa_text)
                log(f"TTS : {time.perf_counter() - t0:.2f}s", "TTS")

                # 6. Gửi về Flutter
                await websocket.send(wav_bytes)
                log(f"Đã gửi audio trả lời ({len(wav_bytes)/1024:.1f} KB)", "INFO")

            except Exception as e:
                log(f"Lỗi xử lý message từ {client_addr}: {e}", "ERROR")
                # Kết nối vẫn mở, tiếp tục chờ message tiếp theo của client này.
                continue

    except websockets.exceptions.ConnectionClosed:
        log(f"Client disconnected: {client_addr}", "INFO")
    finally:
        log(f"Đóng kết nối với {client_addr}", "INFO")


# MARK: MAIN
# ====================== MAIN ======================
async def main():
    warmup_models()
    warmup_rasa()
    print("=" * 70)
    print("          SERVER VOICE BOT WEBSOCKET ĐÃ KHỞI ĐỘNG")
    print(f"          Listening on ws://0.0.0.0:8765")
    print("=" * 70)

    async with websockets.serve(
        handle_client,
        "0.0.0.0",
        8765,
        max_size=20_000_000,  # Tăng buffer
        ping_interval=20,
        ping_timeout=30,
    ):
        await asyncio.Future()  # Chạy mãi mãi


if __name__ == "__main__":
    if not rasa_scripts(rasa_session):
        print("Không khởi động được Rasa, thoát.")
        exit(1)
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped by user.")
    except Exception as e:
        print(f"Server error: {e}")

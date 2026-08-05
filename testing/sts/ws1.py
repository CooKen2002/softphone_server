"""
SERVER PYTHON - VOICE BOT (STT + Rasa + TTS)
UPDATED: 21/7/2026
"""

import numpy as np
import scipy.signal as signal
from faster_whisper import WhisperModel
import websockets
import soundfile as sf
from pydub import AudioSegment

# from piper import PiperVoice
import requests
import librosa
import torch
from df.enhance import init_df, enhance
import asyncio
import io
import time
import wave
import os
from datetime import datetime

from vieneu import Vieneu

from config import *
from postprocess import clean_text
from rasa_suggest import RasaPrompt
from utils import *

# MARK: LOAD MODELS
print(
    f"[{datetime.now().strftime('%H:%M:%S')}] Đang tải model Whisper '{MODEL_PATH}'..."
)
model = WhisperModel(MODEL_PATH, device=DEVICE, compute_type=COMPUTE_TYPE)
print(f"[{datetime.now().strftime('%H:%M:%S')}] Whisper loaded successfully!")

# DeepFilterNet (khu nhieu) - load 1 lan duy nhat, chay tren cung device voi Whisper/TTS
print(f"[{datetime.now().strftime('%H:%M:%S')}] Đang tải model DeepFilterNet...")
DFN_SAMPLE_RATE = 48000  # sample rate co dinh cua DeepFilterNet
_dfn_torch_device = torch.device(
    DEVICE if torch.cuda.is_available() and DEVICE == "cuda" else "cpu"
)
dfn_model, dfn_state, _ = init_df()
dfn_model = dfn_model.to(device=_dfn_torch_device).eval()
assert dfn_state.sr() == DFN_SAMPLE_RATE, f"DFN sample rate mismatch: {dfn_state.sr()}"
print(
    f"[{datetime.now().strftime('%H:%M:%S')}] DeepFilterNet loaded successfully! (device={_dfn_torch_device})"
)

print(f"[{datetime.now().strftime('%H:%M:%S')}] Đang tải VieNeu TTS...")
tts = Vieneu(
    backbone_device=DEVICE,
    codec_device=DEVICE,
    # emotion = "Storytelling"
)
print(f"[{datetime.now().strftime('%H:%M:%S')}] VieNeu TTS loaded successfully!\n")


# MARK: FW FUNCs
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


def load_and_validate_audio_buffer(raw_bytes: bytes, expected_sr: int = 16000):
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

    # Resample chuẩn về 16kHz nếu nhận 8kHz từ bareSIP
    if sr != expected_sr:
        log(f"Resampling {sr}Hz → {expected_sr}Hz bằng scipy...", "AUDIO")
        data = signal.resample_poly(data, up=expected_sr, down=sr).astype(np.float32)
        sr = expected_sr
        log(f"Resample xong: {len(data)/sr:.2f}s", "AUDIO")

    if channels != 1:
        log(f"Warning: Audio không phải Mono ({channels} channels)", "ERROR")

    return data, sr


def denoise_dfn(audio_data: np.ndarray, sr: int) -> np.ndarray:
    """Khử nhiễu nền (quạt, xe cộ, tạp âm...) bằng DeepFilterNet trước khi transcribe.

    DeepFilterNet chỉ chạy ở 48kHz cố định (DFN_SAMPLE_RATE), nên audio được
    upsample lên 48kHz để khử nhiễu rồi downsample lại về `sr` gốc (16kHz)
    để tương thích với các bước sau (preprocess_audio, Whisper).
    Dùng resample_poly (tỉ lệ đúng 48000/16000=3) thay vì librosa/soxr để nhanh
    hơn cho pipeline real-time, và fail-safe: nếu lỗi thì trả lại audio gốc
    thay vì làm sập luồng xử lý.
    """
    if len(audio_data) == 0:
        return audio_data

    start = time.perf_counter()
    try:
        ratio = DFN_SAMPLE_RATE // sr
        if DFN_SAMPLE_RATE % sr == 0 and ratio > 1:
            audio_48k = signal.resample_poly(audio_data, up=ratio, down=1).astype(
                np.float32
            )
        elif sr != DFN_SAMPLE_RATE:
            audio_48k = signal.resample_poly(
                audio_data, up=DFN_SAMPLE_RATE, down=sr
            ).astype(np.float32)
        else:
            audio_48k = audio_data.astype(np.float32)

        audio_tensor = torch.from_numpy(audio_48k).unsqueeze(0).to(_dfn_torch_device)
        with torch.inference_mode():
            enhanced_tensor = enhance(dfn_model, dfn_state, audio_tensor)
        enhanced_48k = enhanced_tensor.squeeze(0).cpu().numpy().astype(np.float32)

        if DFN_SAMPLE_RATE % sr == 0 and ratio > 1:
            enhanced = signal.resample_poly(enhanced_48k, up=1, down=ratio).astype(
                np.float32
            )
        elif sr != DFN_SAMPLE_RATE:
            enhanced = signal.resample_poly(
                enhanced_48k, up=sr, down=DFN_SAMPLE_RATE
            ).astype(np.float32)
        else:
            enhanced = enhanced_48k

        log(f"DFN khử nhiễu xong: {time.perf_counter()-start:.2f}s", "AUDIO")
        return enhanced
    except Exception as e:
        log(f"Lỗi DFN, dùng audio gốc: {e}", "ERROR")
        return audio_data


def preprocess_audio(audio_data: np.ndarray, sr: int) -> np.ndarray:
    """Normalize + trim silence"""
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


def transcribe_faster_whisper(
    audio_data: np.ndarray, initial_prompt: str = None, hotwords: str = None
):
    start = time.perf_counter()
    segments, info = model.transcribe(
        audio_data,
        language=LANGUAGE,
        beam_size=2,
        vad_filter=True,
        vad_parameters=dict(min_silence_duration_ms=300),
        condition_on_previous_text=False,
        initial_prompt=initial_prompt or "Đây là cuộc hội thoại tiếng Việt.",
        hotwords=hotwords,
        no_speech_threshold=0.6,
    )

    text = ""
    for seg in segments:
        text += seg.text.strip() + " "
        log(f"[{seg.start:.1f}s → {seg.end:.1f}s] {seg.text.strip()}", "STT")

    duration = len(audio_data) / 16000
    log(
        f"STT hoàn thành: '{text.strip()}' | RTF: {(time.perf_counter()-start)/duration:.2f}x",
        "STT",
    )
    return clean_text(text).strip()


def request_to_rasa(text: str) -> str:
    if not text or not text.strip():
        return "default|Bạn nói gì vậy?"

    start = time.perf_counter()
    try:
        payload = {"sender": SENDER_ID, "message": text.strip()}
        response = requests.post(RASA_URL, json=payload, timeout=8)
        response_data = response.json()

        rasa_text = ""
        for msg in response_data:
            if "text" in msg:
                rasa_text += msg["text"] + " "

        log(f"Rasa response: {rasa_text.strip()[:100]}...", "RASA")
        log(f"Rasa time: {time.perf_counter()-start:.2f}s", "RASA")
        return rasa_text.strip()

    except Exception as e:
        log(f"Lỗi kết nối Rasa: {e}", "ERROR")
        return "default|Xin lỗi, tôi đang gặp vấn đề kỹ thuật. Bạn nói lại được không?"


async def text_to_wav_bytes(text: str) -> bytes:
    # 1. Synthesize (từ vieNeu tts)
    voice_codes = tts.get_preset_voice("Ly")
    audio = tts.infer(text=text, voice=voice_codes)  # Thường là float32 numpy array

    # 2. Xử lý khoảng lặng (padding) 350ms
    # Giả sử sample rate gốc của model là 24000Hz (thường thấy ở các model vits/vieNeu)
    # Bạn cần thay 24000 bằng sample rate gốc của model vieNeu nếu khác
    sample_rate = 24000
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


# MARK: WEBSOCKET
# ====================== WEBSOCKET HANDLER ======================
async def handle_client(websocket):
    client_addr = websocket.remote_address
    log(f"Client connected: {client_addr}", "INFO")

    rasa_prompt = RasaPrompt()

    try:
        async for message in websocket:
            total_start = time.perf_counter()

            if not isinstance(message, bytes):
                log("Nhận dữ liệu không phải bytes!", "ERROR")
                continue

            # ==================== PIPELINE ====================
            # 1. Nhận & validate audio
            audio_data, sr = load_and_validate_audio_buffer(message)

            # 2. Khử nhiễu (DeepFilterNet)
            denoised = denoise_dfn(audio_data, sr)

            # 3. Preprocess
            processed = preprocess_audio(denoised, sr)

            # 4. Speech-to-Text
            transcript = transcribe_faster_whisper(
                processed,
                initial_prompt=rasa_prompt.initial_prompt,
                hotwords=rasa_prompt.hot_word,
            )

            # 5. Rasa Dialog
            rasa_raw = request_to_rasa(transcript)

            # 5b. Parse state + text thật, đồng thời cập nhật prompt/hotword cho turn kế tiếp
            state, rasa_text = rasa_prompt.compile_text(rasa_raw)
            log(f"State='{state}' | next_prompt='{rasa_prompt.initial_prompt}'", "RASA")

            # 6. Text-to-Speech
            wav_bytes = await text_to_wav_bytes(rasa_text)

            # 7. Gửi về Flutter
            await websocket.send(wav_bytes)
            log(f"Đã gửi audio trả lời ({len(wav_bytes)/1024:.1f} KB)", "INFO")

            total_time = time.perf_counter() - total_start
            log(
                f"=== HOÀN THÀNH 1 LUỒNG - Tổng thời gian: {total_time:.2f}s ===",
                "INFO",
            )

    except websockets.exceptions.ConnectionClosed:
        log(f"Client disconnected: {client_addr}", "INFO")
    except Exception as e:
        log(f"Lỗi xử lý client: {e}", "ERROR")
    finally:
        log(f"Đóng kết nối với {client_addr}", "INFO")


# MARK: MAIN
# ====================== MAIN ======================
async def main():
    print("=" * 70)
    print("          SERVER VOICE BOT WEBSOCKET ĐÃ KHỞI ĐỘNG")
    print(f"          Listening on ws://0.0.0.0:8765")
    print("=" * 70 + "\n")

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
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped by user.")
    except Exception as e:
        print(f"Server error: {e}")

# def create_silence_wav(duration_ms: int = 600) -> bytes:
#     silence = AudioSegment.silent(duration=duration_ms)
#     silence = silence.set_frame_rate(16000).set_channels(1).set_sample_width(2)
#     buf = io.BytesIO()
#     silence.export(buf, format="wav")
#     buf.seek(0)
#     return buf.getvalue()

# async def text_to_wav_bytes(text: str) -> bytes:
#     """Piper TTS → WAV 16kHz bytes (tối ưu memory)"""
#     if not text or not text.strip():
#         return create_silence_wav(800)

#     start = time.perf_counter()

#     # Synthesize to memory
#     wav_io = io.BytesIO()
#     with wave.open(wav_io, "wb") as wf:
#         voice_piper.synthesize_wav(text, wf)
#     wav_io.seek(0)

#     audio = AudioSegment.from_wav(wav_io)

#     # Thêm silence đầu cuối cho tự nhiên
#     silence = AudioSegment.silent(duration=350)
#     audio = silence + audio + silence

#     # Convert to 16kHz mono 16bit
#     audio = audio.set_frame_rate(8000).set_channels(1).set_sample_width(2)

#     # Export to bytes
#     output = io.BytesIO()
#     audio.export(output, format="wav")
#     output.seek(0)

#     log(f"TTS hoàn thành: {len(output.getvalue())/1024:.1f} KB | {time.perf_counter()-start:.2f}s", "TTS")
#     return output.getvalue()

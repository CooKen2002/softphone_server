"""
SERVER PYTHON - VOICE BOT (STT + Rasa + TTS)
UPDATED: 28/7/2026
"""

import numpy as np
import scipy.signal as signal
from faster_whisper import WhisperModel
import websockets
import soundfile as sf
# from pydub import AudioSegment

# from piper import PiperVoice
import requests
import torch
import noisereduce as nr
import asyncio
from concurrent.futures import ThreadPoolExecutor
from math import gcd
import io
import time
import wave
import os
import json
from datetime import datetime

from vieneu import Vieneu
from scipy.io import wavfile

from config import *
from postprocess import clean_text
from rasa_suggest import RasaPrompt
from utils import *

# Sample rate dùng xuyên suốt pipeline sau bước load audio (Whisper yêu cầu 16kHz)
TARGET_SR = 16000

# GPU/CPU (Whisper/TTS) không thread-safe khi gọi song song trên nhiều thread, nên
# dùng 1 worker cố định làm hàng đợi tuần tự cho các job GPU/CPU nặng. Điều này giúp
# các bước inference không chặn (block) event loop asyncio chính — vốn đang cần rảnh
# để xử lý ping/pong và các client khác đang kết nối cùng lúc.
gpu_executor = ThreadPoolExecutor(max_workers=1)

# Session HTTP tái sử dụng kết nối (keep-alive) tới Rasa thay vì mở connection mới mỗi turn
_rasa_session = requests.Session()

# MARK: LOAD&WARMUP
print(
    f"[{datetime.now().strftime('%H:%M:%S')}] Đang tải model Whisper '{MODEL_PATH}'..."
)
model = WhisperModel(
    MODEL_PATH,
    device=DEVICE,
    compute_type=COMPUTE_TYPE,
    cpu_threads=(
        CPU_THREADS if DEVICE == "cpu" else 0
    ),  # 0 = mặc định CTranslate2, không áp dụng trên GPU
    num_workers=NUM_WORKERS,
)
print(f"[{datetime.now().strftime('%H:%M:%S')}] Whisper loaded successfully!")

print(f"[{datetime.now().strftime('%H:%M:%S')}] Đang tải VieNeu TTS...")
if DEVICE == "cpu":
    tts = Vieneu()  
else:
    tts = Vieneu(
        mode="gpu"
        # v3turbo (Mặc định): Sử dụng V3TurboVieNeuTTS (48 kHz, chạy CPU qua ONNX Runtime không cần torch, GPU dùng PyTorch).
        # remote hoặc api: Sử dụng RemoteVieNeuTTS (chạy qua API).
        # fast hoặc gpu: Sử dụng FastVieNeuTTS (dùng GPU-LMDeploy).
        # turbo: Sử dụng TurboVieNeuTTS.
        # turbo_gpu: Sử dụng TurboGPUVieNeuTTS.
        # xpu: Sử dụng XPUVieNeuTTS (dành cho GPU Intel, yêu cầu cài đặt driver và torch.xpu).
        # standard: Sử dụng VieNeuTTS (CPU/GPU-GGUF).
   )
print(f"[{datetime.now().strftime('%H:%M:%S')}] VieNeu TTS loaded successfully!\n")


def warmup_models():
    """Chạy 1 lượt inference 'mồi' cho từng model để CUDA kernel/cudnn autotune xảy ra
    lúc khởi động thay vì ở request đầu tiên của người dùng thật (tránh spike latency).
    """
    try:
        dummy = np.zeros(TARGET_SR, dtype=np.float32)  # 1s silence @ 16kHz
        preprocess_audio(dummy, TARGET_SR)
        list(model.transcribe(dummy, language=LANGUAGE, beam_size=BEAM_SIZE)[0])
        synthesize_tts("xin chào")
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Warmup models hoàn tất!")
    except Exception as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Warmup lỗi (bỏ qua): {e}")

# MARK: FW FUNCs

def load_and_validate_audio_buffer(raw_bytes: bytes):
    """Đọc buffer WAV và trả về numpy array ở sample rate GỐC (chưa resample).

    Việc resample về 16kHz được dời sang preprocess_audio() để gộp chung với
    noisereduce/normalize/trim thành 1 bước tiền xử lý duy nhất.
    """
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

    if channels != 1:
        log(f"Warning: Audio không phải Mono ({channels} channels)", "ERROR")

    return data, sr


def _resample(data: np.ndarray, sr_from: int, sr_to: int) -> np.ndarray:
    """Resample chính xác bằng resample_poly, rút gọn tỉ lệ up/down theo GCD
    (vd 8000→48000 dùng up=6/down=1 thay vì up=48000/down=8000)."""
    if sr_from == sr_to or len(data) == 0:
        return data.astype(np.float32)
    g = gcd(sr_from, sr_to)
    up, down = sr_to // g, sr_from // g
    return signal.resample_poly(data, up=up, down=down).astype(np.float32)


def preprocess_audio(
    audio_data: np.ndarray, sr: int, target_sr: int = TARGET_SR
) -> np.ndarray:
    """Tiền xử lý audio gộp thành 1 bước duy nhất:
    1. Resample thẳng từ `sr` gốc về `target_sr` (16kHz, yêu cầu của Whisper) — chỉ 1 lần,
       không qua sample rate trung gian nào (thay cho việc từng phải lên 48kHz cho DFN).
    2. Khử nhiễu bằng `noisereduce` (spectral gating, thuần CPU, không cần model/GPU riêng
       như DeepFilterNet) — nhẹ và đơn giản hơn nhiều để chạy trên máy CPU-only.
    3. Normalize biên độ.
    4. Trim khoảng lặng ở đầu/cuối.
    Fail-safe: nếu bước khử nhiễu lỗi thì bỏ qua bước đó, dùng audio đã resample.
    """
    t0 = time.perf_counter()
    audio_data = _resample(audio_data, sr, target_sr)
    if len(audio_data) == 0:
        return audio_data

    # Khử nhiễu (bật/tắt qua config.ENABLE_DENOISE — noisereduce khá tốn CPU, nên cho phép tắt
    # khi môi trường thu âm đã sạch để đổi lấy tốc độ)
    if ENABLE_DENOISE:
        t_denoise = time.perf_counter()
        try:
            audio_data = nr.reduce_noise(
                y=audio_data,
                sr=target_sr,
                stationary=False,  # False tốt hơn cho nhiễu biến đổi (tiếng ồn quán cafe, đường phố,...)
                prop_decrease=0.6,  # Giảm tỷ lệ triệt tiêu nhiễu xuống (mặc định là 1.0 - triệt tiêu 100%). Giữ lại 0.8 giúp giọng nói đỡ bị bóp méo/nhỏ tiếng.
                n_std_thresh_stationary=1.5,  # Ngưỡng độ lệch chuẩn để lọc (mặc định khoảng 1.5 - 2.0). Giá trị nhỏ hơn sẽ lọc mạnh hơn.
            ).astype(np.float32)
            log(
                f"  ↳ Denoise (noisereduce): {time.perf_counter()-t_denoise:.2f}s",
                "AUDIO",
            )
        except Exception as e:
            log(f"Lỗi noisereduce, dùng audio chưa khử nhiễu: {e}", "ERROR")

    # Normalize
    max_val = np.max(np.abs(audio_data))
    if max_val > 0:
        audio_data = audio_data / max_val

    # Trim silence
    threshold = 0.008
    non_silent = np.where(np.abs(audio_data) > threshold)[0]
    if len(non_silent) > 0:
        start_idx = max(0, non_silent[0] - target_sr // 10)
        end_idx = min(len(audio_data), non_silent[-1] + target_sr // 10)
        audio_data = audio_data[start_idx:end_idx]

    log(
        f"Preprocess tổng: xử lý={time.perf_counter()-t0:.2f}s | audio sau xử lý={len(audio_data)/target_sr:.2f}s",
        "AUDIO",
    )
    return audio_data


def transcribe_faster_whisper(
    audio_data: np.ndarray, initial_prompt: str = None, hotwords: str = None
):
    start = time.perf_counter()
    segments, info = model.transcribe(
        audio_data,
        language=LANGUAGE,
        beam_size=BEAM_SIZE,
        best_of=5,              # số candidate khi temperature > 0, tăng cơ hội chọn kết quả tốt
        patience=1.0,           # beam search patience, >1 tìm kỹ hơn (đổi lấy tốc độ)
        length_penalty=1.0,
        repetition_penalty=1.1, # >1 giảm lặp từ, hữu ích với audio nhiễu/khoảng lặng ngắn
        no_repeat_ngram_size=3, # chặn lặp cụm n-gram (tránh hallucination lặp câu)
        temperature=[0.0, 0.2, 0.4, 0.6, 0.8, 1.0],  # fallback list thay vì temperature=0 cứng
        compression_ratio_threshold=2.4,  # loại segment "hallucinate" (lặp/nhiễu)
        log_prob_threshold=-1.0,          # loại segment có avg logprob quá thấp
        vad_filter=VAD_FILTER,
        vad_parameters=dict(
            min_silence_duration_ms=MIN_SILENCE_MS,
            speech_pad_ms=400,   # đệm thêm quanh vùng speech, tránh cắt mất âm đầu/cuối câu
            threshold=0.5,
        ),
        condition_on_previous_text=False,
        initial_prompt=initial_prompt,
        hotwords=hotwords,
        no_speech_threshold=NO_SPEECH_THRESHHOLD,
        suppress_blank=True,
    )

    text = ""
    for seg in segments:
        text += seg.text.strip() + " "
        log(f"  ↳ [{seg.start:.1f}s → {seg.end:.1f}s] {seg.text.strip()}", "STT")

    elapsed = time.perf_counter() - start
    duration = len(audio_data) / 16000
    rtf = elapsed / duration if duration > 0 else 0.0
    log(
        f"STT: audio={duration:.2f}s | xử lý={elapsed:.2f}s | RTF={rtf:.2f}x | text='{text.strip()}'",
        "STT",
    )
    return clean_text(text).strip()


def request_to_rasa(text: str) -> str:
    if not text or not text.strip():
        return "default|Bạn nói gì vậy?"

    start = time.perf_counter()
    try:
        payload = {"sender": SENDER_ID, "message": text.strip()}
        response = _rasa_session.post(RASA_URL, json=payload, timeout=8)
        response_data = response.json()

        rasa_text = ""
        for msg in response_data:
            if "text" in msg:
                rasa_text += msg["text"] + " "

        log(f"  ↳ response: {rasa_text.strip()[:100]}", "RASA")
        log(f"Rasa: xử lý={time.perf_counter()-start:.2f}s", "RASA")
        return rasa_text.strip()

    except Exception as e:
        log(f"Lỗi kết nối Rasa: {e}", "ERROR")
        return "default|Xin lỗi, tôi đang gặp vấn đề kỹ thuật. Bạn nói lại được không?"


def synthesize_tts(text: str) -> bytes:
    """Phần đồng bộ (blocking) của TTS — chạy trong gpu_executor để không chặn event loop."""
    start = time.perf_counter()

    # 1. Synthesize (từ vieNeu tts)
    # voice_codes = tts.get_preset_voice("Đoan Trang")
    audio = tts.infer(text=text, voice="Đoan Trang")  # Thường là float32 numpy array

    # 2. Xử lý khoảng lặng (padding) 350ms
    # Giả sử sample rate gốc của model là 48000Hz (thường thấy ở các model vits/vieNeu)
    # Bạn cần thay 48000 bằng sample rate gốc của model vieNeu nếu khác
    sample_rate = 48000
    padding_samples = int(0.35 * sample_rate)
    silence = np.zeros(padding_samples, dtype=np.float32)
    audio = np.concatenate([silence, audio, silence])

    # 3. Chuyển đổi về 8kHz. Tỉ lệ 24000/8000=3 là số nguyên chính xác nên dùng
    # resample_poly (nhanh hơn nhiều so với librosa.resample/soxr) thay vì FFT-based resampling.
    audio_8k = _resample(audio, sample_rate, 8000)

    # 4. Chuyển đổi về 16-bit PCM (int16)
    audio_int16 = np.clip(audio_8k * 32767, -32768, 32767).astype(np.int16)

    # 5. Ghi vào bytes (Memory Buffer) thay vì file vật lý
    wav_io = io.BytesIO()
    with wave.open(wav_io, "wb") as wf:
        wf.setnchannels(1)  # Mono
        wf.setsampwidth(2)  # 16-bit = 2 bytes
        wf.setframerate(8000)  # 8kHz
        wf.writeframes(audio_int16.tobytes())

    out_duration = len(audio_int16) / 8000
    log(
        f"TTS: audio_ra={out_duration:.2f}s | xử lý={time.perf_counter()-start:.2f}s | dung lượng={len(wav_io.getvalue())/1024:.1f}KB",
        "TTS",
    )
    return wav_io.getvalue()


async def text_to_wav_bytes(text: str) -> bytes:
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(gpu_executor, synthesize_tts, text)


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


# MARK: WEBSOCKET
# ====================== WEBSOCKET HANDLER ======================
async def handle_client(websocket):
    client_addr = websocket.remote_address
    log(f"Client connected: {client_addr}", "INFO")

    rasa_prompt = RasaPrompt()

    loop = asyncio.get_running_loop()

    try:
        async for message in websocket:
            total_start = time.perf_counter()
            timings = {}  # thời gian XỬ LÝ (không phải thời lượng audio) của từng bước

            if not isinstance(message, bytes):
                log("Nhận dữ liệu không phải bytes!", "ERROR")
                continue

            # ==================== PIPELINE ====================
            # Các bước CPU nặng (preprocess/denoise, Whisper, TTS) chạy qua gpu_executor (1 worker,
            # tuần tự) và bước gọi Rasa qua executor mặc định — tất cả để không chặn
            # event loop chính, cho phép server phục vụ nhiều client song song.

            # 1. Nhận & validate audio (giữ nguyên sample rate gốc)
            audio_data, sr = load_and_validate_audio_buffer(message)
            turn_id = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
            input_duration = len(audio_data) / sr if sr else 0.0

            # 2. Preprocess: resample → khử nhiễu (noisereduce) → normalize → trim silence (gộp 1 hàm)
            t0 = time.perf_counter()
            processed = await loop.run_in_executor(
                gpu_executor, preprocess_audio, audio_data, sr
            )
            timings["preprocess"] = time.perf_counter() - t0

            # 3. Speech-to-Text
            t0 = time.perf_counter()
            transcript = await loop.run_in_executor(
                gpu_executor,
                transcribe_faster_whisper,
                processed,
                rasa_prompt.initial_prompt,
                rasa_prompt.hot_word,
            )
            timings["stt"] = time.perf_counter() - t0

            # 4. Rasa Dialog (HTTP call — không cần chung executor với GPU)
            t0 = time.perf_counter()
            rasa_raw = await loop.run_in_executor(None, request_to_rasa, transcript)
            timings["rasa"] = time.perf_counter() - t0

            # 4b. Parse state + text thật, đồng thời cập nhật prompt/hotword cho turn kế tiếp
            state, rasa_text = rasa_prompt.process_response(rasa_raw)
            log(
                f"State='{state}' | next_iPrompt='{rasa_prompt.initial_prompt}'", "RASA"
            )
            log(f"State='{state}' | next_hotword='{rasa_prompt.hot_word}'", "RASA")

            # 5. Text-to-Speech
            t0 = time.perf_counter()
            wav_bytes = await text_to_wav_bytes(rasa_text)
            timings["tts"] = time.perf_counter() - t0

            # 6. Gửi về Flutter
            await websocket.send(wav_bytes)
            log(f"Đã gửi audio trả lời ({len(wav_bytes)/1024:.1f} KB)", "INFO")

            total_time = time.perf_counter() - total_start
            processed_duration = len(processed) / TARGET_SR if len(processed) else 0.0
            rtf_total = total_time / input_duration if input_duration > 0 else 0.0

            # ===== TÓM TẮT: tách biệt THỜI LƯỢNG AUDIO vs THỜI GIAN XỬ LÝ của từng bước =====
            log("-" * 64, "INFO")
            log(f"TÓM TẮT LUỒNG turn_id={turn_id}", "INFO")
            log(
                f"  Audio đầu vào     : {input_duration:.2f}s  (sau preprocess: {processed_duration:.2f}s)",
                "INFO",
            )
            log(f"  Preprocess        : {timings['preprocess']:.2f}s", "AUDIO")
            log(f"  STT               : {timings['stt']:.2f}s", "STT")
            log(f"  Rasa              : {timings['rasa']:.2f}s", "RASA")
            log(f"  TTS               : {timings['tts']:.2f}s", "TTS")
            log(
                f"  TỔNG xử lý        : {total_time:.2f}s  (RTF toàn luồng: {rtf_total:.2f}x)",
                "INFO",
            )
            log("-" * 64, "INFO")

            # 7. Lưu lại kết quả cả luồng (voice sau preprocess + STT + Rasa + audio TTS) sau khi đã gửi xong về Flutter
            if DEBUG:
                save_turn_result(
                    turn_id,
                    client_addr,
                    processed,
                    transcript,
                    state,
                    rasa_text,
                    wav_bytes,
                    total_time,
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
    run_rasa()
    warmup_models()

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

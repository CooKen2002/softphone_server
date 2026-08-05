"""
SERVER PYTHON - VOICE BOT (STT + Rasa + TTS)
UPDATED: 05/08/2026
"""

import asyncio
import io
import librosa
import requests
import time
import wave
import websockets

import scipy.signal as signal

from faster_whisper import WhisperModel
from vieneu import Vieneu

from rasa_utils import *
from config import *
from utils import *

# MARK: LOAD MODELS
log(f"Device: {DEVICE}", "INFO")

model = WhisperModel(
    MODEL_PATH,
    device=DEVICE,
    compute_type=COMPUTE_TYPE,
    cpu_threads=CPU_THREADS,  # 0 = mặc định CTranslate2, không áp dụng trên GPU
    num_workers=NUM_WORKERS,
)
log(f"LOADED model FasterWhisper at {MODEL_PATH}", "INFO")

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


def preprocess_audio(audio_data: np.ndarray, sr: int) -> np.ndarray:
    """Tiền xử lý audio gộp thành 1 bước duy nhất:
    1. Resample thẳng từ `sr` gốc về `target_sr` (16kHz, yêu cầu của Whisper) — chỉ 1 lần,
       không qua sample rate trung gian nào (thay cho việc từng phải lên 48kHz cho DFN).
    2. Khử nhiễu bằng `noisereduce` (spectral gating, thuần CPU, không cần model/GPU riêng
       như DeepFilterNet) — nhẹ và đơn giản hơn nhiều để chạy trên máy CPU-only.
    3. Normalize biên độ.
    4. Trim khoảng lặng ở đầu/cuối.
    Fail-safe: nếu bước khử nhiễu lỗi thì bỏ qua bước đó, dùng audio đã resample.
    """

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
    segments, info = model.transcribe(
        audio_data,
        language=LANGUAGE,
        beam_size=BEAM_SIZE,
        best_of=5,  # số candidate khi temperature > 0, tăng cơ hội chọn kết quả tốt
        patience=1.0,  # beam search patience, >1 tìm kỹ hơn (đổi lấy tốc độ)
        length_penalty=1.0,
        repetition_penalty=1.1,  # >1 giảm lặp từ, hữu ích với audio nhiễu/khoảng lặng ngắn
        no_repeat_ngram_size=3,  # chặn lặp cụm n-gram (tránh hallucination lặp câu)
        temperature=[
            0.0,
            0.2,
            0.4,
            0.6,
            0.8,
            1.0,
        ],  # fallback list thay vì temperature=0 cứng
        compression_ratio_threshold=2.4,  # loại segment "hallucinate" (lặp/nhiễu)
        log_prob_threshold=-1.0,  # loại segment có avg logprob quá thấp
        vad_filter=VAD_FILTER,
        vad_parameters=dict(
            min_silence_duration_ms=MIN_SILENCE_MS,
            speech_pad_ms=400,  # đệm thêm quanh vùng speech, tránh cắt mất âm đầu/cuối câu
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
        log(f"[{seg.start:.1f}s → {seg.end:.1f}s] {seg.text.strip()}", "STT")

    return clean_text(text).strip()


def request_to_rasa(text: str) -> str:
    if not text or not text.strip():
        return "default|Bạn nói gì vậy?"

    start = time.perf_counter()
    try:
        payload = {"sender": SENDER_ID, "message": text.strip()}
        response = rasa_session.post(RASA_URL, json=payload, timeout=8)
        response_data = response.json()

        rasa_text = ""
        for msg in response_data:
            if "text" in msg:
                rasa_text += msg["text"] + " "
        return rasa_text.strip()

    except Exception as e:
        log(f"Lỗi kết nối Rasa: {e}", "ERROR")
        return "default|Xin lỗi, tôi đang gặp vấn đề kỹ thuật. Bạn nói lại được không?"


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
        dummy = np.zeros(TARGET_SR, dtype=np.float32)  # 1s silence @ 16kHz
        t0 = time.perf_counter()
        preprocess_audio(dummy, TARGET_SR)

        list(model.transcribe(dummy, language=LANGUAGE, beam_size=BEAM_SIZE)[0])
        log(f" Warmup Preprocess + STT : {time.perf_counter() - t0:.2f}s", "STT")

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
    rasa_prompt = RasaPrompt()
    try:
        async for message in websocket:
            if not isinstance(message, bytes):
                log("Nhận dữ liệu không phải bytes!", "ERROR")
                continue
            # ==================== PIPELINE ====================
            # 1. Nhận & validate audio
            audio_data, sr = load_and_validate_audio_buffer(message)
            # 2. Preprocess
            processed = preprocess_audio(audio_data, sr)
            # 3. Speech-to-Text
            t0 = time.perf_counter()
            transcript = transcribe_faster_whisper(
                processed,
                initial_prompt=rasa_prompt.initial_prompt,
                hotwords=rasa_prompt.hot_word,
            )
            log(f"STT : {time.perf_counter() - t0:.2f}s", "STT")
            # 4. Rasa Dialog
            t0 = time.perf_counter()
            rasa_raw = request_to_rasa(transcript)
            log(f"↳ response: {rasa_raw.strip()[:100]}", "RASA")
            log(f"Rasa : {time.perf_counter() - t0:.2f}s", "RASA")
            # 4b. Parse state + text thật, đồng thời cập nhật prompt/hotword cho turn kế tiếp
            state, rasa_text = rasa_prompt.process_response(rasa_raw)
            log(
                f"State='{state}' | next_iPrompt='{rasa_prompt.initial_prompt}'", "RASA"
            )
            log(f"State='{state}' | next_hotword='{rasa_prompt.hot_word}'", "RASA")
            
            # 5. Text-to-Speech
            t0 = time.perf_counter()
            wav_bytes = await text_to_wav_bytes(rasa_text)
            log(f"TTS : {time.perf_counter() - t0:.2f}s", "TTS")
            # 6. Gửi về Flutter
            await websocket.send(wav_bytes)
            log(f"Đã gửi audio trả lời ({len(wav_bytes)/1024:.1f} KB)", "INFO")
    except websockets.exceptions.ConnectionClosed:
        log(f"Client disconnected: {client_addr}", "INFO")
    except Exception as e:
        log(f"Lỗi xử lý client: {e}", "ERROR")
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

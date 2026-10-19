
import asyncio
import io
import websockets
import numpy as np
import scipy.signal as signal
import scipy.io.wavfile as wav
import simpleaudio as sa
from vieneu import Vieneu

# --- CẤU HÌNH ---
WS_URI = "ws://192.168.1.26:8765"
TARGET_SR = 8000   # Tần số mẫu chuẩn 8kHz cho VoIP/Softphone
SRC_SR = 48000     # Tần số mẫu gốc của Vieneu TTS (thay thành 48000 nếu bản của bạn là 48k)

# Khởi tạo mô hình Vieneu TTS
print("Đang tải mô hình Vieneu TTS...")
tts = Vieneu()


def text_to_wav_bytes(text: str, voice: str = "Đoan Trang") -> bytes:
    """
    Chuyển văn bản thành audio 8kHz, Mono, 16-bit PCM WAV dạng bytes
    """
    # 1. Infer lấy mảng float
    audio_f32 = tts.infer(text=text, voice=voice)
    
    # 2. Resample về 8000Hz
    if SRC_SR != TARGET_SR:
        num_samples = int(len(audio_f32) * TARGET_SR / SRC_SR)
        audio_ds = signal.resample(audio_f32, num_samples)
    else:
        audio_ds = audio_f32

    # 3. Scale về int16
    audio_int16 = np.clip(audio_ds * 32767, -32768, 32767).astype(np.int16)

    # 4. Ghi vào bộ nhớ đệm bytes dạng WAV
    wav_buffer = io.BytesIO()
    wav.write(wav_buffer, TARGET_SR, audio_int16)
    return wav_buffer.getvalue()


def play_audio_bytes(audio_bytes: bytes):
    """
    Đọc file WAV từ bytes và phát ra loa, chặn cho đến khi phát xong
    """
    try:
        wav_buffer = io.BytesIO(audio_bytes)
        wave_obj = sa.WaveObject.from_wave_file(wav_buffer)
        play_obj = wave_obj.play()
        play_obj.wait_done()  # Chờ phát xong âm thanh
    except Exception as e:
        print(f"❌ Lỗi khi phát âm thanh: {e}")


async def process_text_sequence(text_list: list):
    print(f"\nKết nối tới WebSocket server: {WS_URI}...")
    
    try:
        async with websockets.connect(WS_URI) as websocket:
            print("✅ Đã kết nối thành công!\n")

            for index, text in enumerate(text_list, start=1):
                print(f"--------------------------------------------------")
                print(f"[{index}/{len(text_list)}] 🎙️ Đang gen TTS câu: '{text}'")
                
                # Step 1: Tạo bytes audio 8kHz từ text
                audio_bytes = text_to_wav_bytes(text)
                print(f"   -> Tạo thành công audio ({len(audio_bytes)} bytes)")

                # Step 2: Gửi audio đó sang WebSocket
                print("   -> Đang gửi audio sang WebSocket server...")
                await websocket.send(audio_bytes)

                # Step 3: Nhận audio phản hồi từ server
                print("   -> Đang chờ server trả về audio...")
                response = await websocket.recv()

                if isinstance(response, bytes):
                    print(f"   -> ✅ Đã nhận phản hồi ({len(response)} bytes). Đang phát audio...")
                    
                    # Step 4: Phát audio phản hồi và chờ phát xong
                    play_audio_bytes(response)
                    print("   -> 🔉 Phát xong audio phản hồi!")
                else:
                    print(f"   -> 📩 Nhận phản hồi dạng text từ server: {response}")

                # Nghỉ ngắn giữa các câu để luồng gọi tự nhiên
                await asyncio.sleep(0.3)

            print("\n🎉 Đã hoàn thành xử lý toàn bộ danh sách câu!")

    except websockets.exceptions.ConnectionClosedError:
        print("❌ Mất kết nối tới WebSocket server.")
    except Exception as e:
        print(f"❌ Đã xảy ra lỗi: {e}")


if __name__ == "__main__":
    # Danh sách câu thoại đầu vào cần gen voice và gửi tuần tự
    input_texts = [
        "tôi muốn đặt xe",
        "đón ở hà nội",
        "đến hải phòng",
        # "Cảm ơn anh chị, em đã ghi nhận thông tin đặt vé thành công."
    ]

    # Chạy client
    asyncio.run(process_text_sequence(input_texts))
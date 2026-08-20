import os
from pathlib import Path
from vieneu import Vieneu
from config import DEVICE, AUDIO_ASSETS_PATH
import soundfile as sf

if DEVICE == "cpu":
    tts = Vieneu()
else:
    tts = Vieneu(mode="v3turbo")

def create_speech(text: str, sample_rate: int = 8000):
    output_dir = Path(AUDIO_ASSETS_PATH)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Chỉ loại bỏ các ký tự hệ thống Windows cấm tuyệt đối trong tên file: \ / : * ? " < > |
    # Còn lại các dấu câu như , ? . khoảng trắng... sẽ được GIỮ NGUYÊN.
    safe_text = text.replace('/', '_').replace('\\', '_').replace(':', '_') \
                    .replace('*', '_').replace('?', '_').replace('"', '_') \
                    .replace('<', '_').replace('>', '_').replace('|', '_')
                    
    # Tạo đường dẫn file hoàn chỉnh bằng Path object
    filename_path = output_dir / f"{safe_text}.wav"
    
    # 1. Gọi TTS infer để lấy mảng dữ liệu audio
    audio = tts.infer(text=text, voice="Đoan Trang")
    
    # 2. Ép kiểu đường dẫn sang string tuyệt đối để soundfile nhận diện chính xác
    abs_filename_path = str(filename_path.resolve())
    
    # 3. Ghi dữ liệu audio ra file .wav
    sf.write(abs_filename_path, audio, sample_rate)
    
    print(f"Đã tạo audio tại: {abs_filename_path}")

if __name__ == "__main__":
    default_sentences = [
        "anh chị chắc chắn muốn hủy ạ",
        "đã hủy thành công. anh chị muốn em hỗ trợ gì không ạ",
        "nhà xe hà lan xin chào quý khách, em giúp gì cho anh chị ạ",
        "xin chào quý khách, em giúp gì cho anh chị ạ",
        "thời gian đặt không hợp lệ",
        "số điện thoại không hợp lệ",
        "không xác định được số vé đặt",
        "không xác định được tên người",
        "đã đặt xe thành công. anh chị có muốn hỗ trợ gì không ạ",
        "anh chị muốn được đón ở đâu ạ",
        "anh chị muốn đi đến đâu ạ",
        "anh chị muốn đón vào lúc nào ạ",
        "anh chị muốn loại xe nào ạ",
        "anh chị đi bao nhiêu người ạ",
        "anh chị vui lòng cung cấp họ tên ạ",
        "anh chị có muốn dùng số điện thoại này để đặt vé không. nếu không anh chị vui lòng cung cấp số điện thoại đặt vé ạ",
        "xác nhận hủy thao tác, anh chị có muốn hỗ trợ gì thêm không",
    ]
    
    for sentence in default_sentences:
        create_speech(sentence)
from huggingface_hub import snapshot_download

local_dir = snapshot_download(
    repo_id="quocphu/PhoWhisper-ct2-FasterWhisper",
    allow_patterns="PhoWhisper-medium-ct2-fasterWhisper/*",  # chỉ tải bản small, bỏ qua 4 bản còn lại
    local_dir="./models",
)
print("Đã tải về:", local_dir + "/PhoWhisper-medium-ct2-fasterWhisper")

# import os
# from transformers import WhisperForConditionalGeneration, WhisperProcessor
# import ctranslate2

# model_id = "vinai/phowhisper-small"
# original_dir = "./models/phowhisper-small-original"
# ct2_dir = "./models/phowhisper-small-ct2"

# # Bước 1: Tải và lưu model gốc từ VinAI
# print("Đang tải model và processor từ VinAI...")
# processor = WhisperProcessor.from_pretrained(model_id)
# model = WhisperForConditionalGeneration.from_pretrained(model_id)

# os.makedirs(original_dir, exist_ok=True)
# processor.save_pretrained(original_dir)
# model.save_pretrained(original_dir)
# print(f"Đã tải xong và lưu model gốc tại: {original_dir}")

# # Bước 2: Tự động convert sang định dạng CTranslate2 (faster-whisper)
# print("Đang tiến hành convert sang định dạng CTranslate2...")
# os.makedirs(ct2_dir, exist_ok=True)

# ctranslate2.converters.TransformersConverter(original_dir).convert(
#     output_dir=ct2_dir,
#     quantization="float16",  # Dùng "int8" nếu chạy trên CPU hoặc muốn tối ưu VRAM tối đa float16 nếu GPU
#     force=True
# )

# print(f"Convert thành công! Model sẵn sàng sử dụng tại: {ct2_dir}")

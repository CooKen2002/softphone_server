# import torch
# from transformers import Wav2Vec2ForCTC
# from pathlib import Path

# # Khai báo thư mục lưu trữ đầu ra
# output_dir = Path("./models")
# output_dir.mkdir(parents=True, exist_ok=True)
# onnx_path = output_dir / "wav2vec2_vietnamese.onnx"

# model_id = "nguyenvulebinh/wav2vec2-base-vietnamese-250h"

# print("1. Đang tải model PyTorch từ Hugging Face...")
# model = Wav2Vec2ForCTC.from_pretrained(model_id)
# model.eval()

# # Tạo giả lập một mảng audio đầu vào (ví dụ: 5 giây, 16000 Hz)
# dummy_input = torch.randn(1, 16000 * 5)

# print(f"2. Đang tiến hành convert sang ONNX tại: {onnx_path}...")
# torch.onnx.export(
#     model,
#     dummy_input,
#     str(onnx_path),
#     export_params=True,
#     opset_version=14,
#     do_constant_folding=True,
#     input_names=["input_values"],
#     output_names=["logits"],
#     dynamic_axes={
#         "input_values": {0: "batch_size", 1: "sequence_length"},
#         "logits": {0: "batch_size", 1: "sequence_length"}
#     }
# )

# print("Hoàn tất convert file ONNX thành công!")

from huggingface_hub import snapshot_download

local_dir = snapshot_download(
    repo_id="quocphu/PhoWhisper-ct2-FasterWhisper",
    allow_patterns="PhoWhisper-medium-ct2-fasterWhisper/*",  # chỉ tải bản small, bỏ qua 4 bản còn lại
    local_dir="./models",
)
print("Đã tải về:", local_dir + "/PhoWhisper-medium-ct2-fasterWhisper")
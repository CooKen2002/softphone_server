from vieneu import Vieneu

tts = Vieneu(
    mode="turbo_gpu"
    # v3turbo (Mặc định): Sử dụng V3TurboVieNeuTTS (48 kHz, chạy CPU qua ONNX Runtime không cần torch, GPU dùng PyTorch).
    # remote hoặc api: Sử dụng RemoteVieNeuTTS (chạy qua API).
    # fast hoặc gpu: Sử dụng FastVieNeuTTS (dùng GPU-LMDeploy).
    # turbo: Sử dụng TurboVieNeuTTS.
    # turbo_gpu: Sử dụng TurboGPUVieNeuTTS.
    # xpu: Sử dụng XPUVieNeuTTS (dành cho GPU Intel, yêu cầu cài đặt driver và torch.xpu).
    # standard: Sử dụng VieNeuTTS (CPU/GPU-GGUF).
)

def synthesize_tts(text: str) -> bytes:
    """Phần đồng bộ (blocking) của TTS — chạy trong gpu_executor để không chặn event loop."""

    audio = tts.infer(text=text, voice="Đoan Trang")  # Thường là float32 numpy array

    return audio


if __name__ == "__main__":
    sample_text = "Xin chào, đây là ví dụ TTS."
    result = synthesize_tts(sample_text)
    print("TTS output type:", type(result))
    if hasattr(result, "shape"):
        print("TTS output shape:", result.shape)


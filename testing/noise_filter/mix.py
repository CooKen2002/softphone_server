import os
import glob
import numpy as np
import librosa
import soundfile as sf

def mix_clean_with_n_noises_to_n_files(clean_path, noise_folder, snr_range, output_dir, target_sr=16000):
    """
    Trộn 1 clean audio với n file noise trong thư mục để tạo ra n file mix output riêng biệt.
    
    Parameters:
    - clean_path (str): Đường dẫn đến file audio sạch.
    - noise_folder (str): Thư mục chứa n file noise (.wav).
    - snr_range (tuple): Khoảng giá trị SNR (min_snr, max_snr) tính theo dB.
    - output_dir (str): Thư mục lưu n file output sau khi mix.
    - target_sr (int): Tần số lấy mẫu chuẩn.
    """
    # 1. Lấy tất cả các file .wav trong thư mục noise
    noise_paths = glob.glob(os.path.join(noise_folder, "*.mp3"))
    
    if not noise_paths:
        raise ValueError(f"Không tìm thấy file .wav nào trong thư mục: {noise_folder}")
    
    # Tạo thư mục lưu kết quả nếu chưa có
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Tìm thấy {len(noise_paths)} file noise. Sẽ tạo ra {len(noise_paths)} file output tương ứng.")

    # 2. Đọc sẵn file clean audio (tối ưu hiệu suất)
    clean, sr = librosa.load(clean_path, sr=target_sr)
    clean_len = len(clean)
    clean_power = np.sum(clean ** 2) / clean_len

    min_snr, max_snr = snr_range

    # 3. Lặp qua từng file noise để tạo ra n file output riêng biệt
    for i, noise_path in enumerate(noise_paths, start=1):
        noise_name = os.path.splitext(os.path.basename(noise_path))[0]
        print(f"[{i}/{len(noise_paths)}] Đang xử lý noise: {noise_name}.wav")
        
        # Đọc file noise
        noise, _ = librosa.load(noise_path, sr=target_sr)
        
        # Lặp lại noise nếu ngắn hơn clean
        if len(noise) < clean_len:
            repeats = int(np.ceil(clean_len / len(noise)))
            noise = np.tile(noise, repeats)
        
        # Cắt noise cho khớp độ dài với clean
        noise = noise[:clean_len]

        # Random một mức SNR cho file này trong khoảng cho phép
        snr = np.random.uniform(min_snr, max_snr)

        # Tính công suất và scale noise
        noise_power = np.sum(noise ** 2) / clean_len
        if noise_power == 0:
            print(f" -> Bỏ qua {noise_name} do file noise bị im lặng (power = 0).")
            continue

        target_noise_power = clean_power / (10 ** (snr / 10.0))
        scalar = np.sqrt(target_noise_power / noise_power)

        # Mix 1 clean với 1 noise đã scale
        mixed_audio = clean + (noise * scalar)

        # Chuẩn hóa (Normalize) tránh bị vỡ tiếng (clipping)
        max_val = np.max(np.abs(mixed_audio))
        if max_val > 1.0:
            mixed_audio = mixed_audio / max_val

        # Đặt tên file output và lưu lại
        output_filename = f"mixed_{noise_name}_snr_{snr:.1f}dB.wav"
        output_path = os.path.join(output_dir, output_filename)
        
        sf.write(output_path, mixed_audio, target_sr)
        print(f" -> Đã lưu: {output_path}")

    print("/nHoàn tất! Đã tạo xong tất cả các file mix.")

# ================= 📘 Ví dụ cách sử dụng =================
if __name__ == "__main__":
    clean_audio = "./assets/clean/00fee926-02b0-4582-b98a-cb72d9c2b32c.wav"
    noise_directory = "./assets/noise"      # Thư mục chứa n file noise
    output_directory = "./assets/mix"    # Thư mục sẽ chứa n file kết quả
    snr_bounds = (5.0, 5.0)                       # Khoảng SNR ngẫu nhiên (dB)

    mix_clean_with_n_noises_to_n_files(
        clean_path=clean_audio,
        noise_folder=noise_directory,
        snr_range=snr_bounds,
        output_dir=output_directory,
        target_sr=16000
    )
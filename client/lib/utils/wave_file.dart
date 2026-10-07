import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

class WavFile {
  static int lastSample = 0;

  static Future<String> saveSamplesToWav(
    List<double> samples,
    int sampleRate,
  ) async {
    // 1. Chuyển đổi List<double> (-1.0 to 1.0) sang Int16 (PCM 16-bit)
    final Int16List pcmData = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      // Ép kiểu và giới hạn trong khoảng của Int16 (-32768 đến 32767)
      pcmData[i] = (samples[i] * 32767).toInt().clamp(-32768, 32767);
    }

    // 2. Tạo Header cho file WAV (44 bytes)
    final Uint8List header = _createWavHeader(pcmData.length * 2, sampleRate);

    // 3. Kết hợp Header và Data
    final Uint8List fullWav = Uint8List(header.length + (pcmData.length * 2));
    fullWav.setAll(0, header);
    fullWav.buffer.asInt16List(header.length).setAll(0, pcmData);

    // 4. Lưu ra file
    final filePath =
        'recordings/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    final file = File(filePath);
    await file.writeAsBytes(fullWav);
    log("filePath: $filePath");
    return filePath;
  }

  /// Bọc raw PCM (16-bit, mono) thành WAV hợp lệ để gửi qua WebSocket
  static Uint8List wrapPcmAsWav(Uint8List pcmData, {int sampleRate = 16000}) {
    final Uint8List header = _createWavHeader(pcmData.length, sampleRate);
    final Uint8List fullWav = Uint8List(header.length + pcmData.length);
    fullWav.setAll(0, header);
    fullWav.setAll(header.length, pcmData);
    return fullWav;
  }

  static Future<void> savePcmBuffersToWav(
    List<Uint8List> buffers,
    String outputPath,
  ) async {
    // 1. Tính tổng kích thước dữ liệu âm thanh (không bao gồm header)
    lastSample = 0;
    int totalDataLength = 0;
    for (var buf in buffers) {
      totalDataLength += buf.length;
    }

    // 2. Tạo Header WAV (44 bytes) cho 8kHz/16bit/Mono
    final Uint8List wavHeader = _createWavHeader(totalDataLength * 2, 16000);

    // 3. Ghi vào file
    final file = File(outputPath);
    final raf = await file.open(mode: FileMode.write);
    try {
      // Ghi Header trước
      await raf.writeFrom(wavHeader);

      // Ghi lần lượt các buffer dữ liệu PCM
      for (var buffer in buffers) {
        final output_16k = upsample8kTo16k(buffer);
        await raf.writeFrom(output_16k.buffer.asUint8List());
      }

      print("Đã lưu file WAV thành công: $outputPath");
    } catch (e) {
      print("Lỗi khi ghi file: $e");
    } finally {
      await raf.close();
    }
  }

  static Uint8List _createWavHeader(int dataLength, int sampleRate) {
    final int byteRate =
        sampleRate * 1 * 2; // sampleRate * channels * bytesPerSample
    final Uint8List header = Uint8List(44);
    final ByteData bData = ByteData.view(header.buffer);

    // RIFF chunk descriptor
    bData.setUint8(0, 0x52); // R
    bData.setUint8(1, 0x49); // I
    bData.setUint8(2, 0x46); // F
    bData.setUint8(3, 0x46); // F
    bData.setUint32(4, 36 + dataLength, Endian.little);
    bData.setUint8(8, 0x57); // W
    bData.setUint8(9, 0x41); // A
    bData.setUint8(10, 0x56); // V
    bData.setUint8(11, 0x45); // E

    // fmt sub-chunk
    bData.setUint8(12, 0x66); // f
    bData.setUint8(13, 0x6D); // m
    bData.setUint8(14, 0x74); // t
    bData.setUint8(15, 0x20); // (space)
    bData.setUint32(16, 16, Endian.little); // Subchunk1Size
    bData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    bData.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    bData.setUint32(24, sampleRate, Endian.little);
    bData.setUint32(28, byteRate, Endian.little);
    bData.setUint16(32, 2, Endian.little); // BlockAlign
    bData.setUint16(34, 16, Endian.little); // BitsPerSample

    // data sub-chunk
    bData.setUint8(36, 0x64); // d
    bData.setUint8(37, 0x61); // a
    bData.setUint8(38, 0x74); // t
    bData.setUint8(39, 0x61); // a
    bData.setUint32(40, dataLength, Endian.little);

    return header;
  }

  static Uint8List converToInt(List<double> samples) {
    // 1. Chuyển đổi List<double> (-1.0 to 1.0) sang Int16 (PCM 16-bit)
    final Int16List pcmData = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      // Ép kiểu và giới hạn trong khoảng của Int16 (-32768 đến 32767)
      pcmData[i] = (samples[i] * 32767).toInt().clamp(-32768, 32767);
    }
    return pcmData.buffer.asUint8List();
  }

  /// Hàm đọc file WAV từ đường dẫn và trả về Uint8List
  static Future<Uint8List> readFileToBytes(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      return await file.readAsBytes();
    } else {
      throw Exception("Không tìm thấy file tại đường dẫn: $filePath");
    }
  }

  /// Hàm nâng cao: Đọc file và chỉ lấy phần dữ liệu âm thanh (bỏ qua Header 44 bytes)
  /// Thường dùng cho các bộ STT yêu cầu Raw PCM
  static Future<Uint8List> readRawPcmOnly(String filePath) async {
    final bytes = await readFileToBytes(filePath);

    if (bytes.length > 44) {
      // Trích xuất từ byte thứ 44 đến hết
      return bytes.sublist(44);
    }
    return bytes;
  }

  static void debugPcmEndianness(Uint8List rawPcm) {
    // Lấy 2 byte đầu tiên
    final byteData = ByteData.sublistView(rawPcm);

    // Đọc thử theo 2 cách
    int le = byteData.getInt16(0, Endian.little);
    int be = byteData.getInt16(0, Endian.big);

    log("Giá trị nếu là Little Endian: $le");
    log("Giá trị nếu là Big Endian: $be");
  }

  static void checkVolume(Uint8List rawPcm) {
    final byteData = ByteData.sublistView(rawPcm);
    int maxSample = 0;

    for (int i = 0; i < rawPcm.length; i += 2) {
      int sample = byteData.getInt16(i, Endian.little);
      if (sample.abs() > maxSample) maxSample = sample.abs();
    }

    log("Mẫu âm thanh lớn nhất đạt được: $maxSample");
    if (maxSample < 500) {
      log("CẢNH BÁO: Âm thanh quá nhỏ, Vosk có thể không nghe thấy gì!");
    }
  }

  static Float32List _convertToFloat32(Uint8List bytes) {
    Int16List int16Data = bytes.buffer.asInt16List();
    return Float32List.fromList(int16Data.map((e) => e / 32768.0).toList());
  }

  static Int16List upsample8kTo16k(Uint8List input8k) {
    // log("input8k: ${input8k.length}");
    // Số lượng mẫu mới sẽ gấp đôi mẫu cũ
    final output16k = Int16List(input8k.length ~/ 2 * 2);
    // log("output16k: ${output16k.length}");

    // Đọc theo sample 16 bit
    final input8k_16 = input8k.buffer.asInt16List(
      input8k.offsetInBytes,
      input8k.lengthInBytes ~/ 2,
    );
    int srcSampc = input8k_16.length;
    // log("input8k_16: $srcSampc");

    // Xử lý DC offset
    int dcAcc = 0;
    int sum = 0;
    for (int i = 0; i < srcSampc; i++) {
      sum += input8k_16[i];
    }

    final int dc = sum ~/ srcSampc;
    dcAcc = (dcAcc * 7 + dc) ~/ 8;
    final dcOffset = dcAcc;

    // Sample cuối của frame trước (boundary handling)
    lastSample = input8k_16[srcSampc - 1];

    for (int i = 0; i < srcSampc; i++) {
      int currentSample = (input8k_16[i] - dcOffset).clamp(-32768, 32767);
      // Mẫu thứ nhất: Giữ nguyên mẫu cũ
      output16k[i * 2] = currentSample;

      int nextSample = i + 1 < srcSampc
          ?
            /* Có sample kế tiếp trong frame hiện tại */
            input8k_16[i + 1] - dcOffset
          /* Sample cuối frame — dùng last_sample của frame trước */
          : lastSample - dcOffset;

      nextSample = nextSample.clamp(-32768, 32767);

      // Mẫu thứ hai: Nội suy (trung bình cộng của mẫu hiện tại và mẫu kế tiếp)
      output16k[i * 2 + 1] = ((currentSample + nextSample) ~/ 2).clamp(
        -32768,
        32767,
      );
    }

    return output16k;
  }
}

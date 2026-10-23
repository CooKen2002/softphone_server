import 'dart:typed_data';
import 'dart:math' as math;

Uint8List upsample8kTo16k(Uint8List pcm8) {
  final src = pcm8.buffer.asInt16List(pcm8.offsetInBytes, pcm8.length ~/ 2);
  final out = Int16List(src.length * 2);
  for (var i = 0; i < src.length; i++) {
    final next = i + 1 < src.length ? src[i + 1] : src[i];
    out[2 * i] = src[i];
    out[2 * i + 1] = (src[i] + next) >> 1;
  }
  return out.buffer.asUint8List();
}

Uint8List floatsToPcm16(List<double> samples) {
  final out = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    out[i] = (samples[i].clamp(-1.0, 1.0) * 32767).round();
  }
  return out.buffer.asUint8List();
}

Uint8List wavHeader(int pcmLen, {int sampleRate = 16000}) {
  final b = ByteData(44);
  void s(int o, String v) {
    for (var i = 0; i < v.length; i++) b.setUint8(o + i, v.codeUnitAt(i));
  }

  s(0, 'RIFF');
  b.setUint32(4, 36 + pcmLen, Endian.little);
  s(8, 'WAVE');
  s(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  s(36, 'data');
  b.setUint32(40, pcmLen, Endian.little);
  return b.buffer.asUint8List();
}

/// Gộp kênh và đổi sample rate. Hạ tần số dùng trung bình hộp (đỡ rè),
/// nâng tần số dùng nội suy tuyến tính.
Int16List resampleInt16(Int16List src, int from, int to) {
  if (from == to || src.isEmpty) return src;
  final outLen = (src.length * to / from).floor();
  final out = Int16List(outLen);
  final ratio = from / to;
  for (var i = 0; i < outLen; i++) {
    if (ratio > 1) {
      final s = (i * ratio).floor();
      var e = ((i + 1) * ratio).floor();
      if (e <= s) e = s + 1;
      if (e > src.length) e = src.length;
      var sum = 0;
      for (var j = s; j < e; j++) {
        sum += src[j];
      }
      out[i] = sum ~/ (e - s);
    } else {
      final pos = i * ratio;
      final i0 = pos.floor();
      final i1 = math.min(i0 + 1, src.length - 1);
      final f = pos - i0;
      out[i] = (src[i0] * (1 - f) + src[i1] * f).round();
    }
  }
  return out;
}

/// Nhận WAV PCM16 bất kỳ (mono/stereo, mọi sample rate), trả về WAV PCM16
/// mono 8 kHz với header 44 byte, đúng định dạng của AudioTxStream.playWav.
/// Ném FormatException nếu không đọc được hoặc không phải PCM16.
Uint8List wavToTelephonyWav(Uint8List wav) {
  if (wav.length < 12 ||
      String.fromCharCodes(wav, 0, 4) != 'RIFF' ||
      String.fromCharCodes(wav, 8, 12) != 'WAVE') {
    throw const FormatException('Không phải file WAV');
  }
  final bd = ByteData.sublistView(wav);
  int? format, channels, rate, bits;
  var dataStart = -1, dataLen = 0;
  var pos = 12;
  while (pos + 8 <= wav.length) {
    final id = String.fromCharCodes(wav, pos, pos + 4);
    final size = bd.getUint32(pos + 4, Endian.little);
    final body = pos + 8;
    if (id == 'fmt ' && body + 16 <= wav.length) {
      format = bd.getUint16(body, Endian.little);
      channels = bd.getUint16(body + 2, Endian.little);
      rate = bd.getUint32(body + 4, Endian.little);
      bits = bd.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      dataStart = body;
      dataLen = math.min(
          size, wav.length - body); // WAV stream có thể ghi size = 0xFFFFFFFF
      break;
    }
    pos = body + size + (size & 1);
  }
  if (format != 1 ||
      bits != 16 ||
      channels == null ||
      rate == null ||
      dataStart < 0) {
    throw const FormatException('Chỉ hỗ trợ WAV PCM 16-bit');
  }

  dataLen &= ~1;
  // copy để chắc chắn căn hàng 2 byte trước khi nhìn dưới dạng Int16
  final pcm = Uint8List.fromList(wav.sublist(dataStart, dataStart + dataLen))
      .buffer
      .asInt16List();

  Int16List mono;
  if (channels == 1) {
    mono = pcm;
  } else {
    mono = Int16List(pcm.length ~/ channels);
    for (var i = 0; i < mono.length; i++) {
      var sum = 0;
      for (var c = 0; c < channels; c++) {
        sum += pcm[i * channels + c];
      }
      mono[i] = sum ~/ channels;
    }
  }

  final out = resampleInt16(mono, rate, 8000).buffer.asUint8List();
  return Uint8List.fromList(
      [...wavHeader(out.length, sampleRate: 8000), ...out]);
}

import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:vad/vad.dart';
import 'pcm_utils.dart';

class SpeechDetector {
  SpeechDetector({
    this.modelPath, // thư mục chứa silero_vad_legacy.onnx
    this.preRollMs = 400,
    this.tailSilenceMs = 700,
    this.positiveThreshold = 0.5,
    this.negativeThreshold = 0.35,
    this.minSpeechFrames = 4,
    bool debug = false,
  }) : _vad = VadHandler.create(isDebug: debug, onLog: log) {
    _subs
      ..add(_vad.onSpeechStart.listen((_) => _starts.add(null)))
      ..add(_vad.onSpeechEnd
          .listen((samples) => _segments.add(floatsToPcm16(samples))))
      ..add(_vad.onError.listen((e) => log('VAD error: $e')));
  }

  static const _frameSamples = 1536;
  static const _msPerFrame = _frameSamples / 16000 * 1000; // 96 ms
  static const _chunkBytes = _frameSamples * 2;

  final String? modelPath;
  final double preRollMs, tailSilenceMs, positiveThreshold, negativeThreshold;
  final int minSpeechFrames;

  final VadHandler _vad;
  static const defaultModelPath = 'packages/flutter_voice_chatbot/windows/libs/';
  final _subs = <StreamSubscription<dynamic>>[];
  final _segments = StreamController<Uint8List>.broadcast();
  final _starts = StreamController<void>.broadcast();
  StreamController<Uint8List>? _input;
  Uint8List _carry = Uint8List(0);

  /// Mỗi phần tử là một câu nói: PCM16 mono **16 kHz**.
  Stream<Uint8List> get segments => _segments.stream;
  Stream<void> get speechStarts => _starts.stream;

  Future<void> start() async {
    await stop();
    _input = StreamController<Uint8List>();
    await _vad.startListening(
      // lỗi sẽ ném ra cho nơi gọi
      model: 'legacy',
      frameSamples: _frameSamples,
      audioStream: _input!.stream,
      baseAssetPath: modelPath ?? defaultModelPath,
      minSpeechFrames: minSpeechFrames,
      preSpeechPadFrames: (preRollMs / _msPerFrame).ceil(),
      redemptionFrames: (tailSilenceMs / _msPerFrame).ceil(),
      positiveSpeechThreshold: positiveThreshold,
      negativeSpeechThreshold: negativeThreshold,
    );
  }

  /// Nhận frame cuộc gọi 8 kHz (320 byte), tự resample và gom đủ 1536 mẫu.
  void addFrame8k(Uint8List frame) {
    final input = _input;
    if (input == null) return;
    final data = Uint8List.fromList([..._carry, ...upsample8kTo16k(frame)]);
    var offset = 0;
    while (data.length - offset >= _chunkBytes) {
      input.add(Uint8List.sublistView(data, offset, offset + _chunkBytes));
      offset += _chunkBytes;
    }
    _carry = Uint8List.sublistView(data, offset);
  }

  Future<void> stop() async {
    try {
      await _vad.stopListening().timeout(const Duration(seconds: 2));
    } catch (e) {
      log('VAD stop: $e');
    }
    await _input?.close();
    _input = null;
    _carry = Uint8List(0);
  }

  Future<void> dispose() async {
    await stop();
    for (final s in _subs) {
      await s.cancel();
    }
    await _vad.dispose();
    await _segments.close();
    await _starts.close();
  }
}

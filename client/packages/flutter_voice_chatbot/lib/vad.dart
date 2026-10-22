import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:vad/vad.dart';

class VAD {
  VadHandler? _vadHandler;
  Stream<Uint8List>? audioStream;
  Function(VadHandler vadHandler)? onListener;
  
  static const int _frameSamples = 1536;
  static const double _msPerFrame = _frameSamples / 16000 * 1000; // 96ms

  void create() {
    if (_vadHandler != null) return;
    _vadHandler = VadHandler.create(isDebug: true);
    onListener?.call(_vadHandler!);
  }

  void startListening({
    double preRollMs = 5000,
    double tailSilenceMs = 2000,
    double positiveSpeechThreshold = 0.5,
    double negativeSpeechThreshold = 0.35,
    int minSpeechFrames = 4,
  }) async {
    try {
      final int preSpeechPadFrames = (preRollMs / _msPerFrame).ceil();
      final int redemptionFrames = (tailSilenceMs / _msPerFrame).ceil();

      await _vadHandler?.startListening(
        baseAssetPath: "windows/libs",
        audioStream: audioStream,
        frameSamples: _frameSamples,
        minSpeechFrames: minSpeechFrames,
        preSpeechPadFrames: preSpeechPadFrames,
        redemptionFrames: redemptionFrames,
        positiveSpeechThreshold: positiveSpeechThreshold,
        negativeSpeechThreshold: negativeSpeechThreshold,
      );
    } catch (e) {
      log(e.toString());
    }
  }

  void dispose() {
    stopListening();
    _vadHandler?.dispose();
    _vadHandler = null;
  }

  void stopListening() async {
    await _vadHandler?.stopListening();
  }
}
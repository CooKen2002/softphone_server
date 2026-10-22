import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_soft_phone/flutter_soft_phone.dart';

/// Một nơi tiêu thụ âm thanh cuộc gọi (ghi file, gửi server, VAD...).
abstract class CallAudioSink {
  void onCallStart(CallSession call);
  void onFrame(Uint8List frame);
  Future<void> onCallEnd();
}

class CallAudioPipeline {
  CallAudioPipeline(this._phone, this._sinks) {
    _phone.onCallChanged = _onCallChanged;
    _sub = _phone.audioIn.frames.listen(_onFrame);
  }

  final SoftPhoneController _phone;
  final List<CallAudioSink> _sinks;
  StreamSubscription<Uint8List>? _sub;
  bool _active = false;

  void _onCallChanged(CallSession? call) {
    if (call != null && call.isActive && !_active) {
      _active = true;
      for (final s in _sinks) { s.onCallStart(call); }
    } else if (call == null && _active) {
      _active = false;
      for (final s in _sinks) { s.onCallEnd(); }
    }
  }

  void _onFrame(Uint8List frame) {
    if (!_active) return;
    for (final s in _sinks) { s.onFrame(frame); }
  }

  void dispose() {
    _sub?.cancel();
    _phone.onCallChanged = null;
  }
}

class RxRecorderSink implements CallAudioSink {
  final _buf = BytesBuilder(copy: false);
  String _remote = '';

  @override
  void onCallStart(CallSession call) { _buf.clear(); _remote = call.remoteNumber; }

  @override
  void onFrame(Uint8List frame) => _buf.add(frame);

  @override
  Future<void> onCallEnd() async {
    final pcm = _buf.takeBytes();
    // ghi file như RxCapture.stopAndSave ở trên
  }
}
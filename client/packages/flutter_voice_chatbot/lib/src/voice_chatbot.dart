import 'dart:async';
import 'dart:typed_data';
import 'dart:developer';
import 'chatbot_transport.dart';
import 'pcm_utils.dart';
import 'speech_detector.dart';

enum BotState { idle, listening, waitingResponse, botSpeaking }

class VoiceChatbot {
  VoiceChatbot({
    required this.transport,
    required this.detector,
    this.playReply,
    this.cancelReply,
    this.responseTimeout = const Duration(seconds: 20),
    this.resumeDelay = const Duration(milliseconds: 300),
    this.normalizeReply = true,
  });

  final ChatbotTransport transport;
  final SpeechDetector detector;

  /// Ví dụ phone.audioOut.playWav. Future hoàn thành khi đã đẩy hết dữ liệu.
  final Future<void> Function(Uint8List wav)? playReply;

  /// Ví dụ phone.audioOut.reset. Gọi khi dừng bot.
  final void Function()? cancelReply;

  /// Quá thời gian này mà server không gửi audio thì bot quay lại nghe.
  final Duration responseTimeout;

  /// Nghỉ một chút sau khi phát xong rồi mới nghe, tránh bắt phải đuôi âm thanh.
  final Duration resumeDelay;

  /// Kiểm tra/đổi WAV server trả về sang 8 kHz mono (server hiện đã trả đúng
  /// định dạng nên có thể đặt false để bỏ qua bước này).
  final bool normalizeReply;

  final _text = StreamController<String>.broadcast();
  final _state = StreamController<BotState>.broadcast();
  final _errors = StreamController<Object>.broadcast();
  final _subs = <StreamSubscription<dynamic>>[];

  BotState _current = BotState.idle;
  Timer? _timeout;
  Future<void> _playChain = Future.value();
  int _pendingPlays = 0;
  bool _disposed = false;

  Stream<String> get texts => _text.stream;
  Stream<BotState> get states => _state.stream;
  Stream<Object> get errors => _errors.stream;
  BotState get state => _current;

  /// Bắt đầu cho một cuộc gọi: kết nối, báo thông tin cuộc gọi cho server
  /// ("công ty|số điện thoại") rồi đợi audio lời chào.
  Future<bool> start(
    Stream<Uint8List> pcm8kFrames, {
    required String company,
    required String phone,
  }) async {
    await stop();
    _subs.add(transport.messages.listen(_onServer)); // nghe trước khi connect
    try {
      if (!await transport.connect()) {
        _error(StateError('Không kết nối được ${transport.url}'));
        await stop();
        return false;
      }
      log('[Bot] đã kết nối ${transport.url}');

      // Gửi thông tin cuộc gọi NGAY, trước khi khởi động VAD,
      // để server chuẩn bị lời chào trong lúc VAD đang load model.
      final info = _callInfo(company, phone);
      _set(BotState.waitingResponse);
      transport.sendText(info);
      log('[Bot] đã gửi thông tin cuộc gọi: "$info"');
      _armTimeout();

      await detector.start();
      log('[Bot] VAD đã chạy');
    } catch (e) {
      log('[Bot] start lỗi: $e');
      _error(e);
      await stop();
      return false;
    }

    _subs
      ..add(detector.segments.listen(_onSegment))
      ..add(pcm8kFrames.listen((f) {
        if (_current == BotState.listening) detector.addFrame8k(f);
      }));
    return true;
  }

  /// Server tách bằng "|" và yêu cầu đúng 2 phần, nên loại ký tự này khỏi dữ liệu.
  static String _callInfo(String company, String phone) =>
      '${_clean(company)}|${_clean(phone)}';
  static String _clean(String s) => s.replaceAll('|', ' ').trim();

  void _onSegment(Uint8List pcm16k) {
    if (_current != BotState.listening) return;
    transport.send(Uint8List.fromList(
        [...wavHeader(pcm16k.length, sampleRate: 16000), ...pcm16k]));
    _set(BotState.waitingResponse);
    _armTimeout();
  }

  void _onServer(ServerMessage m) {
    switch (m) {
      case TextReply(:final text):
        _text.add(text);
        if (_current == BotState.waitingResponse) _armTimeout();
      case AudioReply(:final wav):
        _enqueuePlay(wav);
      case ServerClosed():
        _timeout?.cancel();
        _error(StateError('Server đã đóng kết nối'));
        _set(BotState.idle);
    }
  }

  void _enqueuePlay(Uint8List wav) {
    _timeout?.cancel();
    _pendingPlays++;
    _set(BotState.botSpeaking);
    _playChain = _playChain.then((_) async {
      try {
        final data = normalizeReply ? wavToTelephonyWav(wav) : wav;
        await playReply?.call(data);
      } catch (e) {
        _error(e);
      } finally {
        _pendingPlays--;
        if (_pendingPlays <= 0) {
          _pendingPlays = 0;
          if (resumeDelay > Duration.zero) {
            await Future<void>.delayed(resumeDelay);
          }
          if (_current == BotState.botSpeaking && _pendingPlays == 0) {
            _set(BotState.listening); // tới lượt người gọi nói
          }
        }
      }
    });
  }

  void _armTimeout() {
    _timeout?.cancel();
    _timeout = Timer(responseTimeout, () {
      if (_current != BotState.waitingResponse) return;
      _error(TimeoutException('Server không phản hồi', responseTimeout));
      _set(BotState.listening);
    });
  }

  Future<void> stop() async {
    _timeout?.cancel();
    _pendingPlays = 0;
    cancelReply?.call();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await transport.disconnect();
    await detector.stop();
    _set(BotState.idle);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await stop();
    _disposed = true;
    await detector.dispose();
    await _text.close();
    await _state.close();
    await _errors.close();
  }

  void _set(BotState s) {
    if (_disposed || _current == s) return;
    _current = s;
    _state.add(s);
  }

  void _error(Object e) {
    if (!_disposed && !_errors.isClosed) _errors.add(e);
  }
}

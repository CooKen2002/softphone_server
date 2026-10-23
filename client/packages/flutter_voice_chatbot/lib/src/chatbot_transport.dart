import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

sealed class ServerMessage {
  const ServerMessage();
}

class TextReply extends ServerMessage {
  const TextReply(this.text);
  final String text;
}

class AudioReply extends ServerMessage {
  const AudioReply(this.wav);
  final Uint8List wav;
}

class ServerClosed extends ServerMessage {
  const ServerClosed();
}

class ChatbotTransport {
  ChatbotTransport(this.url);
  Uri url;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _messages = StreamController<ServerMessage>.broadcast();

  Stream<ServerMessage> get messages => _messages.stream;
  bool get isConnected => _channel != null;

  Future<bool> connect() async {
    if (_channel != null) return true;
    try {
      final ch = WebSocketChannel.connect(url);
      await ch.ready; // chỉ gán sau khi kết nối thật
      _channel = ch;
      _sub = ch.stream.listen(
        _onData,
        onError: (Object e) => log('WS error: $e'),
        onDone: () {
          _channel = null;
          _messages.add(const ServerClosed());
        },
      );
      return true;
    } catch (e) {
      log('WS connect failed: $e');
      return false;
    }
  }

  void _onData(dynamic d) {
    if (d is String) {
      _messages.add(TextReply(d));
    } else if (d is List<int>) {
      _messages.add(AudioReply(Uint8List.fromList(d)));
    }
  }

  void send(Uint8List bytes) => _channel?.sink.add(bytes);
  void sendText(String text) => _channel?.sink.add(text);

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink
          .close(status.normalClosure)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
    _channel = null;
  }
}

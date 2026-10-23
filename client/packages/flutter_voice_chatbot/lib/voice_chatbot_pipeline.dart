// import "dart:io";
import 'dart:developer';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import "package:flutter_soft_phone/audio_stream.dart";
import "package:flutter_voice_chatbot/flutter_voice_chatbot.dart";
// import "package:web_socket_channel/web_socket_channel.dart";

class VoiceChatbot {
  // Cấu hình ws
  String webSocketURL = "";
  bool isConnected = false;
  bool isWaitingResponse = false; // Đang đợi phản hồi từ server
  bool isBotPlaying = false; 
  WebSocketChannel? channel;
  // VAD
  late final SpeechDetector vad;
  // Audio buffer
  late final AudioRxStream audioIn;

  Future<bool> connectWebSocketChatBot() async {
    if (channel != null) return true;
    try {
      final wsUrl = Uri.parse(webSocketURL); // MARK: WEBSOCKET
      channel = WebSocketChannel.connect(wsUrl);
      await channel?.ready;
      isConnected = true;
      return true;
    } catch (e) {
      log(e.toString());
    }
    return false;
  }

  Future<bool> disconnectWebSocketChatBot() async {
    try {
      channel?.sink.close(status.normalClosure);
      channel = null;
      isConnected = false;
      return true;
    } catch (e) {
      log(e.toString());
    }
    // Ngắt kết nối luôn trả về đúng
    channel = null;
    return true;
  }
}

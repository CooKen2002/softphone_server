import 'dart:math';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class VoiceChatBotController extends ChangeNotifier {
  String webSocketURL = "";
  bool isConnected = false;
  bool isWaitingResponse = false; // Đang đợi phản hồi từ server
  bool isBotPlaying = false; 
  WebSocketChannel? channel;
  Future<bool> connectWebSocketChatBot() async {
    if (channel != null) return true;
    try {
      final wsUrl = Uri.parse(webSocketURL); // MARK: WEBSOCKET
      channel = WebSocketChannel.connect(wsUrl);
      await channel?.ready;
      isConnected = true;
      return true;
    } catch (e) {
      log("$e" as num);
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
      log("$e" as num);
    }
    // Ngắt kết nối luôn trả về đúng
    channel = null;
    return true;
  }
}

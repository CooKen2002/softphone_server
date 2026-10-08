import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:talkie_v2/models/action_result.dart';
import 'package:talkie_v2/models/admin_model.dart';
import 'package:talkie_v2/screens/talkie/talkie_record_audio.dart';
import 'package:talkie_v2/screens/talkie/talkie_user_search_page.dart';
import 'package:talkie_v2/services/admin_service.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/screens/talkie/audio_message.dart';
import 'package:toastification/toastification.dart';
import 'package:web_socket_channel/io.dart';

class TalkieScreen extends StatefulWidget {
  const TalkieScreen({super.key});

  @override
  State<TalkieScreen> createState() => _TalkieScreenState();
}

class _TalkieScreenState extends State<TalkieScreen> {
  String playingID = "";
  bool isOnline = true;
  bool isConnectWs = false;
  bool isShowScrollToBottom = false;
  List<VoiceMessage> messages = [];
  final player = AudioPlayer();
  ScrollController scrollController = ScrollController();
  double scrollPosition = 0;
  IOWebSocketChannel? webSocket;
  User? toUser;
  TextEditingController textController = TextEditingController(
    text: "Tất cả tài khoản",
  );
  AdminService service = AdminService();
  Timer? timer;

  void getMessages() async {
    VoiceMessagesResponse response = await service.listVoiceMessages();
    if (response.errorMessage.isEmpty) {
      setState(() {
        messages = response.messages;
      });
      scrollPosition = scrollController.position.maxScrollExtent;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void connectWebSocket() async {
    if (isConnectWs) {
      return;
    }

    isConnectWs = true;
    webSocket = IOWebSocketChannel.connect(
      '${baseUrl.replaceAll("http", "ws")}/chat/${base64.encode(loginResponse.tokenID.codeUnits)}',
    );

    try {
      await webSocket?.ready;
      setState(() {
        isOnline = isConnectWs;
      });

      webSocket?.stream.listen(
        (message) {
          if (mounted) handleWebSocketMessage(message);
        },
        onDone: resetWebSocketState,
        onError: (error) {
          resetWebSocketState();
        },
      );
    } catch (e) {
      resetWebSocketState();
    }
  }

  void handleWebSocketMessage(String value) async {
    Map<String, dynamic> json = jsonDecode(value);
    VoiceMessage message = VoiceMessage.fromJson(json);
    setState(() {
      messages.add(message);
    });
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      curve: Curves.easeOut,
      duration: Duration(milliseconds: 300),
    );
    playAudio(message.id);
  }

  void resetWebSocketState() {
    webSocket = null;
    isConnectWs = false;
    if (mounted && context.mounted) {
      setState(() {
        isOnline = false;
      });
    }
  }

  void playAudio(String value) async {
    await player.stop();
    setState(() {
      playingID = value;
    });
    String url = "$baseUrl/rest/app/getVoiceMessage/$value.mp3";
    await player.play(UrlSource(url));
  }

  void starMarkVoiceMessage(String id, bool starMark) async {
    ActionResult response = await service.starMarkVoiceMessage(id, starMark);
    if (response.errorMessage.isEmpty) {
      setState(() {});
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void sendVoiceMessage(File file) async {
    int userID = toUser != null ? toUser!.userID : 0;
    VoiceMessagesResponse response = await service.sendVoiceMessage(
      userID,
      file.path,
      file.readAsBytesSync(),
      0,
    );
    if (response.errorMessage.isEmpty) {
      setState(() {
        messages.add(response.message);
      });
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      );
      file.delete();
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    getMessages();
    connectWebSocket();
    player.onPlayerComplete.listen((event) {
      setState(() {
        playingID = "";
      });
    });
    scrollController.addListener(() {
      scrollPosition = scrollController.position.pixels;
      setState(() {
        isShowScrollToBottom =
            scrollPosition < scrollController.position.maxScrollExtent
            ? true
            : false;
      });
    });
    timer = Timer.periodic(Duration(seconds: 2), (timer) => connectWebSocket());
  }

  @override
  void dispose() {
    timer?.cancel();
    webSocket?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: isOnline ? Colors.green : Colors.red,
                ),
              ),
              const Text(
                "Talkie",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                hoverColor: Colors.transparent,
                icon: const Icon(Icons.refresh),
                onPressed: getMessages,
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                ListView.separated(
                  controller: scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    VoiceMessage model = messages[index];
                    return AudioMessage(
                      isPlay: model.id == playingID,
                      createDate: model.createDate!,
                      starMark: model.starMark,
                      isOwner: model.userID == loginResponse.userID,
                      userName: model.userName,
                      actionReply: () {
                        setState(() {
                          toUser = User(model.userID, model.userName);
                        });
                        textController.text = model.userName;
                      },
                      actionPlay: () => playAudio(model.id),
                      actionStarMark: (startMark) {
                        starMarkVoiceMessage(model.id, startMark);
                      },
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 5);
                  },
                ),
                Visibility(
                  visible: isShowScrollToBottom,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.grey),
                        ),
                        color: Colors.white,
                        hoverColor: Colors.transparent,
                        onPressed: () {
                          scrollController.animateTo(
                            scrollController.position.maxScrollExtent,
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                        icon: Icon(Icons.arrow_downward),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 45,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: TextFormField(
              style: TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIconColor: Colors.black,
                prefixIcon: Icon(Icons.person),
                suffixIconColor: Colors.white,
                suffixIcon: toUser != null
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            toUser = null;
                          });
                          textController.text = "Tất cả tài khoản";
                        },
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Icon(Icons.close, size: 18),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(3),
              ),
              readOnly: true,
              controller: textController,
              mouseCursor: SystemMouseCursors.click,
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      contentPadding: const EdgeInsets.all(0),
                      content: TalkieUserSearchPage(
                        onSelectItem: (user) {
                          setState(() {
                            toUser = user;
                          });
                          textController.text = toUser!.userName;
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          TalkieRecordAudio(onRecorded: sendVoiceMessage),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

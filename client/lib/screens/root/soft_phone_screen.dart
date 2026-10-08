import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talkie_v2/models/soft_phone_model.dart';
import 'package:talkie_v2/screens/soft_phone/call_history_screen.dart';
import 'package:talkie_v2/screens/soft_phone/call_incoming.dart';
import 'package:talkie_v2/screens/soft_phone/call_log_details.dart';
import 'package:talkie_v2/screens/soft_phone/call_outgoing.dart';
import 'package:talkie_v2/screens/soft_phone/soft_phone_setting.dart';
import 'package:talkie_v2/services/soft_phone_service.dart';
import 'package:talkie_v2/utils/bare_sip.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/dynamic_library_loader.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/string_utils.dart';
import 'package:talkie_v2/utils/wave_file.dart';
import 'package:toastification/toastification.dart';
import 'package:vad/vad.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class SoftPhoneScreen extends StatefulWidget {
  const SoftPhoneScreen({super.key});

  @override
  State<SoftPhoneScreen> createState() => _SoftPhoneScreenState();
}

class _SoftPhoneScreenState extends State<SoftPhoneScreen> {
  bool isOnline = false;
  bool isRegister = true;
  bool isCallSucces = false;
  bool isCallInComing = false;
  bool isWaitingResponse = false; // Đang đợi phản hồi từ server
  bool isBotPlaying = false; // Bot đang phát âm thanh cho khách nghe
  int countOnline = 0;
  List<UA> uAList = [];
  TextEditingController phoneNoController = TextEditingController();
  String callingNum = "";
  String callingName = "Unknow";

  Isolate? bareSipIsolate;


  late AudioStreamReader audioReader;
  late AudioStreamWriter audioWriter;
  bool isAutoAnswer = false;

  static const String companyName = "hà lan";

  // VAD
  final VAD vad = VAD();
  StreamController<Uint8List>? scVad;
  WebSocketChannel? channel;
  // bool isConnect = false;
  // List<Uint8List> buffer16k = [];

  ValueNotifier<List<CallLog>> historyList = ValueNotifier([]);
  ValueNotifier<String> uA = ValueNotifier("");
  ValueNotifier<String> phoneName = ValueNotifier("");
  ValueNotifier<STATE_SOFT_PHONE> stateSoftPhone = ValueNotifier(
    STATE_SOFT_PHONE.HISTORY,
  );
  ValueNotifier<STATE_CALL> stateCall = ValueNotifier(STATE_CALL.CALLING);
  ValueNotifier<String> stateRecognizeVoice = ValueNotifier("");

  final player = AudioPlayer();
  // final voskBuffer = BytesBuilder();
  final speechBuffer = BytesBuilder();
  bool isRecordCalling = false;
  final List<Uint8List> _preRollFrames = [];
  static const int _preRollFrameCount = 20;

  List<String> sampleAnswer = [
    "khonghieunoigi.wav",
    "noichamlai.wav",
    "noilainhe.wav",
    "noinhanhmotchut.wav",
  ];
  final random = math.Random();

  SoftPhoneService service = SoftPhoneService();

  TextEditingController wavName = TextEditingController();
  TextEditingController audioBook = TextEditingController();

  Future<void> getAllCallHistory() async {
    CallLogsResponse result = await service.listCallLogs("", "");
    if (result.errorMessage.isEmpty) {
      if (result.callLogs.isNotEmpty) {
        historyList.value = result.callLogs;
      }
    } else {
      showToast(result.errorMessage, ToastificationType.error);
    }
  }

  Future<void> getAllUa() async {
    String userStringsJson = await readData(F_ALL_USER) ?? "";
    if (userStringsJson.isEmpty) return;

    List<String> userStrings = List<String>.from(jsonDecode(userStringsJson));
    uAList = userStrings
        .map((userString) => UA.fromJson(jsonDecode(userString)))
        .toList();

    Future.delayed(Duration(seconds: 3), () {
      for (var ua in uAList) {
        if (ua.autoConnect!) {
          bareSip.uaNew(ua.getUri());
        }
      }
    });
  }

  Future<bool> connectWebSocketChatBot() async {
    if (channel != null) return true;
    try {
      final wsUrl = Uri.parse('ws://192.168.1.26:8765'); // MARK: WEBSOCKET
      channel = WebSocketChannel.connect(wsUrl);
      await channel?.ready;
      player.onPlayerComplete.listen((_) {
        setState(() {
          isBotPlaying = false;
          isWaitingResponse =
              false; // 🔓 MỞ KHÓA: Đã phát xong, cho phép VAD bắt đầu nhận giọng nói mới
        });
        log("🔓 Đã phát xong audio từ Bot. Mở khóa VAD cho lượt tiếp theo.");
      });
      channel?.stream.listen(
        (message) async {
          // log(message);
          final tempFile = File('recordings/answer.wav');

          // 2. Ghi dữ liệu binary vào file tạm
          await tempFile.writeAsBytes(message);
          // 2.5 Đánh dấu bot đang chuẩn bị phát âm thanh
          setState(() {
            isBotPlaying = true;
          });
          // 3. Phát file
          await player.stop();
          await player.play(DeviceFileSource(tempFile.path));

          // 4. Gửi bare sip
          audioWriter.readFileSendFrame(tempFile.path);
        },
        onError: (e) {
          log("⚠️ WebSocket ChatBot lỗi: $e");
          channel =
              null; // cho phép connectWebSocketChatBot() kết nối lại lần sau
          setState(() {
            isBotPlaying = false;
            isWaitingResponse =
                false; // 🔓 mở khóa VAD ngay, tránh khóa vĩnh viễn khi WS rớt giữa chừng
          });
        },
        onDone: () {
          log("⚠️ WebSocket ChatBot đã đóng kết nối.");
          channel = null;
          setState(() {
            isBotPlaying = false;
            isWaitingResponse = false;
          });
        },
      );

      return true;
    } on SocketException {
      showToast("SocketException", ToastificationType.error);
    } on WebSocketChannelException {
      showToast("Không thể kết nối đến ChatBot", ToastificationType.error);
    } catch (e) {
      log(e.toString());
    }

    return false;
  }

  Future<bool> disconnectWebSocketChatBot() async {
    try {
      channel?.sink.close(status.normalClosure);
      channel = null;
      return true;
    } catch (e) {
      log(e.toString());
    }
    // Ngắt kết nối luôn trả về đúng
    channel = null;
    return true;
  }

  // Future<void> getAutoAnswer(bool auto) async {
  //   String autoAnswerStringsJson = await readData(F_AUTO_ANSWER) ?? "";
  //   if (autoAnswerStringsJson.isEmpty) return;
  //   // kết nối đến chatbot
  //   bool ret = await connectWebSocketChatBot();
  //   if (ret) {
  //     setState(() {
  //       isAutoAnswer = true;
  //     });
  //   }
  // }
  Future<void> restoreAutoAnswer() async {
    String saved = await readData(F_AUTO_ANSWER) ?? "";
    setState(() {
      isAutoAnswer = saved == "true";
    });
  }

  void changeModeAutoAnser() async {
    isAutoAnswer = !isAutoAnswer;
    // saveData(F_AUTO_ANSWER, isAutoAnswer ? "true" : "");
    // setState(() {});
    bool ret = false;
    if (isAutoAnswer) {
      saveData(F_AUTO_ANSWER, "true");
      ret = await connectWebSocketChatBot();
      if (!ret) {
        isAutoAnswer = false;
      }
    } else {
      saveData(F_AUTO_ANSWER, "");
      ret = await disconnectWebSocketChatBot();
    }

    if (ret) {
      setState(() {});
    }
  }

  void getCallContact(String query) async {
    phoneName.value = "";
    CallLogsResponse result = await service.getCallContact(query);
    if (result.errorMessage.isEmpty) {
      phoneName.value = result.callLog.fullName;
      callingName = phoneName.value;
    } else {
      showToast(result.errorMessage, ToastificationType.error);
    }
  }

  void onCallStop() {
    if (uA.value.isEmpty) return;
    bareSip.hangup(uA.value);
    phoneNoController.text = "";
    phoneName.value = "";
    // Gọi hàm kết thúc cuộc gọi
    stateSoftPhone.value = STATE_SOFT_PHONE.HISTORY;
    stateCall.value = STATE_CALL.CALLING;
  }

  void onCallAccept() {
    if (uA.value.isEmpty) return;
    bareSip.answer(uA.value);
    // Gọi hàm chấp nhận cuộc gọi
    stateCall.value = STATE_CALL.ACCPECT;
  }

  void callGoingOut() {
    if (phoneNoController.text.isEmpty) {
      phoneName.value = "Số điện thoại không được để trống !!!";
      return;
    }
    if (phoneNoController.text.length < 10) {
      phoneName.value = "Số điện thoại không đúng !!!";
      return;
    }

    if (uA.value.isEmpty) {
      phoneName.value = "Bạn phải đăng ký hot line !!!";
      return;
    }

    callingNum = phoneNoController.text;
    isCallSucces = false;
    isCallInComing = false;
    bareSip.dial(uA.value, callingNum);
    stateCall.value = STATE_CALL.CALLING;
    stateSoftPhone.value = STATE_SOFT_PHONE.OUTGOING;
  }

  bool checkUaOnline(UA model) {
    for (var uA in uAList) {
      if (uA.status == STATUS_UA.CONNECTED && uA.hotLine == model.hotLine) {
        return true;
      }
    }
    return false;
  }

  Future<void> initSoftPhone() async {
    bareSipIsolate ??= await Isolate.spawn(
      DynamicLibraryLoader.isolateEntryPoint,
      "baresip-window.dll",
    );
    bareSip = BareSip(DynamicLibraryLoader.dylib);
    bareSip.onProcessCallBack = eventbareSip;
    bareSip.startListener();

    audioReader = AudioStreamReader(DynamicLibraryLoader.dylib);
    audioReader.dataOnVAD = onDataVad; // MARK: NOTE
    // audioReader.dataOnVOSK = onDataVosk;
    audioReader.dataOnVOSK = onDataSpeechBuffer;
    audioWriter = AudioStreamWriter(DynamicLibraryLoader.dylib);

    vad.onListener = setupVadHandler;
    vad.create();
    scVad = StreamController();
    vad.audioStream = scVad?.stream;
    vad.startListening();

    await connectWebSocketChatBot();
    await restoreAutoAnswer();
  }

  void resetSoftPhone() {
    bareSip.stop();
    bareSipIsolate?.kill();
    bareSipIsolate = null;
    isOnline = false;
    vad.stopListening();
    scVad?.close();
    scVad = null;
    disconnectWebSocketChatBot(); // WS giờ gắn vòng đời softphone, không phải vòng đời auto-answer
  }

  void onDataVad(Uint8List data) {
    final Int16List data_16 = WavFile.upsample8kTo16k(data);
    scVad?.add(data_16.buffer.asUint8List());
  }

  // void onDataVosk(Uint8List data) {
  //   if (isRecordCalling) {
  //     final Int16List data_16 = WavFile.upsample8kTo16k(data);
  //     voskBuffer.add(data_16.buffer.asUint8List());
  //   }
  // }
  void onDataSpeechBuffer(Uint8List data) {
    final Int16List data_16 = WavFile.upsample8kTo16k(data);
    final bytes = data_16.buffer.asUint8List();

    if (isRecordCalling) {
      speechBuffer.add(bytes);
    } else {
      // Luôn trượt giữ N frame gần nhất, kể cả khi chưa xác nhận speech,
      // để khi onSpeechStart bắn thì có sẵn audio đệm prepend vào đầu buffer.
      _preRollFrames.add(bytes);
      if (_preRollFrames.length > _preRollFrameCount) {
        _preRollFrames.removeAt(0);
      }
    }
  }

  void saveCallLog(
    int userID,
    bool isCallSucces,
    bool isCallInComing, {
    String? pathFile,
    DateTime? start,
    DateTime? end,
  }) async {
    CallLog model = CallLog();
    if (isCallSucces && isCallInComing) {
      model.type = TYPE_IN;
      model.fullName = callingName;
      model.callingName = callingName;
      model.callingNumber = callingNum;
      model.calledName = uA.value;
      model.calledNumber = uA.value;
      model.pathFileRecord = pathFile;
      model.data = File(pathFile!).readAsBytesSync();
    } else if (!isCallSucces && isCallInComing) {
      model.type = TYPE_FIN;
      model.fullName = callingName;
      model.callingName = callingName;
      model.callingNumber = callingNum;
      model.calledName = uA.value;
      model.calledNumber = uA.value;
    } else if (isCallSucces && !isCallInComing) {
      model.type = TYPE_OUT;
      model.fullName = callingName;
      model.calledName = callingName;
      model.calledNumber = callingNum;
      model.callingName = uA.value;
      model.callingNumber = uA.value;
      model.pathFileRecord = pathFile;
      model.data = File(pathFile!).readAsBytesSync();
    } else {
      model.type = TYPE_FOUT;
      model.fullName = callingName;
      model.calledName = callingName;
      model.calledNumber = callingNum;
      model.callingName = uA.value;
      model.callingNumber = uA.value;
    }

    model.startDate ??= DateTime.now();
    model.endDate ??= DateTime.now();
    CallLogsResponse result = await service.storeCallLog(model);
    if (result.errorMessage.isEmpty) {
      getAllCallHistory();
    } else {
      showToast(result.errorMessage, ToastificationType.error);
    }
  }

  String stringFromCharCode(int index, List<int> arrByte) {
    String ret = "";
    for (var i = index; i < arrByte.length; i++) {
      ret += String.fromCharCode(arrByte[i]);
    }
    return ret;
  }

  void eventbareSip(int type, String name, List<int> msgByte) {
    switch (type) {
      case 2: // Đăng ký/ Huỷ đăng ký thành công
        String hotLine = String.fromCharCodes(msgByte);
        int index = uAList.indexWhere((u) => hotLine.startsWith(u.hotLine!));
        // log("$index: $hotLine");
        if (index == -1) return;
        if (isRegister) {
          if (uAList[index].status == STATUS_UA.CONNECTED) return;
          uAList[index].status = STATUS_UA.CONNECTED;
          uA.value = uAList[index].hotLine!;
          setState(() {
            countOnline++;
            isOnline = true;
          });
        } else {
          uAList[index].status = STATUS_UA.NOTCONNECT;
          countOnline--;
          if (countOnline <= 0) {
            isOnline = false;
            uA.value = "";
            bareSip.stop();
            resetSoftPhone();
          }
          setState(() {});
        }
        isRegister = true;
        break;
      case 3: // Đăng ký thất bại
        // if (callState == CALL.IDLE) {
        //   // registerUA(null);
        // }
        break;
      case 1: // Đang đăng ký
        isRegister = true;
        break;
      case 4: // Đang huỷ đăng ký
        isRegister = false;
        break;
      case 5: // Báo hiệu có cuộc gọi đến
        audioReader.startReading();
        String sip = String.fromCharCodes(msgByte);
        // String hotLine = parts[2];
        callingNum = sip
            .split(":")[1]
            .split("@")[0]; //sip:0916767869@172.28.0.19
        isCallSucces = false;
        isCallInComing = true;
        stateSoftPhone.value = STATE_SOFT_PHONE.INCOMING;
        stateCall.value = STATE_CALL.CALLING;

        Future.delayed(Duration(seconds: 2), () {
          if (isAutoAnswer) {
            onCallAccept();
          }
        });

        break;
      case 9: // Kết thúc cuộc gọi
        // String sip = parts[1];
        if (!isCallSucces) {
          saveCallLog(loginResponse.userID, isCallSucces, isCallInComing);
          callingName = "Unknow";
        }

        // Refesh các trạng thái của Bare
        audioReader.stop();
        stateRecognizeVoice.value = "";

        stateSoftPhone.value = STATE_SOFT_PHONE.HISTORY;
        stateCall.value = STATE_CALL.CALLING;
        // voskBuffer.clear();
        speechBuffer.clear();
        break;
      case 8: // Chấp nhận cuộc gọi đến # MARK: CallGoingOut ACP EV
        // reset state
        isWaitingResponse = false;
        isBotPlaying = false;
        isRecordCalling = false;
        // voskBuffer.clear();
        speechBuffer.clear();
        _preRollFrames.clear();
        audioReader.startReading();
        if (sendCallSessionInfo()) {
          isWaitingResponse = true;
        }
        stateCall.value = STATE_CALL.ACCPECT;
        isCallSucces = true;
        break;
      case 10: // Ghi âm thành công
        //./19-01-2026_10-39-32_02473083088_to_0916767869.mp3
        String pathTemp = String.fromCharCodes(
          msgByte,
        ); //recordings/19-01-2026_10-39-32_02473083088_to_0916767869.mp3
        if (isCallSucces) {
          String fileName = pathTemp.split("/")[2];
          List<String> date = fileName.split("_"); //19-01-2026_10-39-32
          DateTime startDate = "${date[0]}_${date[1]}".dateCallTime();
          DateTime endDate = DateTime.now();

          saveCallLog(
            loginResponse.userID,
            isCallSucces,
            isCallInComing,
            pathFile: pathTemp,
            start: startDate,
            end: endDate,
          );
          callingName = "Unknow";
        }

        try {
          File file = File(pathTemp);
          file.delete();
        } catch (e) {
          log("Delete file error: $pathTemp");
        }
        break;
      default:
        break;
    }
  }

  void setupVadHandler(VadHandler? vadHandler) {
    if (vadHandler == null) {
      log("vadHandler null");
    }

    File fileTest = File("recordings/vad_test.pcm");

    vadHandler?.onSpeechStart.listen((_) {
      if (isWaitingResponse || isBotPlaying) {
        return;
      }
      isRecordCalling = true;
      stateRecognizeVoice.value = "Start detect speech";

      for (final f in _preRollFrames) {
        speechBuffer.add(f);
      }
      _preRollFrames.clear();
    });

    vadHandler?.onSpeechEnd.listen((List<double> samples) async {
      if (isWaitingResponse || isBotPlaying) {
        // voskBuffer.clear();
        speechBuffer.clear();
        return;
      }
      isRecordCalling = false;
      stateRecognizeVoice.value = "Start recognize voice";
      // if (voskBuffer.toBytes().isNotEmpty) {
      if (speechBuffer.toBytes().isNotEmpty) {
        // final bytes = voskBuffer.takeBytes();
        final bytes = speechBuffer.takeBytes();
        final wavBytes = WavFile.wrapPcmAsWav(bytes, sampleRate: 16000);
        fileTest.writeAsBytes(wavBytes);
        channel?.sink.add(wavBytes);
        setState(() {
          isWaitingResponse = true;
        });
        log(
          "🔒 Đã gửi audio lên WS. Khóa VAD, chuyển sang trạng thái đợi phản hồi...",
        );
      }
    });

    vadHandler?.onRealSpeechStart.listen((_) {
      stateRecognizeVoice.value = "Real speech";
      audioWriter.stopSendFrame();
    });

    // vadHandler?.onSpeechEnd.listen((List<double> samples) async {
    //   isRecordCalling = false;
    //   stateRecognizeVoice.value = "Start recognize voice";
    //   // Gửi frame cho server
    //   if (voskBuffer.toBytes().isNotEmpty) {
    //     final bytes = voskBuffer.takeBytes();
    //     fileTest.writeAsBytes(bytes);
    //     channel?.sink.add(bytes);
    //   }
    // });

    vadHandler?.onVADMisfire.listen((_) {
      log('VAD misfire detected.');
      isRecordCalling =
          false; // ✅ fix: trước đây thiếu, khiến isRecordCalling mắc kẹt true nếu misfire xảy ra
      speechBuffer.clear(); //    sau khi onSpeechStart nhưng trước onSpeechEnd
      _preRollFrames
          .clear(); //    reset luôn pre-roll để tránh audio cũ lẫn vào lượt kế tiếp
      // voskBuffer.clear();
      // String audio = sampleAnswer[random.nextInt(4)];
      // answerAudio("assets/$audio");
      // player.play(AssetSource(audio));
    });

    vadHandler?.onError.listen((String message) {
      log('VAD error: $message');
      isRecordCalling = false; // ✅ fix tương tự onVADMisfire
      speechBuffer.clear();
      _preRollFrames.clear();
      // voskBuffer.clear();
      // String audio = sampleAnswer[random.nextInt(4)];
      // answerAudio("assets/$audio");
      // player.play(AssetSource(audio));
    });
  }

  void answerAudio(String pathAudio) async {
    final ByteData data = await rootBundle.load(pathAudio);
    final Uint8List bytes = data.buffer.asUint8List();
    final Uint8List rawPcm = bytes.sublist(44);
    audioWriter.readDataSendFrame(rawPcm);
  }

  // void requestMicroPhonePermission() async {
  //   var status = await Permission.microphone.request();
  //   if (!status.isGranted) {
  //     showToast(
  //       "Ứng dụng cần cấp quyền microphone để có thể sử dụng",
  //       ToastificationType.error,
  //     );
  //   }
  // }

  @override
  void initState() {
    super.initState();
    Directory("recordings").create(recursive: true);
    // requestMicroPhonePermission();
    getAllUa();
    getAllCallHistory();
    initSoftPhone();
  }

  // MARK: SendCallInfo
  bool sendCallSessionInfo() {
    if (channel == null) {
      log("Chưa kết nối WebSocket ChatBot, bỏ qua gửi call info");
      return false;
    }
    if (callingNum.isEmpty) {
      log("callingNum rỗng, bỏ qua gửi call info");
      return false;
    }

    final String payload = "$companyName|$callingNum";
    try {
      channel?.sink.add(payload);
      log("Đã gửi call info: $payload");
      return true;
    } catch (e) {
      log("Lỗi gửi call info: $e");
      return false;
    }
  }

  @override
  void dispose() {
    resetSoftPhone();
    audioReader.stop();
    super.dispose();
  }
  // MARK: UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(minWidth: 300, maxWidth: 500),
          padding: EdgeInsets.all(5),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border.symmetric(horizontal: BorderSide(width: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.circle,
                      color: isOnline ? Colors.green : Colors.red,
                    ),
                    SizedBox(
                      height: 35,
                      child: ValueListenableBuilder(
                        valueListenable: uA,
                        builder: (context, value, child) {
                          if (value.isEmpty) {
                            return Center(
                              child: Text(
                                "Chưa đăng ký",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[400],
                                ),
                              ),
                            );
                          }

                          List<String> list = [];
                          for (var e in uAList) {
                            if (e.status == STATUS_UA.CONNECTED) {
                              list.add(e.hotLine!);
                            }
                          }

                          return DropdownButton<String>(
                            underline: Container(),
                            focusColor: Colors.transparent,
                            value: uA.value,
                            items: list.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.split('@').first),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              uA.value = value;
                            },
                          );
                        },
                      ),
                    ),
                    IconButton(
                      constraints: BoxConstraints(minWidth: 10, minHeight: 10),
                      padding: EdgeInsets.zero,
                      hoverColor: Colors.transparent,
                      icon: Icon(
                        Icons.hdr_auto,
                        color: isAutoAnswer ? Colors.green : Colors.grey,
                      ),
                      onPressed: changeModeAutoAnser,
                    ),
                    IconButton(
                      constraints: BoxConstraints(minWidth: 10, minHeight: 10),
                      padding: EdgeInsets.zero,
                      hoverColor: Colors.transparent,
                      icon: Icon(Icons.refresh),
                      onPressed: getAllCallHistory,
                    ),
                    IconButton(
                      constraints: BoxConstraints(minWidth: 10, minHeight: 10),
                      padding: EdgeInsets.zero,
                      hoverColor: Colors.transparent,
                      icon: Icon(Icons.history_sharp),
                      onPressed: showCallHistoryDialog,
                    ),
                    IconButton(
                      constraints: BoxConstraints(minWidth: 10, minHeight: 10),
                      padding: EdgeInsets.zero,
                      hoverColor: Colors.transparent,
                      icon: Icon(Icons.settings),
                      onPressed: showSettingDialog,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 5),
              
              Stack(
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextFormField(
                      // focusNode: phoneNoFn,
                      textAlignVertical: TextAlignVertical.center,
                      cursorHeight: 18,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: "Nhập số để gọi",
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      controller: phoneNoController,
                      mouseCursor: SystemMouseCursors.click,
                      onChanged: getCallContact,
                      onEditingComplete: callGoingOut,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: InkWell(
                        onTap: callGoingOut,
                        child: const Icon(Icons.phone, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 5),
              
              ValueListenableBuilder(
                valueListenable: phoneName,
                builder: (context, value, child) {
                  return Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: value.endsWith("!!!") ? Colors.red : Colors.black,
                    ),
                  );
                },
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: stateSoftPhone,
                  builder: (context, state, child) {
                    if (state == STATE_SOFT_PHONE.HISTORY) {
                      return CallHistoryScreen(
                        notifier: historyList,
                        onCall: (callHistory) {
                          if (!isOnline) {
                            phoneName.value =
                                "Bạn phải đăng ký đầu số trước !!!";
                            return;
                          }
                          phoneNoController.text = callHistory
                              .getPhoneNo()
                              .split("@")[0];
                          phoneName.value = callHistory.getPhoneName();
                          callingName = callHistory.getPhoneName();
                          callGoingOut();
                        },
                      );
                    }
                    if (state == STATE_SOFT_PHONE.INCOMING) {
                      return CallInComing(
                        callingNumber: callingNum,
                        callState: stateCall,
                        onAccept: onCallAccept,
                        onHangup: onCallStop,
                        onStop: onCallStop,
                        onSetPhoneName: (name) => callingName = name,
                      );
                    }
                    if (state == STATE_SOFT_PHONE.OUTGOING) {
                      return CallOutgoing(
                        callingName: callingName,
                        callingNumber: callingNum,
                        callState: stateCall,
                        onAccept: onCallAccept,
                        onHangup: onCallStop,
                        onStop: onCallStop,
                        onSetPhoneName: (name) => callingName = name,
                      );
                    }
                    if (state == STATE_SOFT_PHONE.CONTACT) return Container();
                    return Container();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showCallHistoryDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return Builder(
          builder: (context) {
            var width = MediaQuery.of(context).size.width;
            var height = MediaQuery.of(context).size.height;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              content: Container(
                width: width * 0.85,
                height: height * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.hardEdge,
                child: CallLogDetails(),
              ),
            );
          },
        );
      },
    );
  }

  void showSettingDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return Builder(
          builder: (context) {
            var width = MediaQuery.of(context).size.width;
            var height = MediaQuery.of(context).size.height;
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  contentPadding: const EdgeInsets.all(0),
                  content: Container(
                    width: width * 0.85,
                    height: height * 0.85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: SoftPhoneSetting(
                      uaList: uAList,
                      uA: uA,
                      onRegister: (model) {
                        // Kiểm tra ua đã online chưa?
                        if (checkUaOnline(model)) return;

                        // Kiểm tra bare đã init chưa?
                        if (bareSipIsolate == null) {
                          initSoftPhone();
                        }

                        Future.delayed(Duration(seconds: 1), () {
                          bareSip.uaNew(model.getUri());
                        });

                        Future.delayed(Duration(seconds: 2), () {
                          if (context.mounted) {
                            setState(() {});
                          }
                        });
                      },
                      onUnRegister: (model) {
                        bareSip.unRegister(model.hotLine!);
                        Future.delayed(Duration(seconds: 1), () {
                          if (context.mounted) {
                            setState(() {});
                          }
                        });
                      },
                      onRefesh: (model) {
                        setState(() {});
                      },
                      onStop: () {
                        uA.value = "";
                        bareSip.stop();
                        resetSoftPhone();
                        if (context.mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

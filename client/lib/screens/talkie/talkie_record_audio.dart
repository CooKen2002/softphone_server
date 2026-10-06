import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:talkie_v2/models/admin_model.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:toastification/toastification.dart';

class TalkieRecordAudio extends StatefulWidget {
  final Function(File file) onRecorded;
  const TalkieRecordAudio({super.key, required this.onRecorded});

  @override
  State<TalkieRecordAudio> createState() => _TalkieRecordAudioState();
}

class _TalkieRecordAudioState extends State<TalkieRecordAudio> {
  int second = 0;
  String filePath = "";
  TalkieRecordState state = TalkieRecordState.waiting;
  RecordIconState iconState = RecordIconState.mic;
  final audioRecord = AudioRecorder();
  Timer? timer;
  bool isKeyBoardPressed = false;
  final FocusNode _focusNode = FocusNode();

  void deleteFile(String path) async {
    timer?.cancel();
    String audioFilePath = path;
    File audioFile = File(audioFilePath);
    if (audioFile.existsSync()) {
      await audioFile.delete();
    }

    setState(() {
      state = TalkieRecordState.waiting;
      iconState = RecordIconState.mic;
    });
  }

  void startRecord() async {
    timer?.cancel();
    setState(() {
      state = TalkieRecordState.recording;
      iconState = RecordIconState.mic;
      second = 0;
    });

    filePath = "${DateTime.now().formatDateTimeCompact}.mp3";

    await audioRecord.start(
      const RecordConfig(autoGain: true, noiseSuppress: true),
      path: filePath,
    );

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        second += 1;
      });
    });
  }

  void stopRecord() async {
    timer?.cancel();
    String? path = await audioRecord.stop();
    bool isValid = checkSizeFile(path!);
    if (isValid) {
      widget.onRecorded(File(path));
    } else {
      deleteFile(path);
      showToast("Bản ghi âm quá ngắn!", ToastificationType.error);
    }
    setState(() {
      second = 0;
      state = TalkieRecordState.waiting;
    });
  }

  bool checkSizeFile(String path) {
    bool ret = true;
    File file = File(path);
    int sizeInByte = file.lengthSync();
    if (sizeInByte <= 3000) {
      ret = false;
    }
    return ret;
  }

  String title() {
    switch (state) {
      case TalkieRecordState.delete:
        return "Xóa tệp ghi âm";
      case TalkieRecordState.freeHand:
        return "Chế độ rảnh tay";
      case TalkieRecordState.recording:
        return "Sang trái để xóa, sang phải để rảnh tay";
      default:
        return "Nhấn và giữ để ghi âm";
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKeyboardKey.f3) {
          if (event is KeyDownEvent && !isKeyBoardPressed) {
            isKeyBoardPressed = true;
            startRecord();
          } else if (event is KeyUpEvent) {
            isKeyBoardPressed = false;
            stopRecord();
          }
        }
      },
      child: SizedBox(
        height: 100,
        child: Column(
          children: [
            Text(state == TalkieRecordState.waiting ? "" : "${second}s"),
            Text(title()),
            SizedBox(height: 3),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: DragTarget(
                        onAcceptWithDetails: (details) {
                          deleteFile(filePath);
                        },
                        onWillAcceptWithDetails: (details) {
                          setState(() {
                            iconState = RecordIconState.delete;
                          });
                          return true;
                        },
                        onLeave: (data) {
                          setState(() {
                            iconState = RecordIconState.mic;
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return state == TalkieRecordState.recording ||
                                  state == TalkieRecordState.freeHand
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: GestureDetector(
                                    onTap: () => deleteFile(filePath),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                )
                              : Container();
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Draggable(
                        data: 1,
                        feedback: Container(),
                        onDragEnd: (details) {
                          if (state == TalkieRecordState.freeHand) {
                            setState(() {
                              iconState = RecordIconState.send;
                            });
                          }
                        },
                        childWhenDragging: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: primaryColor, width: 2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: iconWidget(),
                        ),
                        child: GestureDetector(
                          onTapDown: (details) {
                            startRecord();
                          },
                          onTapUp: (details) {
                            stopRecord();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryColor, width: 2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: iconWidget(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: DragTarget(
                        onAcceptWithDetails: (data) {
                          setState(() {
                            state = TalkieRecordState.freeHand;
                          });
                        },
                        onWillAcceptWithDetails: (data) {
                          setState(() {
                            iconState = RecordIconState.lock;
                          });
                          return true;
                        },
                        onLeave: (data) {
                          setState(() {
                            iconState = RecordIconState.mic;
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return state == TalkieRecordState.freeHand ||
                                  state == TalkieRecordState.waiting
                              ? Container()
                              : Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Icon(
                                    Icons.lock_open,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget iconWidget() {
    switch (iconState) {
      case RecordIconState.lock:
        return Icon(Icons.lock, color: Colors.green);
      case RecordIconState.delete:
        return Icon(Icons.delete, color: Colors.red);
      case RecordIconState.send:
        return Icon(Icons.send, color: primaryColor);
      default:
        return Icon(Icons.mic, color: primaryColor, size: 30);
    }
  }
}

enum RecordIconState { lock, delete, mic, send }

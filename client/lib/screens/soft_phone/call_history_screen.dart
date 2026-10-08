import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talkie_v2/models/soft_phone_model.dart';
import 'package:talkie_v2/screens/soft_phone/contact_detail.dart';
import 'package:talkie_v2/screens/soft_phone/player_screen.dart';
import 'package:talkie_v2/services/soft_phone_service.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:toastification/toastification.dart';

class CallHistoryScreen extends StatefulWidget {
  final Function(CallLog value) onCall;
  final ValueNotifier<List<CallLog>> notifier;

  const CallHistoryScreen({
    super.key,
    required this.onCall,
    required this.notifier,
  });
  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  AudioPlayer player = AudioPlayer();
  CallLog? selectedCallLog;
  TextEditingController filterController = TextEditingController();
  SoftPhoneService service = SoftPhoneService();

  //MARK: Player
  Future<void> _play(CallLog callLog) async {
    if (selectedCallLog != null) {
      if (player.state == PlayerState.playing) {
        await _stop();
      }
    }
    setState(() {
      selectedCallLog = callLog;
      selectedCallLog!.isPlayBack = true;
    });
    String url = "$baseUrl/rest/app/getCallMp3/${callLog.fileID}.mp3";
    await player.play(UrlSource(url));
  }

  Future<void> _stop() async {
    await player.stop();
    if (selectedCallLog != null) {
      setState(() {
        selectedCallLog!.isPlayBack = false;
        selectedCallLog = null;
      });
    }
  }

  Icon getCallIcon(String callStatus) {
    switch (callStatus) {
      case TYPE_FIN:
        return const Icon(Icons.phone_callback, color: Colors.red);
      case TYPE_FOUT:
        return const Icon(Icons.phone_forwarded, color: Colors.red);
      case TYPE_IN:
        return const Icon(Icons.phone_callback_sharp, color: Colors.green);
      case TYPE_OUT:
        return const Icon(Icons.phone_forwarded, color: Colors.green);
      default:
        return const Icon(Icons.phone, color: Colors.green);
    }
  }

  void saveCallContact(CallLog callLog) async {
    CallLog? contact = await showDialog(
      context: context,
      builder: (context) {
        return ContactDetail(contact: callLog);
      },
    );
    if (contact == null) return;

    CallContactsResponse result = await service.saveCallContact(
      contact.getPhoneNo(),
      contact.token,
      contact.getPhoneName(),
    );

    if (result.errorMessage.isEmpty) {
      setState(() {
        callLog.calledName = contact.fullName;
        callLog.fullName = contact.fullName;
      });
      showToast("Cập nhập thành công", ToastificationType.success);
    } else {
      showToast(result.errorMessage, ToastificationType.error);
    }
  }

  void playOrPause(CallLog model) {
    if (model.isPlayBack) {
      _stop();
    } else {
      _play(model);
    }
  }

  @override
  void initState() {
    super.initState();
    player.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 360, maxHeight: 400),
      child: Column(
        spacing: 10,
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: widget.notifier,
              builder: (context, list, child) {
                if (list.isEmpty) {
                  return Center(child: Text("Không có lịch sử cuộc gọi nào"));
                }

                list.sort((a, b) => b.startDate!.compareTo(a.startDate!));
                String query = filterController.text;
                List<CallLog> callLogs = list
                    .where((i) => i.getPhoneNo().contains(query))
                    .toList();
                return ListView.builder(
                  itemCount: callLogs.length,
                  itemBuilder: (context, index) {
                    final model = callLogs[index];
                    model.indexPlay = index;
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: model.isPlayBack
                                ? PlayerScreen(
                                    player: player,
                                    onPlayDone: _stop,
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: getCallIcon(model.type),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              model.getPhoneName(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              parseNumber(model.getPhoneNo()),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: IconButton(
                                      padding: const EdgeInsets.all(0.0),
                                      iconSize: 16,
                                      onPressed: () => saveCallContact(model),
                                      icon: Icon(Icons.info_outline),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: IconButton(
                                      padding: const EdgeInsets.all(0.0),
                                      iconSize: 16,
                                      onPressed: () => widget.onCall(model),
                                      icon: Icon(Icons.refresh),
                                    ),
                                  ),
                                  Visibility(
                                    visible:
                                        !model.type.startsWith("F") &&
                                        model.fileID.isNotEmpty,
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: IconButton(
                                        padding: const EdgeInsets.all(0.0),
                                        iconSize: 16,
                                        onPressed: () => playOrPause(model),
                                        icon: model.isPlayBack
                                            ? Icon(Icons.pause)
                                            : Icon(Icons.play_arrow),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                model.startDate!.formatToMinute,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              const Text(
                "Tìm kiếm",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    // focusNode: filterFn,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                    ),
                    controller: filterController,
                    mouseCursor: SystemMouseCursors.click,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(width: 5),
            ],
          ),
        ],
      ),
    );
  }

  SizedBox buildIconButton(Icon icon, void Function() onPressed) {
    return SizedBox(
      height: 20,
      width: 20,
      child: IconButton(
        padding: const EdgeInsets.all(0.0),
        iconSize: 16,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }

  String parseNumber(String? num) {
    if (num == null) return "";
    return num.split("@")[0];
  }
}

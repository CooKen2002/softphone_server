import 'dart:async';

import 'package:flutter/material.dart';
import 'package:talkie_v2/models/soft_phone_model.dart';
import 'package:talkie_v2/services/soft_phone_service.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:toastification/toastification.dart';

class CallOutgoing extends StatefulWidget {
  const CallOutgoing({
    super.key,
    required this.callingNumber,
    required this.callingName,
    required this.callState,
    this.stateRecognizeVoice,
    this.recognizeText,
    this.onAccept,
    this.onStop,
    this.onHangup,
    this.onSetPhoneName,
  });
  final String callingNumber;
  final String callingName;
  final ValueNotifier<STATE_CALL> callState;
  final ValueNotifier<String>? stateRecognizeVoice;
  final ValueNotifier<String>? recognizeText;
  final Function()? onAccept;
  final Function()? onStop;
  final Function()? onHangup;
  final Function(String phoneName)? onSetPhoneName;
  @override
  State<CallOutgoing> createState() => _CallOutgoingState();
}

class _CallOutgoingState extends State<CallOutgoing> {
  ValueNotifier<String> phoneName = ValueNotifier("Unkown");
  Timer? timer;
  ValueNotifier<int> seconds = ValueNotifier(0);
  Color buttonStop = Colors.red;
  SoftPhoneService service = SoftPhoneService();

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      seconds.value++;
    });
  }

  void getCallContact() async {
    CallLogsResponse result = await service.getCallContact(
      widget.callingNumber,
    );
    if (result.errorMessage.isEmpty) {
      phoneName.value = result.callLog.fullName;
      widget.onSetPhoneName?.call(phoneName.value);
    } else {
      showToast(result.errorMessage, ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    phoneName.value = widget.callingName;
    if (phoneName.value.isEmpty) {
      getCallContact();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: widget.callState,
              builder: (context, value, child) {
                if (value == STATE_CALL.CALLING) {
                  return const Text("gọi đến ...");
                } else if (value == STATE_CALL.ACCPECT) {
                  startTimer();
                  return ValueListenableBuilder(
                    valueListenable: seconds,
                    builder: (context, value, child) {
                      return Text(formatTime(value));
                    },
                  );
                }
                return const Text("Chờ kết nối ...");
              },
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: phoneName,
              builder: (context, value, child) {
                return Text(
                  value.isEmpty ? "Unkown" : value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            Text(
              widget.callingNumber,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: widget.callState,
              builder: (context, value, child) {
                return InkWell(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onHover: (value) {
                    setState(() {
                      buttonStop = value ? Colors.red.shade200 : Colors.red;
                    });
                  },
                  onTap: () {
                    widget.onStop?.call();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: buttonStop,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    width: 50,
                    height: 50,
                    child: Icon(Icons.call_end),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/soft_phone_model.dart';
import '../services/soft_phone_service.dart';
import '../utils/global.dart';
import 'package:toastification/toastification.dart';

class CallInComing extends StatefulWidget {
  const CallInComing({
    super.key,
    required this.callingNumber,
    required this.callState,
    this.onAccept,
    this.onStop,
    this.onHangup,
    this.onSetPhoneName,
  });
  final String callingNumber;
  final ValueNotifier<STATE_CALL> callState;
  final Function()? onAccept;
  final Function()? onStop;
  final Function()? onHangup;
  final Function(String phoneName)? onSetPhoneName;
  @override
  State<CallInComing> createState() => _CallInComingState();
}

class _CallInComingState extends State<CallInComing> {
  ValueNotifier<String> phoneName = ValueNotifier("");
  Timer? timer;
  int seconds = 0;
  Color buttonAccept = Colors.green;
  Color buttonStop = Colors.red;
  SoftPhoneService service = SoftPhoneService();

  String formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) {
        setState(() {
          seconds++;
        });
      }
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
    getCallContact();
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
                if (value == STATE_CALL.CALLING) {
                  return const Text("đang gọi ...");
                } else if (value == STATE_CALL.ACCPECT) {
                  startTimer();
                  return Text(formatTime(seconds));
                }
                return const Text("Chờ kết nối ...");
              },
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: widget.callState,
              builder: (context, value, child) {
                List<Widget> buttonList = [];
                if (value != STATE_CALL.ACCPECT) {
                  buttonList.add(
                    InkWell(
                      onTap: () {
                        widget.onAccept?.call();
                      },
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onHover: (value) {
                        setState(() {
                          buttonAccept = value
                              ? Colors.green.shade200
                              : Colors.green;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: buttonAccept,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        width: 50,
                        height: 50,
                        child: Icon(Icons.call),
                      ),
                    ),
                  );
                }

                buttonList.add(
                  InkWell(
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
                  ),
                );

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 50,
                  children: buttonList,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

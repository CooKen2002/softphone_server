import 'package:flutter/material.dart';
import 'package:talkie_v2/models/soft_phone_model.dart';
import 'package:talkie_v2/services/soft_phone_service.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:toastification/toastification.dart';

class RecentCallScreen extends StatefulWidget {
  const RecentCallScreen({super.key});

  @override
  State<RecentCallScreen> createState() => _RecentCallScreenState();
}

class _RecentCallScreenState extends State<RecentCallScreen> {
  int day = 2;
  List<CallLog> callLogs = [];
  SoftPhoneService service = SoftPhoneService();

  void listCallLogs() async {
    final from = DateTime.now().endOfDay;
    final to = from.subtract(Duration(days: day)).startOfDay;
    CallLogsResponse response = await service.listCallLogs(
      from.formatDateTimeTz(),
      to.formatDateTimeTz(),
    );
    if (response.errorMessage.isEmpty) {
      setState(() {
        callLogs = response.callLogs;
      });
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    listCallLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 4.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: primaryColor,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.white),
                const SizedBox(width: 8.0),
                Text(
                  "Cuộc gọi gần đây",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.all(0.0),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: listCallLogs,
                  ),
                ),
                const SizedBox(width: 30),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton(
                      underline: const SizedBox.shrink(),
                      focusColor: Colors.transparent,
                      padding: const EdgeInsets.only(left: 10),
                      value: day,
                      items: [2, 5, 10, 15, 30].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value ngày gần đây'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          day = value!;
                        });
                        listCallLogs();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: callLogs.length,
                    itemBuilder: (context, index) {
                      CallLog model = callLogs[index];
                      ValueNotifier<bool> hover = ValueNotifier(false);
                      Duration difference = Duration.zero;
                      if (model.startDate != null && model.endDate != null) {
                        difference = model.endDate!.difference(
                          model.startDate!,
                        );
                      }
                      return ValueListenableBuilder(
                        valueListenable: hover,
                        builder: (context, value, child) {
                          return MouseRegion(
                            onEnter: (event) => hover.value = true,
                            onExit: (event) => hover.value = false,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: value
                                    ? Color.fromARGB(80, 187, 187, 187)
                                    : Color.fromARGB(192, 255, 255, 255),
                                border: const Border(
                                  bottom: BorderSide(color: Colors.grey),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  iconWidget(model.type),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          model.type.contains("IN")
                                              ? model.callingNumber
                                              : model.calledNumber,
                                          textAlign: TextAlign.left,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          model.type.contains("IN")
                                              ? model.callingName
                                              : model.calledName,
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${difference.inMinutes}:${difference.inSeconds % 60}",
                                          textAlign: TextAlign.right,
                                        ),
                                        Text(
                                          model.startDate!.formatToMinuteTime,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget iconWidget(String value) {
    switch (value) {
      case "FIN":
        return Icon(Icons.phone_callback, color: Colors.red);
      case "FOUT":
        return Icon(Icons.phone_forwarded, color: Colors.red);
      case "IN":
        return Icon(Icons.phone_callback, color: Colors.green);
      case "OUT":
        return Icon(Icons.phone_forwarded, color: Colors.green);
      default:
        return Icon(Icons.phone, color: Colors.green);
    }
  }
}

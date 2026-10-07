import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/soft_phone_model.dart';
import '../soft_phone/contact_detail.dart';
import '../soft_phone/player_screen.dart';
import '../services/soft_phone_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/global.dart';
import '../utils/string_utils.dart';
import '../widgets/progress_hud.dart';
import 'package:toastification/toastification.dart';

class CallLogDetails extends StatefulWidget {
  const CallLogDetails({super.key});

  @override
  State<CallLogDetails> createState() => _CallLogDetailsState();
}

class _CallLogDetailsState extends State<CallLogDetails> {
  AudioPlayer player = AudioPlayer();
  Dio dio = Dio();
  int indexPlaying = -1;
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 10)),
    end: DateTime.now(),
  );

  List<CallLog> callLogs = [];
  List<CallLog> filteredCallLogs = [];

  Color buttonClose = Colors.red;
  bool isApiCallProcess = false;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  SoftPhoneService service = SoftPhoneService();

  _CallLogDetailsState() {
    searchController.addListener(() {
      String value = searchController.text;
      log(value);
      setState(() {
        filteredCallLogs = callLogs
            .where(
              (element) =>
                  element.getPhoneNo().contains(value) ||
                  element.getPhoneName().searchText.contains(value.searchText),
            )
            .toList();
      });
    });
  }

  void listCallLogs() async {
    setState(() {
      isApiCallProcess = true;
    });
    CallLogsResponse result = await service.listCallLogs("", "");
    setState(() {
      isApiCallProcess = false;
    });
    if (result.errorMessage.isEmpty) {
      setState(() {
        callLogs = result.callLogs;
        callLogs.sort((a, b) => b.startDate!.compareTo(a.startDate!));
        filteredCallLogs = callLogs;
        searchController.clear();
      });
    } else {
      showToast(result.errorMessage, ToastificationType.error);
    }
  }

  Future<void> downloadFile(String url, String fileName) async {
    try {
      String pathRoot = await readData(F_ROOT_PATH) ?? Directory.current.path;
      String savePath = '$pathRoot/download/$fileName';
      await dio.download(url, savePath);
      showToast("Tải xuống hoàn tất: $savePath", ToastificationType.success);
    } catch (e) {
      showToast("Lỗi khi tải xuống: $fileName", ToastificationType.error);
    }
  }

  Future<void> _play(CallLog callHistory, CallLog? callHistoryOld) async {
    if (callHistoryOld != null) {
      await _stop(callHistory: callHistoryOld);
      log("callHistoryOld: ${callHistoryOld.indexPlay}");
    } else {
      log("callHistoryOld: null");
    }

    setState(() {
      indexPlaying = callHistory.indexPlay;
      log("_play: $indexPlaying");
    });

    String url = "$baseUrl/rest/app/getCallMp3/${callHistory.fileID}.mp3";
    await player.play(UrlSource(url));
  }

  Future<void> _stop({CallLog? callHistory}) async {
    if (indexPlaying < 0) return;
    await player.stop();
    if (callHistory != null) {
      callHistory.isPlayBack = !callHistory.isPlayBack;
    }
    setState(() {
      indexPlaying = -1;
    });
  }

  Future<void> _showDateRangePicker() async {
    DateTimeRange? result = await showDateRangePicker(
      context: context,
      initialDateRange: dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (result != null) {
      dateRange = result;

      fromDateController.text = dateRange.start.formatDate;
      toDateController.text = dateRange.end.formatDate;
    }
  }

  @override
  void initState() {
    super.initState();
    player.setReleaseMode(ReleaseMode.stop);
    fromDateController.text = dateRange.start.formatDate;
    toDateController.text = dateRange.end.formatDate;
    listCallLogs();
  }

  @override
  void dispose() {
    player.dispose();
    searchController.dispose();
    super.dispose();
  }

  //MARK: build
  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      inAsyncCall: isApiCallProcess,
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          automaticallyImplyLeading: false,
          actionsPadding: EdgeInsets.symmetric(horizontal: 10),
          title: Text('Lịch sử cuộc gọi'),
          actions: [
            SizedBox(
              height: 45,
              width: 45,
              child: IconButton(
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onHover: (value) {
                  setState(() {
                    buttonClose = value ? Colors.red.shade200 : Colors.red;
                  });
                },
                icon: Icon(Icons.close, color: buttonClose),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Tìm kiếm",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: TextFormField(
                      readOnly: true,
                      textAlignVertical: TextAlignVertical.center,
                      controller: fromDateController,
                      mouseCursor: SystemMouseCursors.click,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        labelText: "Từ ngày",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _showDateRangePicker,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: const Icon(Icons.arrow_forward_rounded),
                  ),
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: TextFormField(
                      readOnly: true,
                      textAlignVertical: TextAlignVertical.center,
                      controller: toDateController,
                      mouseCursor: SystemMouseCursors.click,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        labelText: "Đến ngày",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _showDateRangePicker,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    width: 45,
                    height: 45,
                    child: IconButton(
                      onPressed: listCallLogs,
                      icon: const Icon(Icons.search, color: Colors.black),
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    height: 45,
                    child: TextFormField(
                      textAlignVertical: TextAlignVertical.center,
                      controller: searchController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        labelText: 'Tên / Số điện thoại',
                        hintText: 'Tất cả',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              tableHeaderWidget(),
              Expanded(
                child: filteredCallLogs.isNotEmpty
                    ? ListView.builder(
                        itemCount: filteredCallLogs.length,
                        itemBuilder: (context, index) {
                          final model = filteredCallLogs[index];
                          model.indexPlay = index;

                          return callLogWidget(model, index);
                        },
                      )
                    : Center(child: Text("Không có lịch sử cuộc gọi nào")),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tableHeaderWidget() {
    return Container(
      height: 45,
      color: Colors.blue,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tableHeader('STT', 1),
            tableHeader('Trạng thái', 1),
            tableHeader('Số điện thoại', 3),
            tableHeader('Tên khách hàng', 3),
            tableHeader('Thời gian bắt đầu', 3),
            tableHeader('Thời gian kết thúc', 3),
            tableHeader('Thời lượng cuộc gọi', 3),
            tableHeader('Tác vụ', 3),
          ],
        ),
      ),
    );
  }

  Widget callLogWidget(CallLog model, int index) {
    Duration difference = Duration.zero;
    if (model.endDate != null && model.startDate != null) {
      difference = model.endDate!.difference(model.startDate!);
    }
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          model.isHover = true;
        });
      },
      onExit: (_) {
        setState(() {
          model.isHover = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: model.isHover
              ? const Color.fromARGB(80, 187, 187, 187)
              : const Color.fromARGB(192, 255, 255, 255),
          border: const Border(bottom: BorderSide(color: Colors.grey)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: Text("${index + 1}", textAlign: TextAlign.center),
              ),
              Expanded(flex: 1, child: getCallIcon(model.type)),
              Expanded(
                flex: 3,
                child: Text(model.getPhoneNo(), textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        model.getPhoneName(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: 25,
                      width: 25,
                      child: IconButton(
                        padding: const EdgeInsets.all(0.0),
                        iconSize: 22,
                        onPressed: () => actionEditCallContact(model),
                        icon: Icon(Icons.edit),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  model.startDate!.formatTimeDate,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  model.endDate!.formatTimeDate,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  "${difference.inMinutes}:${difference.inSeconds}",
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(flex: 3, child: _buildActionBar(model)),
            ],
          ),
        ),
      ),
    );
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

  Widget tableHeader(String label, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Text(
          style: TextStyle(color: Colors.white),
          label,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget playBack(CallLog callHistory) {
    return Row(
      children: [
        Tooltip(
          message: 'Play/Pause',
          child: SizedBox(
            height: 25,
            width: 25,
            child: IconButton(
              padding: const EdgeInsets.all(0.0),
              iconSize: 22,
              onPressed: () {
                callHistory.isPlayBack = !callHistory.isPlayBack;

                if (callHistory.isPlayBack) {
                  // _play(
                  // callHistory,
                  // indexPlaying < 0 ? null : widget.historyList[indexPlaying],
                  // );
                } else {
                  _stop();
                }
              },
              icon: callHistory.isPlayBack
                  ? const Icon(Icons.pause)
                  : const Icon(Icons.play_arrow),
            ),
          ),
        ),
        Expanded(
          child: PlayerScreen(
            player: player,
            onPlayDone: () => setState(() {
              _stop(callHistory: callHistory);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(CallLog callHistory) {
    if (!callHistory.type.startsWith("F") && callHistory.fileID.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [playingRecord(callHistory)],
      );
    }
    return Container();
  }

  Widget playingRecord(CallLog callHistory) {
    // log("callHistory: ${callHistory.toJson()}");
    return Expanded(
      child: callHistory.isPlayBack
          ? playBack(callHistory)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Play/Pause',
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: IconButton(
                      padding: const EdgeInsets.all(0.0),
                      iconSize: 22,
                      onPressed: () {
                        callHistory.isPlayBack = !callHistory.isPlayBack;

                        if (callHistory.isPlayBack) {
                          // _play(
                          // callHistory,
                          // indexPlaying < 0 ? null : widget.historyList[indexPlaying],
                          // );
                        } else {
                          _stop();
                        }
                      },
                      icon: callHistory.isPlayBack
                          ? const Icon(Icons.pause)
                          : const Icon(Icons.play_arrow),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Copy file',
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: IconButton(
                      padding: const EdgeInsets.all(0.0),
                      iconSize: 22,
                      onPressed: () {
                        String url =
                            "$baseUrl/rest/app/getCallMp3/${callHistory.fileID}.mp3";
                        Clipboard.setData(ClipboardData(text: url));
                      },
                      icon: Icon(Icons.share),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Download',
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: IconButton(
                      padding: const EdgeInsets.all(0.0),
                      iconSize: 22,
                      onPressed: () {
                        String url =
                            "$baseUrl/rest/app/getCallMp3/${callHistory.fileID}.mp3";
                        downloadFile(url, callHistory.fileName);
                      },
                      icon: Icon(Icons.share),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
    );
  }

  void actionEditCallContact(CallLog callHistory) async {
    CallLog? contact = await showDialog(
      context: context,
      builder: (context) {
        return ContactDetail(contact: callHistory);
      },
    );

    if (contact == null) return;

    CallContactsResponse result = await service.saveCallContact(
      contact.getPhoneNo(),
      contact.token,
      contact.getPhoneName(),
    );

    if (result.errorMessage.isEmpty) {
      // setState(() {
      //   callHistory.setPhoneName(contact.getPhoneName());
      //   callHistory.fullName = contact.fullName;
      // });
      // log("callHistory: ${callHistory.toJson()}");
      // showToast(
      //   "Cập nhật thành công",
      //   context,
      //   color: Colors.blue,
      //   local: local,
      // );
    } else {
      // showToast(result.errorMessage, context, color: Colors.blue, local: local);
    }
  }
}

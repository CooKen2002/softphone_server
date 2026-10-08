import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talkie_v2/models/limousine_model.dart';
import 'package:talkie_v2/services/limousine_service.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/string_utils.dart';
import 'package:toastification/toastification.dart';

class TripManagmentScreen extends StatefulWidget {
  const TripManagmentScreen({super.key});

  @override
  State<TripManagmentScreen> createState() => _TripManagmentScreenState();
}

class _TripManagmentScreenState extends State<TripManagmentScreen> {
  int hoverIndex = -1;
  List<TruckLine> truckLines = [];
  List<TruckLine> filteredTruckLines = [];
  LimoTrip trip = LimoTrip();
  LimousineService service = LimousineService();
  String validateMsg = "";
  final _formKey = GlobalKey<FormState>();

  //data
  TimeOfDay? firstTripHour;
  TimeOfDay? lastTripHour;
  DateTime? applyDate;
  String token = "";
  List<LimoTrip> trips = [];

  void listTruckLines() async {
    TruckLinesResponse response = await service.listTruckLines();
    if (response.errorMessage.isEmpty) {
      if (mounted) {
        setState(() {
          truckLines = response.truckLines;
          filteredTruckLines = truckLines;
        });
      }
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void filterTruckLines(String value) {
    if (value.isNotEmpty) {
      setState(() {
        filteredTruckLines = truckLines
            .where((e) => e.description.searchText.contains(value.searchText))
            .toList();
      });
    } else {
      setState(() {
        filteredTruckLines = truckLines;
      });
    }
  }

  String formatTimeOfDay(int hour, int minute) {
    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }

  void createTrips() async {
    bool isValid = _formKey.currentState!.validate();
    if (!isValid) {
      showToast(validateMsg, ToastificationType.error);
      return;
    }

    if (trip.lineID == 0) {
      showToast(
        "Vui lòng chọn tuyến xe trước khi tạo chuyến!",
        ToastificationType.error,
      );
      return;
    }

    if (trip.interval < 5) {
      showToast(
        "Tần suất chuyến phải lớn hơn 5 phút.",
        ToastificationType.error,
      );
      return;
    }

    if (trip.minTrips > trip.maxTrips) {
      showToast(
        "Số lượt tối đa phải lớn hơn số lượt tối thiểu!",
        ToastificationType.error,
      );
      return;
    }

    if (firstTripHour!.isAfter(lastTripHour!)) {
      showToast(
        "Thời gian chuyến cuối phải nhỏ hơn chuyến đầu!",
        ToastificationType.error,
      );
      return;
    }

    DateTime startDate = DateTime(
      applyDate!.year,
      applyDate!.month,
      applyDate!.day,
      firstTripHour!.hour,
      firstTripHour!.minute,
    );
    DateTime endDate = DateTime(
      applyDate!.year,
      applyDate!.month,
      applyDate!.day,
      lastTripHour!.hour,
      lastTripHour!.minute,
    );
    trip.startDate = startDate;
    trip.endDate = endDate;
    trip.count = 1;
    PrepareLimoTripsResponse response = await service.prepareLimoTrips(trip);
    if (response.errorMessage.isEmpty) {
      setState(() {
        trips = response.trips;
        token = response.token;
      });
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void generateLimoTrips() async {
    LimoTripsResponse response = await service.generateLimoTrips(trips, token);
    if (mounted) Navigator.of(context).pop();
    if (response.errorMessage.isEmpty) {
      showToast("Tạo chuyến thành công!", ToastificationType.success);
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    listTruckLines();
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallSize = MediaQuery.of(context).size.width < 1500;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Text(
                  'Lộ trình',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: InputBorder.none,
                  ),
                  onChanged: filterTruckLines,
                ),
                SizedBox(height: 10),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: filteredTruckLines.length,
                      itemBuilder: (context, index) {
                        final model = filteredTruckLines[index];
                        return MouseRegion(
                          onEnter: (event) {
                            setState(() {
                              hoverIndex = index;
                            });
                          },
                          onExit: (event) {
                            setState(() {
                              hoverIndex = -1;
                            });
                          },
                          child: Container(
                            color: hoverIndex == index
                                ? Colors.grey[350]
                                : Colors.transparent,
                            child: ListTile(
                              onTap: () {
                                setState(() {
                                  trip.lineID = model.lineID;
                                });
                              },
                              title: Text(
                                model.description,
                                style: TextStyle(
                                  color: trip.lineID == model.lineID
                                      ? Colors.blue
                                      : Colors.black,
                                ),
                              ),
                              mouseCursor: SystemMouseCursors.click,
                              hoverColor: Colors.red.shade200,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            alignment: isSmallSize
                                ? WrapAlignment.start
                                : WrapAlignment.spaceBetween,
                            runSpacing: 10,
                            spacing: 25,
                            children: [
                              cardWidget(
                                "Tần suất",
                                "${trip.interval} phút",
                                numberTextField(
                                  "Tần suất",
                                  (v) => trip.interval = v,
                                ),
                              ),
                              cardWidget(
                                "Số lượt tối thiểu",
                                "${trip.minTrips} chuyến",
                                numberTextField(
                                  "Số lượt tối thiểu",
                                  (v) => trip.minTrips = v,
                                ),
                              ),
                              cardWidget(
                                "Số lượt tối đa",
                                "${trip.maxTrips} chuyến",
                                numberTextField(
                                  "Số lượt tối đa",
                                  (v) => trip.maxTrips = v,
                                ),
                              ),
                              cardWidget(
                                "Chuyến sớm",
                                "",
                                hourTextField(
                                  "Chuyến sớm",
                                  firstTripHour,
                                  (v) => firstTripHour = v,
                                ),
                              ),
                              cardWidget(
                                "Chuyến muộn",
                                "",
                                hourTextField(
                                  "Chuyến muộn",
                                  lastTripHour,
                                  (v) => lastTripHour = v,
                                ),
                              ),
                              cardWidget(
                                "Ngày áp dụng",
                                applyDate != null ? applyDate!.formatDate : "",
                                dateTextField(
                                  "Ngày áp dụng",
                                  applyDate,
                                  (v) => applyDate = v,
                                ),
                              ),
                              cardWidget(
                                "Thời gian 1 lộ trình",
                                "${trip.roundDuration} phút",
                                numberTextField(
                                  "Thời gian 1 lộ trình",
                                  (v) => trip.roundDuration = v,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        elevation: WidgetStateProperty.all<double>(0),
                        backgroundColor: WidgetStateProperty.all<Color>(
                          primaryColor,
                        ),
                      ),
                      onPressed: createTrips,
                      child: Text(
                        'Xác nhận',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Divider(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SingleChildScrollView(child: prepareTripsWidget()),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        elevation: WidgetStateProperty.all<double>(0),
                        backgroundColor: WidgetStateProperty.all<Color>(
                          primaryColor,
                        ),
                      ),
                      onPressed: showGenerateLimoTripsDialog,
                      child: Text(
                        'Xác nhận',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget cardWidget(String label, String content, Widget textField) {
    double width = MediaQuery.of(context).size.width < 1500 ? 130 : 150;
    return Container(
      width: width,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 20),
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 20),
          SizedBox(height: 35, child: textField),
        ],
      ),
    );
  }

  Widget numberTextField(String label, Function(int) onChanged) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          String msg = "$label không được để trống!";
          validateMsg = msg;
          return msg;
        }
        return null;
      },
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(10),
        errorStyle: TextStyle(height: 0, fontSize: 0),
      ),
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
      },
      onChanged: (tmp) => setState(() {
        onChanged(tmp.isNotEmpty ? int.parse(tmp) : 0);
      }),
    );
  }

  Widget hourTextField(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onChanged,
  ) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          String msg = "$label không được để trống!";
          validateMsg = msg;
          return msg;
        }
        return null;
      },
      controller: time != null
          ? TextEditingController(text: formatTimeOfDay(time.hour, time.minute))
          : null,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'HH:mm',
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        errorStyle: TextStyle(height: 0, fontSize: 0),
      ),
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {
        final value = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (value != null) {
          setState(() {
            onChanged(value);
          });
        }
      },
    );
  }

  Widget dateTextField(
    String label,
    DateTime? date,
    Function(DateTime) onChanged,
  ) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          String msg = "$label không được để trống!";
          validateMsg = msg;
          return msg;
        }
        return null;
      },
      controller: date != null
          ? TextEditingController(text: date.formatDate)
          : null,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(0),
        border: OutlineInputBorder(),
        prefixIcon: Padding(
          padding: EdgeInsets.all(0.0),
          child: Icon(Icons.calendar_month),
        ),
        errorStyle: TextStyle(height: 0, fontSize: 0),
      ),
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {
        final firstDate = DateTime.now();
        final lastDate = firstDate.add(Duration(days: 10));
        final initialDate = date ?? firstDate;
        final value = await showDatePicker(
          context: context,
          firstDate: firstDate,
          lastDate: lastDate,
          initialDate: initialDate,
        );
        if (value != null) {
          setState(() {
            onChanged(value);
          });
        }
      },
    );
  }

  Widget prepareTripsWidget() {
    List<int> items = List.generate(
      trip.maxTrips - trip.minTrips + 1,
      (index) => trip.minTrips + index,
    );
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 23,
            runSpacing: 5.0,
            alignment: WrapAlignment.start,
            children: trips
                .map(
                  (e) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: SizedBox(
                      width: 150,
                      height: 80,
                      child: Column(
                        children: [
                          Expanded(
                            child: Text(
                              formatTimeOfDay(
                                e.departureDate!.hour,
                                e.departureDate!.minute,
                              ),
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          DropdownButton(
                            value: e.count,
                            items: items
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      "$e chuyến",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                e.count = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  void showGenerateLimoTripsDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: 100,
            height: 90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn có muốn lưu danh sách khung giờ ?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 15),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      const TextSpan(text: 'Khung giờ từ '),
                      TextSpan(
                        text: (formatTimeOfDay(
                          firstTripHour!.hour,
                          firstTripHour!.minute,
                        )),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: ' đến '),
                      TextSpan(
                        text: (formatTimeOfDay(
                          lastTripHour!.hour,
                          lastTripHour!.minute,
                        )),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: generateLimoTrips,
              child: Text('Xác nhận', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Quay lại', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

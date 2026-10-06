import 'package:flutter/material.dart';
import 'package:talkie_v2/models/limousine_model.dart';
import 'package:talkie_v2/services/limousine_service.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/string_utils.dart';
import 'package:talkie_v2/widgets/progress_hud.dart';
import 'package:toastification/toastification.dart';

class LimoTicketDashboardScreen extends StatefulWidget {
  const LimoTicketDashboardScreen({super.key});

  @override
  State<LimoTicketDashboardScreen> createState() =>
      _LimoTicketDashboardScreenState();
}

class _LimoTicketDashboardScreenState extends State<LimoTicketDashboardScreen> {
  bool isApiCallProcess = false;
  List<TruckLine> trucklines = [];
  TruckLine? selectedLine;
  DateTimeRange? dateRange;
  List<LimoTrip> trips = [];
  int totalRevenue = 0;
  int averageRevenue = 0;
  List<String> vehiclesWithMostTrips = [];
  List<String> driversWithMostTrips = [];
  int totalTicket = 0;
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  LimousineService service = LimousineService();
  String validateMsg = "";
  final _formKey = GlobalKey<FormState>();

  void listTruckLines() async {
    TruckLinesResponse response = await service.listTruckLines();
    if (response.errorMessage.isEmpty) {
      setState(() {
        trucklines = response.truckLines;
      });
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void _showDateRangePicker() async {
    DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2070),
      initialDateRange: dateRange,
    );

    if (result != null) {
      dateRange = result;
      fromDateController.text = dateRange!.start.formatDate;
      toDateController.text = dateRange!.end.formatDate;
    }
  }

  void searchTrips() async {
    bool isValid = _formKey.currentState!.validate();

    if (!isValid) {
      showToast(validateMsg, ToastificationType.error);
      return;
    }

    setState(() {
      isApiCallProcess = true;
    });

    LimoTripsResponse response = await service.searchTrips(
      selectedLine!.lineID,
      dateRange!.start,
      dateRange!.end,
    );

    setState(() {
      isApiCallProcess = false;
      totalRevenue = averageRevenue = totalTicket = 0;
      vehiclesWithMostTrips = driversWithMostTrips = [];
    });

    if (response.errorMessage.isEmpty) {
      trips = response.trips;

      Map<String, int> tripQtyMap = {};
      Map<String, int> driverMap = {};
      for (var trip in trips) {
        tripQtyMap.update(trip.plateNo, (value) => value++, ifAbsent: () => 1);
        driverMap.update(
          trip.driverName,
          (value) => value++,
          ifAbsent: () => 1,
        );
        totalTicket += trip.matrixes.length;
        for (var matrix in trip.matrixes) {
          totalRevenue += matrix.price;
        }
      }
      if (totalRevenue != 0) {
        averageRevenue = (totalRevenue / trips.length).toInt();
      }
      vehiclesWithMostTrips = tripQtyMap.keys.toList()
        ..sort((a, b) => tripQtyMap[b]!.compareTo(tripQtyMap[a]!))
        ..take(3).toList();
      driversWithMostTrips = driverMap.keys.toList()
        ..sort((a, b) => driverMap[b]!.compareTo(driverMap[a]!))
        ..take(3).toList();
      setState(() {});
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
    return ProgressHUD(
      inAsyncCall: isApiCallProcess,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      SizedBox(width: 20),
                      Text(
                        "Tuyến xe",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 250,
                        height: 50,
                        child: DropdownButtonFormField(
                          validator: (value) {
                            if (value == null) {
                              validateMsg = "Tuyến xe không được để trống";
                              return validateMsg;
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: "Tuyến xe",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(5.0),
                              ),
                            ),
                            errorStyle: TextStyle(height: 0, fontSize: 0),
                          ),
                          initialValue: selectedLine,
                          items: trucklines
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.description),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedLine = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 20),
                      Text(
                        "Ngày",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 150,
                        height: 50,
                        child: TextFormField(
                          validator: (value) {
                            if (value == null) {
                              validateMsg = "Ngày không được để trống";
                              return validateMsg;
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: fromDateController,
                          readOnly: true,
                          onTapOutside: (event) =>
                              FocusScope.of(context).unfocus(),
                          mouseCursor: SystemMouseCursors.click,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_month),
                            errorStyle: TextStyle(height: 0, fontSize: 0),
                          ),
                          onTap: _showDateRangePicker,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Icon(Icons.arrow_forward_rounded),
                      ),
                      SizedBox(
                        width: 150,
                        height: 50,
                        child: TextFormField(
                          validator: (value) {
                            if (value == null) {
                              validateMsg = "Ngày không được để trống";
                              return validateMsg;
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: toDateController,
                          readOnly: true,
                          onTapOutside: (event) =>
                              FocusScope.of(context).unfocus(),
                          mouseCursor: SystemMouseCursors.click,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_month),
                            errorStyle: TextStyle(height: 0, fontSize: 0),
                          ),
                          onTap: _showDateRangePicker,
                        ),
                      ),
                      SizedBox(width: 20),
                      InkWell(
                        onTap: searchTrips,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: 50,
                          height: 50,
                          child: Center(
                            child: Icon(Icons.search, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 1070 ? 4 : 3;
                      return GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                        children: [
                          dashboardCardWidget(
                            "Doanh thu",
                            "Tổng doanh thu",
                            totalRevenue.formatCurrency(),
                            "VNĐ",
                          ),
                          dashboardCardWidget(
                            "Doanh thu trung bình mỗi chuyến",
                            "Doanh thu trung bình mỗi chuyến xe",
                            averageRevenue.formatCurrency(),
                            "VNĐ",
                          ),
                          dashboardCardWidget(
                            "Số lượng chuyến",
                            "Tổng số lượng chuyến xe",
                            "${trips.length}",
                            "chuyến",
                          ),
                          dashboardCardWidget(
                            "Xe chạy nhiều nhất",
                            "Xe chạy nhiều chuyến nhất",
                            vehiclesWithMostTrips
                                .asMap()
                                .entries
                                .map((e) => "${e.key + 1}. ${e.value}")
                                .join("\n"),
                            "",
                          ),
                          dashboardCardWidget(
                            "Tài xế chạy nhiều nhất",
                            "Tài xế chạy nhiều chuyến nhất",
                            driversWithMostTrips
                                .asMap()
                                .entries
                                .map((e) => "${e.key + 1}. ${e.value}")
                                .join("\n"),
                            "",
                          ),
                          dashboardCardWidget(
                            "Số tuyến xe",
                            "Số tuyến xe hiện có",
                            "${trucklines.length}",
                            "tuyến",
                          ),
                          dashboardCardWidget(
                            "Số lượng vé",
                            "Số lượng vé bán ra",
                            "$totalTicket",
                            "vé",
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dashboardCardWidget(
    String title,
    String subTitle,
    String value,
    String unit,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: 25),
            isApiCallProcess
                ? Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subTitle,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

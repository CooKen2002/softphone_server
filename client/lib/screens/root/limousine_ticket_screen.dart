import 'package:flutter/material.dart';
import 'package:talkie_v2/models/limousine_model.dart';
import 'package:talkie_v2/screens/limousine_ticket/edit_trip_screen.dart';
import 'package:talkie_v2/services/limousine_service.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/widgets/calendar_ticket.dart';
import 'package:talkie_v2/widgets/tab_widget.dart';
import 'package:toastification/toastification.dart';

class LimousineTicketScreen extends TabWidget {
  const LimousineTicketScreen({super.key})
    : super(icon: Icons.confirmation_num_outlined, title: "Vé xe");

  @override
  State<LimousineTicketScreen> createState() => _LimousineTicketScreenState();
}

class _LimousineTicketScreenState extends State<LimousineTicketScreen> {
  DateTime _selectedDate = DateTime.now();

  // schedule
  TruckLine? _selectedTruckLine;
  List<TruckLine> truckLines = [];
  List<TruckLine> filteredTruckLines = [];
  LimousineService service = LimousineService();

  void listTruckLines() async {
    TruckLinesResponse response = await service.listTruckLines();
    if (response.errorMessage.isEmpty) {
      setState(() {
        truckLines = response.truckLines;
        filteredTruckLines = truckLines;
      });
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
    return Scaffold(
      body: Container(
        color: Color.fromARGB(255, 236, 236, 236),
        child: Row(
          children: [
            Expanded(flex: 1, child: leftSideWidget()),
            Expanded(flex: 4, child: rightSideWidget()),
          ],
        ),
      ),
    );
  }

  Widget leftSideWidget() {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.black26)),
      ),
      child: Column(
        children: [
          CalendarTicket(onChanged: (value) => _selectedDate = value),
          Divider(),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Lịch trình',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 16,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    onChanged: (value) {
                      setState(() {
                        filteredTruckLines = value.isEmpty
                            ? truckLines
                            : truckLines
                                  .where((e) => e.description.contains(value))
                                  .toList();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        itemCount: filteredTruckLines.length,
                        itemBuilder: (context, index) {
                          final model = filteredTruckLines[index];
                          return InkWell(
                            onTap: () => setState(() {
                              _selectedTruckLine = model;
                            }),
                            child: ListTile(
                              title: Text(
                                model.description,
                                style: TextStyle(
                                  color:
                                      _selectedTruckLine != null &&
                                          _selectedTruckLine!.lineID ==
                                              model.lineID
                                      ? Colors.blue
                                      : Colors.black,
                                ),
                              ),
                              mouseCursor: SystemMouseCursors.click,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget rightSideWidget() {
    return Column(
      children: [
        Expanded(
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 13),
                          Text(
                            "Danh sách khung giờ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: EdgeInsets.all(2),
                            child: IconButton(
                              color: primaryColor,
                              onPressed: _showCreateTripDialog,
                              icon: const Icon(Icons.add),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Hiện tại chưa có khung giờ nào",
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(),
                Expanded(child: tripDetailWidget()),
              ],
            ),
          ),
        ),
        Divider(),
        Expanded(
          flex: 2,
          child: DefaultTabController(
            length: 2,
            child: Container(
              color: Color(0xfffef7ff),
              child: Column(
                children: [
                  TabBar(
                    labelColor: primaryColor,
                    indicatorColor: primaryColor,
                    isScrollable: true,
                    tabs: const [
                      SizedBox(width: 80, child: Tab(text: 'Sơ Đồ Ghế')),
                      SizedBox(width: 80, child: Tab(text: 'Hành Khách')),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              showToast("Test toast", ToastificationType.error);
                            },
                            child: Text("12345"),
                          ),
                        ),
                        Container(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateTripDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: SizedBox(width: 800, height: 800, child: EditTripScreen()),
        );
      },
    );
  }

  Widget tripDetailWidget() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      elevation: WidgetStateProperty.all<double>(0),
                      backgroundColor: WidgetStateProperty.all<Color>(
                        secondaryColor,
                      ),
                    ),
                    onPressed: () {},
                    label: Text(
                      "In Phơi",
                      style: TextStyle(color: Colors.black),
                    ),
                    icon: Icon(Icons.print, color: Colors.black),
                  ),
                  ElevatedButton.icon(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      elevation: WidgetStateProperty.all<double>(0),
                      backgroundColor: WidgetStateProperty.all<Color>(
                        secondaryColor,
                      ),
                    ),
                    onPressed: () {},
                    label: Text(
                      "Lịch sử",
                      style: TextStyle(color: Colors.black),
                    ),
                    icon: Icon(Icons.history, color: Colors.black),
                  ),
                  ElevatedButton.icon(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      elevation: WidgetStateProperty.all<double>(0),
                      backgroundColor: WidgetStateProperty.all<Color>(
                        Colors.orange,
                      ),
                    ),
                    onPressed: () {},
                    label: Text(
                      "Hủy chuyến",
                      style: TextStyle(color: Colors.black),
                    ),
                    icon: Icon(Icons.print, color: Colors.black),
                  ),
                  ElevatedButton.icon(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      elevation: WidgetStateProperty.all<double>(0),
                      backgroundColor: WidgetStateProperty.all<Color>(
                        secondaryColor,
                      ),
                    ),
                    onPressed: () {},
                    label: Text(
                      "Lệnh vận chuyển",
                      style: TextStyle(color: Colors.black),
                    ),
                    icon: Icon(Icons.print, color: Colors.black),
                  ),
                ],
              ),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  Text(
                    DateTime.now().formatDate,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  VerticalDivider(color: Colors.black),
                  Row(
                    children: [
                      Text(
                        "Lộ trình",
                        style: TextStyle(color: secondaryColor, fontSize: 16),
                      ),
                      Icon(Icons.arrow_right_outlined, color: secondaryColor),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTapDown: (details) {
                            showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                              ),
                              items: loginResponse.seatCapacities.map((e) {
                                return PopupMenuItem(
                                  child: Text("Xe $e chỗ"),
                                  onTap: () {},
                                );
                              }).toList(),
                            );
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              children: [
                                Icon(Icons.directions_car_filled_outlined),
                                SizedBox(width: 10),
                                Text(
                                  "Chọn loại xe",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: secondaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              children: [
                                Icon(Icons.car_crash_outlined),
                                SizedBox(width: 10),
                                Text(
                                  "Chọn biển số xe",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: secondaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              children: [
                                Icon(Icons.person_2_outlined),
                                SizedBox(width: 10),
                                Text(
                                  "Chọn tài xế",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: secondaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: "10",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(text: " vé đã bán"),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: "Tiền mặt: "),
                              TextSpan(
                                text: "10.000đ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: "Số khách trên xe: "),
                              TextSpan(
                                text: "10",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: "Chuyển khoản: "),
                              TextSpan(
                                text: "10.000đ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: "Số khách chưa đón: "),
                              TextSpan(
                                text: "2",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: "Tổng tiền: "),
                              TextSpan(
                                text: "20.000đ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

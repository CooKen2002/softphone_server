import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talkie_v2/models/limousine_model.dart';
import 'package:talkie_v2/services/limousine_service.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:toastification/toastification.dart';

class TicketManagmentScreen extends StatefulWidget {
  const TicketManagmentScreen({super.key});

  @override
  State<TicketManagmentScreen> createState() => _TicketManagmentScreenState();
}

class _TicketManagmentScreenState extends State<TicketManagmentScreen> {
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();

  List<Map<String, dynamic>> dataTable = [];
  List<TruckLine> truckLines = [];
  TruckLine? selectedTruckLine;
  LimousineService service = LimousineService();
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  void listTruckLines() async {
    TruckLinesResponse response = await service.listTruckLines();
    if (response.errorMessage.isEmpty) {
      setState(() {
        truckLines = response.truckLines;
      });
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  Future<void> _selectDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2070),
      initialDateRange: dateRange,
    );
    if (result != null) {
      setState(() {
        dateRange = result;
        fromDateController.text = result.start.formatDate;
        toDateController.text = result.end.formatDate;
      });
    }
  }

  void exportToExcel() async {
    if (dataTable.isEmpty) {
      showToast('Không có dữ liệu để xuất.', ToastificationType.warning);
      return;
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
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text("Tuyến xe", style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(width: 10),
                SizedBox(
                  width: 240,
                  height: 50,
                  child: DropdownButtonFormField(
                    initialValue: selectedTruckLine,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: "Chọn tuyến xe",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 0.5),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    items: truckLines.map((value) {
                      return DropdownMenuItem<TruckLine>(
                        value: value,
                        child: Text(value.description),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTruckLine = value!;
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "Thời gian",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 350, child: _buildDatePickers()),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(width: 0.5),
                    borderRadius: BorderRadius.circular(5.0),
                    color: primaryColor,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.search, color: Colors.white),
                  ),
                ),
                SizedBox(width: 20),
                Container(
                  width: 140,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(width: 0.5),
                    borderRadius: BorderRadius.circular(5.0),
                    color: primaryColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: GestureDetector(
                      onTap: exportToExcel,
                      child: Row(
                        children: [
                          Icon(Icons.file_download, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Xuất excel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              color: primaryColor,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildHeaderTable('STT', 1, Colors.white),
                        buildHeaderTable('Ngày', 3, Colors.white),
                        buildHeaderTable('Giờ xuất bến', 3, Colors.white),
                        buildHeaderTable('Lộ trình', 5, Colors.white),
                        buildHeaderTable('Tài xế', 4, Colors.white),
                        buildHeaderTable('Biển số xe', 4, Colors.white),
                        buildHeaderTable('Tổng số ghế', 3, Colors.white),
                        buildHeaderTable('Bán ra', 3, Colors.white),
                        buildHeaderTable('Người tạo', 3, Colors.white),
                        buildHeaderTable('Ghi chú', 5, Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: index != 19
                          ? Border(bottom: BorderSide(color: Colors.grey))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildHeaderTable('${index + 1}', 1, Colors.black),
                        buildHeaderTable(
                          DateTime.now().formatDate,
                          3,
                          Colors.black,
                        ),
                        buildHeaderTable(
                          DateFormat('HH:mm').format(DateTime.now()),
                          3,
                          Colors.black,
                        ),
                        buildHeaderTable("Tuyến ${index + 1}", 5, Colors.black),
                        buildHeaderTable(
                          'Tài xế ${index + 1}',
                          4,
                          Colors.black,
                        ),
                        buildHeaderTable(
                          'Biển số ${index + 1}',
                          4,
                          Colors.black,
                        ),
                        buildHeaderTable('${index + 10}', 3, Colors.black),
                        buildHeaderTable('${index + 10}', 3, Colors.black),
                        buildHeaderTable(
                          "Người tạo ${index + 1}",
                          3,
                          Colors.black,
                        ),
                        buildHeaderTable("Ghi chú", 5, Colors.black),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickers() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Flexible(
            child: SizedBox(
              height: 50,
              child: TextFormField(
                controller: fromDateController,
                mouseCursor: SystemMouseCursors.click,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: "Từ ngày",
                  prefixIcon: Icon(Icons.calendar_month),
                  contentPadding: EdgeInsets.all(8),
                ),
                readOnly: true,
                onTap: _selectDateRange,
              ),
            ),
          ),
          Text("   -   "),
          Flexible(
            child: SizedBox(
              height: 50,
              child: TextFormField(
                controller: toDateController,
                mouseCursor: SystemMouseCursors.click,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: "Đến ngày",
                  prefixIcon: Icon(Icons.calendar_month),
                  contentPadding: EdgeInsets.all(8),
                ),
                readOnly: true,
                onTap: _selectDateRange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeaderTable(String label, int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w400),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

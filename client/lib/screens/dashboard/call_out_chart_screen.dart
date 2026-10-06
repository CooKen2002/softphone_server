import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:talkie_v2/models/soft_phone_model.dart';
import 'package:talkie_v2/services/soft_phone_service.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:toastification/toastification.dart';

class CallOutChartScreen extends StatefulWidget {
  const CallOutChartScreen({super.key});

  @override
  State<CallOutChartScreen> createState() => _CallOutChartScreenState();
}

class _CallOutChartScreenState extends State<CallOutChartScreen> {
  int day = 1;
  int outSuccessCalls = 0, outFailureCall = 0, totalInCalls = 0;
  double inSuccessPercentage = 0, inFailurePercentage = 0;
  List<CallLog> callLogs = [];
  ScreenshotController screenshotController = ScreenshotController();
  SoftPhoneService service = SoftPhoneService();

  void _loadData() async {
    final from = DateTime.now().startOfDay;
    final to = from.subtract(Duration(days: day)).endOfDay;
    CallLogsResponse response = await service.listCallLogs(
      from.formatDateTimeTz(),
      to.formatDateTimeTz(),
    );
    if (response.errorMessage.isEmpty) {
      setState(() {
        callLogs = response.callLogs;
        outSuccessCalls = callLogs.where((log) => log.type == "OUT").length;
        outFailureCall = callLogs.where((log) => log.type == "FOUT").length;
        totalInCalls = outSuccessCalls + outFailureCall;

        inSuccessPercentage = totalInCalls > 0
            ? (outSuccessCalls / totalInCalls) * 100
            : 0;
        inFailurePercentage = totalInCalls > 0
            ? (outFailureCall / totalInCalls) * 100
            : 0;
      });
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void _downloadChartPNG() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(pw.MemoryImage(image)));
          },
        ),
      );

      String pathRoot = Directory.current.path;

      final dateFormat = DateFormat('dd-MM-yyyy_HH-mm');
      final dateTime = dateFormat.format(DateTime.now());
      final fileName = 'call_out_chart_$dateTime.png';

      final savePath = '$pathRoot/downloadChartFolder/$fileName';

      final file = File(savePath);
      await file.writeAsBytes(image);

      showToast('PNG saved at: $savePath', ToastificationType.success);
    } catch (e) {
      showToast('Error saving PNG', ToastificationType.error);
    }
  }

  Future<void> _downloadChartPDF() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(pw.MemoryImage(image)));
          },
        ),
      );

      String pathRoot = Directory.current.path;

      final dateFormat = DateFormat('dd-MM-yyyy_HH-mm');
      final dateTime = dateFormat.format(DateTime.now());
      final fileName = 'call_out_chart_$dateTime.pdf';

      final savePath = '$pathRoot/downloadChartFolder/$fileName';

      final file = File(savePath);
      await file.writeAsBytes(await pdf.save());

      showToast('PDF saved at: $savePath', ToastificationType.success);
    } catch (e) {
      showToast('Error saving PDF', ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    callLogs.where((log) => log.type == "OUT").length;

    return Screenshot(
      controller: screenshotController,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 4.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: primaryColor,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.call_made, color: Colors.white),
                  const SizedBox(width: 8.0),
                  Text(
                    "Cuộc gọi đi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.all(0.0),
                    child: IconButton(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(0.0),
                    child: PopupMenuButton(
                      icon: const Icon(Icons.list, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'download_image') {
                          _downloadChartPNG();
                        } else if (value == 'download_pdf') {
                          _downloadChartPDF();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'download_image',
                          child: Text('Tải xuống biểu đồ PNG'),
                        ),
                        const PopupMenuItem(
                          value: 'download_pdf',
                          child: Text('Tải xuống biểu đồ PDF'),
                        ),
                      ],
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
                    padding: EdgeInsetsGeometry.symmetric(vertical: 4),
                    child: Container(
                      height: 30,
                      padding: EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton(
                        underline: const SizedBox.shrink(),
                        focusColor: Colors.transparent,
                        padding: const EdgeInsets.only(left: 10),
                        value: day,
                        items: [1, 5, 10].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text("$value ngày"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            day = value!;
                          });
                          _loadData();
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: callLogs.isEmpty
                        ? const Center(child: Text('Không có dữ liệu'))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final chartRadius = constraints.maxWidth / 4;

                              return PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: outSuccessCalls.toDouble(),
                                      color: secondaryColor,
                                      title:
                                          '${inSuccessPercentage.toStringAsFixed(1)}%',
                                      radius: chartRadius,
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                      ),
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: outFailureCall.toDouble(),
                                      color: primaryColor,
                                      title:
                                          '${inFailurePercentage.toStringAsFixed(1)}%',
                                      radius: chartRadius,
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                      ),
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 0,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: secondaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Text('Thành công'),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Text('Thất bại'),
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

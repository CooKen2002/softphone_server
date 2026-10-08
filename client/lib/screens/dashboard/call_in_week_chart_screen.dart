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

class CallInWeekChartScreen extends StatefulWidget {
  const CallInWeekChartScreen({super.key});

  @override
  State<CallInWeekChartScreen> createState() => _CallInWeekChartScreenState();
}

class _CallInWeekChartScreenState extends State<CallInWeekChartScreen> {
  ScreenshotController screenshotController = ScreenshotController();
  List<String> days = [];
  List<double> totalCalls = List.filled(7, 0);
  List<double> answeredCalls = List.filled(7, 0);
  List<double> unansweredCalls = List.filled(7, 0);
  List<CallLog> callLogs = [];
  SoftPhoneService service = SoftPhoneService();

  void _loadData() async {
    final from = DateTime.now().startOfDay;
    final to = from.subtract(Duration(days: 7)).endOfDay;
    CallLogsResponse response = await service.listCallLogs(
      from.formatDateTimeTz(),
      to.formatDateTimeTz(),
    );
    if (response.errorMessage.isEmpty) {
      setState(() {
        callLogs = response.callLogs;
      });
      _computeWeeklyStatistics();
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

  void _generateDaysList() {
    days.clear();

    for (int i = 0; i < 7; i++) {
      DateTime day = DateTime.now().subtract(Duration(days: i));
      switch (day.weekday) {
        case DateTime.monday:
          days.add('Thứ hai');
          break;
        case DateTime.tuesday:
          days.add('Thứ ba');
          break;
        case DateTime.wednesday:
          days.add('Thứ tư');
          break;
        case DateTime.thursday:
          days.add('Thứ năm');
          break;
        case DateTime.friday:
          days.add('Thứ sáu');
          break;
        case DateTime.saturday:
          days.add('Thứ bảy');
          break;
        case DateTime.sunday:
          days.add('Chủ nhật');
          break;
      }
    }

    days = days.reversed.toList();
  }

  void _computeWeeklyStatistics() {
    for (var call in callLogs) {
      if (call.startDate != null) {
        int daysDifference = DateTime.now().difference(call.startDate!).inDays;

        if (daysDifference < 7) {
          int index = 6 - daysDifference;

          totalCalls[index]++;
          if (call.type == "IN" || call.type == "OUT") {
            answeredCalls[index]++;
          } else {
            unansweredCalls[index]++;
          }
        }
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _generateDaysList();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
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
                    "Cuộc trong vòng 7 ngày",
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
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double fontSize = constraints.maxWidth <= 400 ? 8 : 12;

                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 1000,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Transform.rotate(
                                    angle: -6,
                                    child: Text(
                                      days[value.toInt()],
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: fontSize,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value == 0 ||
                                    value == 500 ||
                                    value == 1000) {
                                  return Text(
                                    '${value.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                } else {
                                  return Container();
                                }
                              },
                              reservedSize: 30,
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          horizontalInterval: 500,
                          getDrawingHorizontalLine: (value) {
                            if (value == 0 || value == 500 || value == 1000) {
                              return FlLine(
                                // ignore: deprecated_member_use
                                color: Colors.grey.withOpacity(0.5),
                                strokeWidth: 1,
                              );
                            } else {
                              return const FlLine(color: Colors.transparent);
                            }
                          },
                          getDrawingVerticalLine: (value) {
                            return const FlLine(color: Colors.transparent);
                          },
                        ),
                        barGroups: List.generate(days.length, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: totalCalls[index],
                                color: const Color.fromARGB(255, 1, 154, 165),
                                width: constraints.maxWidth / 30,
                                borderRadius: BorderRadius.zero,
                              ),
                              BarChartRodData(
                                toY: answeredCalls[index],
                                color: secondaryColor,
                                width: constraints.maxWidth / 30,
                                borderRadius: BorderRadius.zero,
                              ),
                              BarChartRodData(
                                toY: unansweredCalls[index],
                                color: primaryColor,
                                width: constraints.maxWidth / 30,
                                borderRadius: BorderRadius.zero,
                              ),
                            ],
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.circle,
                  color: Color.fromARGB(255, 1, 154, 165),
                  size: 16,
                ),
                const Text(
                  'Tổng cuộc gọi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 15),
                Icon(Icons.circle, color: secondaryColor, size: 16),
                const Text(
                  'Thành công',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 15),
                Icon(Icons.circle, color: primaryColor, size: 16),
                const Text(
                  'Thất bại',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

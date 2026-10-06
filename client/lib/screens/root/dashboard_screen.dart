import 'package:flutter/material.dart';
import 'package:talkie_v2/screens/dashboard/call_in_chart_screen.dart';
import 'package:talkie_v2/screens/dashboard/call_in_week_chart_screen.dart';
import 'package:talkie_v2/screens/dashboard/call_out_chart_screen.dart';
import 'package:talkie_v2/screens/dashboard/recent_call_screen.dart';
import 'package:talkie_v2/screens/dashboard/todo_list_screen.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/string_utils.dart';
import 'package:talkie_v2/widgets/tab_widget.dart';

class DashboardScreen extends TabWidget {
  const DashboardScreen({super.key})
    : super(icon: Icons.dataset_sharp, title: "Thống kê");

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, Widget> allCardsMap = {};
  Map<String, Widget> cardsMap = {};
  bool showAddCardList = false;

  void saveCards() async {
    String value = cardsMap.keys.join(",");
    await saveData(F_DASHBOARD_CARD, value);
  }

  void loadCards() async {
    cardsMap.clear();
    String value = nvl(await readData(F_DASHBOARD_CARD));
    if (value.isNotEmpty) {
      List<String> split = value.split(",");
      setState(() {
        for (var key in allCardsMap.keys) {
          if (split.contains(key)) {
            cardsMap[key] = allCardsMap[key]!;
          }
        }
      });
    }
  }

  void addCard(String value) {
    setState(() {
      cardsMap[value] = allCardsMap[value]!;
      showAddCardList = false;
    });
    saveCards();
  }

  @override
  void initState() {
    super.initState();
    allCardsMap = {
      F_TODO_LIST: TodoListScreen(),
      F_RECENT_CALL: RecentCallScreen(),
      F_CALL_IN_CHART: CallInChartScreen(),
      F_CALL_OUT_CHART: CallOutChartScreen(),
      F_CALL_IN_WEEK_CHART: CallInWeekChartScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(6.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1000 ? 3 : 2;
            return GridView.count(
              padding: const EdgeInsets.only(right: 10),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 6.0,
              mainAxisSpacing: 6.0,
              children: [
                ...cardsMap.keys.map((key) {
                  return Stack(
                    children: [
                      cardsMap[key]!,
                      Positioned(
                        top: 12,
                        right: 6,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              cardsMap.remove(key);
                            });
                            saveCards();
                          },
                        ),
                      ),
                    ],
                  );
                }),
                showAddCardList
                    ? Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 4.0,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: allCardsMap.keys
                                      .where(
                                        (key) => !cardsMap.containsKey(key),
                                      )
                                      .toList()
                                      .map((e) {
                                        return ListTile(
                                          leading: iconWidget(e),
                                          title: Text(title(e)),
                                          onTap: () => addCard(e),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() {
                            showAddCardList = true;
                          });
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 4.0,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 80.0,
                                  color: primaryColor,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Hiển thị thêm Module',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget iconWidget(String key) {
    switch (key) {
      case F_TODO_LIST:
        return Icon(Icons.list_alt_outlined);
      case F_RECENT_CALL:
        return Icon(Icons.history);
      default:
        return Icon(Icons.help);
    }
  }

  String title(String key) {
    switch (key) {
      case F_TODO_LIST:
        return "Todo List";
      case F_RECENT_CALL:
        return "Cuộc gọi gần nhất";
      case F_CALL_OUT_CHART:
        return "Thống kê cuộc gọi đi";
      case F_CALL_IN_CHART:
        return "Thống kê cuộc gọi đến";
      case F_CALL_IN_WEEK_CHART:
        return "Cuộc gọi trong 7 ngày";
      default:
        return "";
    }
  }
}

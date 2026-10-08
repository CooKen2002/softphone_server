import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:page_transition/page_transition.dart';
import 'package:talkie_v2/screens/root/dashboard_screen.dart';
import 'package:talkie_v2/screens/root/delivery_screen.dart';
import 'package:talkie_v2/screens/root/excavator_screen.dart';
import 'package:talkie_v2/screens/root/limousine_ticket_screen.dart';
import 'package:talkie_v2/screens/root/login_screen.dart';
import 'package:talkie_v2/screens/root/map_screen.dart';
import 'package:talkie_v2/screens/root/operation_screen.dart';
import 'package:talkie_v2/screens/root/soft_phone_screen.dart';
import 'package:talkie_v2/screens/root/talkie_screen.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/widgets/tab_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  bool isDarkMode = false;
  bool isLogOutHover = false;
  List<Widget> tabs = [
    MapScreen(),
    DashboardScreen(),
    DeliveryScreen(),
    LimousineTicketScreen(),
    OperationScreen(),
    ExcavatorScreen(),
  ];

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void logout() async {
    Navigator.of(context).pushReplacement(
      PageTransition(child: LoginScreen(), type: PageTransitionType.fade),
    );
    await saveData(F_PASSWORD, "");
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this);
    showWindowCloseDialog();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(width: 0.2)),
                          color: Colors.white12,
                        ),
                        height: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ...tabs.asMap().entries.map(
                              (e) => _buildTabItem(e.value as TabWidget, e.key),
                            ),
                            // _buildTabItem(Icons.dataset_sharp, "Tổng quan", 1),
                            // _buildTabItem(Icons.warehouse, "Chuyển phát", 2),
                            // _buildTabItem(
                            //   Icons.person_pin_sharp,
                            //   "Quản lý hàng",
                            //   3,
                            // ),
                            // _buildTabItem(
                            //   Icons.confirmation_num_outlined,
                            //   "Vé xe",
                            //   4,
                            // ),
                            // _buildTabItem(
                            //   Icons.airport_shuttle,
                            //   "Quản lý vận hành",
                            //   5,
                            // ),
                            // _buildTabItem(
                            //   Icons.construction,
                            //   "Quản lý máy xúc",
                            //   6,
                            // ),
                            Spacer(),
                            IconButton(
                              onPressed: toggleTheme,
                              icon: const Icon(Icons.brightness_6),
                            ),
                            SizedBox(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onHover: (value) {
                                  setState(() {
                                    isLogOutHover = value;
                                  });
                                },
                                onTap: logout,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: isLogOutHover
                                        ? Colors.red
                                        : Colors.transparent,
                                  ),
                                  child: Icon(
                                    Icons.power_settings_new_outlined,
                                    color: isLogOutHover
                                        ? Colors.white
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: tabs,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      Expanded(child: SoftPhoneScreen()),
                      // Expanded(child: TalkieScreen()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabItem(TabWidget tab, int index) {
    Color backgroundColor = (tabController.index == index)
        ? primaryColor
        : Colors.transparent;
    Color textColor = (tabController.index == index)
        ? Colors.white
        : Colors.black;
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth < 1500 ? 10 : 15;
    double tabWidth = screenWidth < 1500 ? 100 : 140;
    double iconSize = screenWidth < 1500 ? 25 : 30;

    return InkWell(
      onTap: () {
        setState(() {
          tabController.index = index;
        });
      },
      child: Container(
        width: tabWidth,
        decoration: BoxDecoration(color: backgroundColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, size: iconSize, color: textColor),
            const SizedBox(height: 5),
            Text(
              tab.title,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showWindowCloseDialog() {
    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Bạn có chắc chắn thoát không?'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // stopBare();
                  bareSip.stop();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Có'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Không'),
              ),
            ],
          );
        },
      );
    });
  }
}

// import 'package:flutter/material.dart';
// import 'package:talkie_v2/screens/root/soft_phone_screen.dart';

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: SizedBox(
//           width: 300,
//           child: Column(
//             children: [
//               Expanded(child: SoftPhoneScreen()),
//               // Expanded(child: TalkieScreen()),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

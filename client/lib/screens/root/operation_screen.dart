import 'package:flutter/material.dart';
import 'package:talkie_v2/screens/operation/driver_list_screen.dart';
import 'package:talkie_v2/screens/operation/limo_ticket_dashboard_screen.dart';
import 'package:talkie_v2/screens/operation/ticket_managment_screen.dart';
import 'package:talkie_v2/screens/operation/trip_managment_screen.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/widgets/tab_widget.dart';

class OperationScreen extends TabWidget {
  const OperationScreen({super.key})
    : super(icon: Icons.airport_shuttle, title: "Quản lý vận hành");

  @override
  State<OperationScreen> createState() => _OperationScreenState();
}

class _OperationScreenState extends State<OperationScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade100,
          elevation: 4.0,
          toolbarHeight: 50,
          automaticallyImplyLeading: false,
          flexibleSpace: TabBar(
            labelColor: primaryColor,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            indicatorColor: primaryColor,
            tabs: [
              Tab(child: Text("Thiết Lập Tuyến")),
              Tab(child: Text("Quản lý vé xe")),
              Tab(child: Text("Danh sách lái xe")),
              Tab(child: Text("Thống kê vé xe")),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TripManagmentScreen(),
            TicketManagmentScreen(),
            DriverListScreen(),
            LimoTicketDashboardScreen(),
          ],
        ),
      ),
    );
  }
}

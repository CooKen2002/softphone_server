import 'package:flutter/material.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/widgets/tab_widget.dart';

class DeliveryScreen extends TabWidget {
  const DeliveryScreen({super.key})
    : super(icon: Icons.warehouse, title: "Chuyển phát");

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade100,
          elevation: 4.0,
          toolbarHeight: 50,
          automaticallyImplyLeading: false,
          flexibleSpace: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TabBar(
                    labelColor: primaryColor,
                    padding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    indicatorColor: primaryColor,
                    tabs: [
                      tabWidget("Kho gửi"),
                      tabWidget("Trên xe"),
                      tabWidget("Kho nhận"),
                      tabWidget("Kho thanh lý"),
                      tabWidget("Hàng đã giao"),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm tên, số ĐT hoặc mã đơn',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: "Thêm mới đơn hàng",
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // showCreateOrder();
                    },
                  ),
                ),
                Tooltip(
                  message: "Show pdf",
                  child: IconButton(
                    icon: const Icon(Icons.insert_drive_file_sharp),
                    onPressed: () {
                      // showPrint();
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

  Widget tabWidget(String label) {
    return Tab(
      child: Center(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

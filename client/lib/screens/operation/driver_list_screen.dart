import 'package:flutter/material.dart';
import 'package:talkie_v2/models/admin_model.dart';
import 'package:talkie_v2/services/limousine_service.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:toastification/toastification.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  List<User> drivers = [];
  TextEditingController dateController = TextEditingController();
  LimousineService service = LimousineService();

  void listLimoUsers() async {
    UsersResponse response = await service.listLimoUsers();
    if (response.errorMessage.isEmpty) {
      setState(() {
        drivers = response.users;
      });
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    listLimoUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Danh sách lái xe trống",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 40,
                  child: TextFormField(
                    readOnly: true,
                    textAlign: TextAlign.center,
                    controller: dateController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(driver.fullName),
                  subtitle: Text(
                    "Thông tin chi tiết : Tài khoản : ${driver.userName} -  ${driver.mobileNo.isNotEmpty ? driver.mobileNo : "Chưa có sđt"}",
                  ),
                  onTap: () {
                    showDriverDetailDialog(driver);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void showDriverDetailDialog(User driver) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            height: 400,
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    "Thông tin lái xe: ${driver.fullName}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Tài khoản:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            Text(driver.userName),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Họ và tên:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Text(driver.fullName),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Số điện thoại:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              driver.mobileNo.isNotEmpty
                                  ? driver.mobileNo
                                  : "Chưa có số điện thoại",
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Địa chỉ:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            Text("Hà Nội (sample)"),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Ngày sinh:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            Text("01/01/1990 (sample)"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(primaryColor),
                    ),
                    child: const Text(
                      "Đóng",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:talkie_v2/models/admin_model.dart';
import 'package:talkie_v2/models/limousine_model.dart';
import 'package:talkie_v2/models/vehicle_model.dart';
import 'package:talkie_v2/services/limousine_service.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:toastification/toastification.dart';

class EditTripScreen extends StatefulWidget {
  const EditTripScreen({super.key});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  List<TruckLine> truckLines = [];
  List<Vehicle> vehicles = [];
  List<User> users = [];
  int? seatCapacity;
  LimousineService service = LimousineService();

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

  void listVehicles() async {
    VehiclesResponse response = await service.listVehicles();
    if (response.errorMessage.isEmpty) {
      setState(() {
        vehicles = response.vehicles;
      });
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void listLimoUsers() async {
    UsersResponse response = await service.listLimoUsers();
    if (response.errorMessage.isEmpty) {
      setState(() {
        users = response.users;
      });
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void _showDatePicker() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2060),
    );
    if (date != null) {}
  }

  void _showTimePicker() async {
    TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (result != null) {}
  }

  @override
  void initState() {
    super.initState();
    listTruckLines();
    listVehicles();
    listLimoUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        title: Text(
          'Tăng cường chuyến',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Divider(thickness: 0.2, indent: 0, endIndent: 0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      labelWidget("Tuyến xe"),
                      SizedBox(height: 8),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          hintText: "Chọn tuyến xe",
                          // contentPadding: const EdgeInsets.symmetric(
                          //   horizontal: 10,
                          // ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                        ),
                        items: truckLines
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.description,
                                child: Text(e.description),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelWidget("Ngày"),
                            SizedBox(height: 8),
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: "Ngày",
                                // contentPadding: const EdgeInsets.symmetric(
                                //   horizontal: 10,
                                // ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5.0),
                                  ),
                                ),
                              ),
                              readOnly: true,
                              mouseCursor: SystemMouseCursors.click,
                              onTap: _showDatePicker,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelWidget("Giờ xuất bến"),
                            SizedBox(height: 8),
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: "Giờ",
                                // contentPadding: const EdgeInsets.symmetric(
                                //   horizontal: 10,
                                // ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5.0),
                                  ),
                                ),
                              ),
                              readOnly: true,
                              mouseCursor: SystemMouseCursors.click,
                              onTap: _showTimePicker,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chọn loại xe",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          hintText: "Chọn loại xe",
                          // contentPadding: const EdgeInsets.symmetric(
                          //   horizontal: 10,
                          // ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                        ),
                        initialValue: seatCapacity,
                        items: loginResponse.seatCapacities
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text("Xe $e chỗ"),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            seatCapacity = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chọn biển số xe",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          hintText: "Chọn biển số xe",
                          // contentPadding: const EdgeInsets.symmetric(
                          //   horizontal: 10,
                          // ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                        ),
                        items: vehicles
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.plateNo),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tài xế",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          hintText: "Chọn tài xế",
                          // contentPadding: const EdgeInsets.symmetric(
                          //   horizontal: 10,
                          // ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                        ),
                        items: users
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.fullName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Phụ xe",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          hintText: "Chọn phụ xe",
                          // contentPadding: const EdgeInsets.symmetric(
                          //   horizontal: 10,
                          // ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                        ),
                        items: users
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.fullName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: primaryColor,
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(double.infinity, double.infinity),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cập nhật',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 25),
            Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.shade300,
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Đóng',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget labelWidget(String label) {
    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: "$label ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          TextSpan(
            text: "*",
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

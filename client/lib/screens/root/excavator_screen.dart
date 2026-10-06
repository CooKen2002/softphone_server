import 'package:flutter/material.dart';
import 'package:talkie_v2/models/vehicle_model.dart';
import 'package:talkie_v2/services/limousine_service.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/widgets/tab_widget.dart';
import 'package:toastification/toastification.dart';

class ExcavatorScreen extends TabWidget {
  const ExcavatorScreen({super.key})
    : super(icon: Icons.construction, title: "Quản lý máy xúc");

  @override
  State<ExcavatorScreen> createState() => _ExcavatorScreenState();
}

class _ExcavatorScreenState extends State<ExcavatorScreen> {
  List<Vehicle> vehicles = [];

  void listVehicles() async {
    LimousineService service = LimousineService();
    VehiclesResponse response = await service.listVehicles();
    if (response.errorMessage.isEmpty) {
      setState(() {
        vehicles = response.vehicles;
      });
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    listVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 4 / 3,
                mainAxisExtent: 250,
              ),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return DragTarget(
                  builder: (context, candidateData, rejectedData) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: candidateData.isNotEmpty ? 8.0 : 3.0,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: vehicles.isEmpty
                                    ? Colors.red.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Máy xúc: ${vehicle.plateNo}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Số xe tải: ${vehicles.length}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(width: 280),
        ],
      ),
    );
  }
}

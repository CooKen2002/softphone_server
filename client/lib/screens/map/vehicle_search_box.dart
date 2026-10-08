import 'package:flutter/material.dart';
import 'package:talkie_v2/models/vehicle_model.dart';
import 'package:talkie_v2/utils/global.dart';

class VehicleSearchBox extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Function(Vehicle value) onTap;
  const VehicleSearchBox({
    super.key,
    required this.vehicles,
    required this.onTap,
  });

  @override
  State<VehicleSearchBox> createState() => _VehicleSearchBoxState();
}

class _VehicleSearchBoxState extends State<VehicleSearchBox> {
  int _selectedIndex = -1;
  int group = 0;
  TextEditingController searchController = TextEditingController();
  String currentColor = "";
  List<Vehicle> filteredVehicles = [];

  void filterVehicle(String query) {
    setState(() {
      filteredVehicles = widget.vehicles
          .where((e) => e.plateNo.contains(query))
          .toList();
    });
  }

  void filterVehicleByColorState(String color) {
    setState(() {
      currentColor = color;
      filteredVehicles = widget.vehicles
          .where((element) => element.colorState.contains(color))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    filteredVehicles = widget.vehicles;
  }

  @override
  Widget build(BuildContext context) {
    filteredVehicles = widget.vehicles;
    filterVehicle(searchController.text);
    filterVehicleByColorState(currentColor);
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 1, child: Text("Nhóm")),
              Expanded(
                flex: 3,
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      elevation: 0,
                      focusColor: Colors.transparent,
                      value: group,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          group = value;
                        });
                      },
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text("Tất cả nhóm 1"),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text("Tất cả nhóm 2"),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text("Tất cả nhóm 3"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Expanded(flex: 1, child: Text("Tìm kiếm")),
              Expanded(
                flex: 3,
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextFormField(
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                    ),
                    controller: searchController,
                    mouseCursor: SystemMouseCursors.click,
                    onChanged: filterVehicle,
                    onEditingComplete: () =>
                        filterVehicle(searchController.text),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Table(
            border: TableBorder.all(
              color: Colors.blue.shade100,
              style: BorderStyle.solid,
              width: 1,
            ),
            columnWidths: {
              0: const FlexColumnWidth(1),
              1: const FlexColumnWidth(2),
              2: const FlexColumnWidth(1),
              3: const FlexColumnWidth(1),
              4: const FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  tableHeaderWidget("TT"),
                  tableHeaderWidget("Biển số"),
                  tableHeaderWidget("Máy"),
                  tableHeaderWidget("VT"),
                  tableHeaderWidget("Số hiệu"),
                ],
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = filteredVehicles[index];
                return SizedBox(
                  height: 40,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => widget.onTap(vehicle),
                    child: MouseRegion(
                      onEnter: (PointerEvent details) =>
                          setState(() => _selectedIndex = index),
                      onExit: (PointerEvent details) =>
                          setState(() => _selectedIndex = -1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedIndex == index ? Colors.grey : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.blue.shade100,
                              width: 1.0,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Image.asset(
                                'assets/images/vehicles/${vehicle.iconID}.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                vehicle.plateNo,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                vehicle.engineState,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "${vehicle.currentSpeed.toInt()}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                vehicle.vehicleNo,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 25,
                height: 25,
                child: InkWell(
                  child: Text(
                    "All",
                    style: TextStyle(
                      fontWeight: currentColor.isEmpty
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () => filterVehicleByColorState(""),
                ),
              ),
              filterColorWidget(Colors.green, "green"),
              filterColorWidget(Colors.red, "red"),
              filterColorWidget(Colors.yellow, "yellow"),
              filterColorWidget(Colors.purple, "purple"),
              filterColorWidget(Colors.pinkAccent, "lightpink"),
              filterColorWidget(Colors.lightBlue, "lightblue"),
              filterColorWidget(Colors.pink.shade500, "heavypink"),
              filterColorWidget(Colors.cyanAccent, "cyan"),
              filterColorWidget(Colors.blue.shade600, "heavyblue"),
              filterColorWidget(Colors.blueGrey, "gray"),
              filterColorWidget(Colors.brown, "brown"),
              filterColorWidget(Colors.grey, "lightgray"),
            ],
          ),
        ],
      ),
    );
  }

  Widget tableHeaderWidget(String label) {
    return Container(
      color: secondaryColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Container filterColorWidget(Color color, String colorName) {
    bool showBorder = currentColor == colorName ? true : false;
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: showBorder ? Border.all() : null,
      ),
      width: 25,
      height: 25,
      child: InkWell(onTap: () => filterVehicleByColorState(colorName)),
    );
  }
}

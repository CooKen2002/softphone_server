import 'package:flutter/material.dart';
import 'package:talkie_v2/models/map_model.dart';
import 'package:talkie_v2/models/vehicle_model.dart';
import 'package:talkie_v2/screens/map/place_search_box.dart';
import 'package:talkie_v2/screens/map/vehicle_search_box.dart';
import 'package:talkie_v2/utils/global.dart';

class MarkerSearchBox extends StatefulWidget {
  final List<Vehicle> vehicles;
  final List<PlaceMark> places;
  final Function(double x, double y) onMoveLatLng;
  const MarkerSearchBox({
    super.key,
    required this.vehicles,
    required this.places,
    required this.onMoveLatLng,
  });

  @override
  State<MarkerSearchBox> createState() => _MarkerSearchBoxState();
}

class _MarkerSearchBoxState extends State<MarkerSearchBox> {
  String _selectedValue = 'Giám sát';
  bool _isContainerVisible = false;

  void toggleContainerVisibility() {
    setState(() {
      _isContainerVisible = !_isContainerVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Vehicle> vehicles = widget.vehicles;
    List<PlaceMark> places = widget.places;
    return SizedBox(
      width: 350,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: toggleContainerVisibility,
                    child: Row(
                      children: [
                        Icon(Icons.search, color: primaryColor),
                        SizedBox(width: 8.0),
                        Text(
                          'Tìm Kiếm...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DropdownButton<String>(
                  dropdownColor: Colors.white,
                  value: _selectedValue,
                  items: [
                    DropdownMenuItem<String>(
                      value: 'Giám sát',
                      child: Text('Giám sát'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Hỗ trợ',
                      child: Text('Hỗ trợ'),
                    ),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _selectedValue = newValue!;
                    });
                  },
                  underline: SizedBox(), // Removes the underline
                  icon: Icon(Icons.arrow_drop_down),
                ),
              ],
            ),
          ),
          Visibility(
            visible: _isContainerVisible,
            child: AnimatedContainer(
              width: 350,
              height: MediaQuery.of(context).size.height * 0.7,
              color: Colors.white,
              duration: const Duration(milliseconds: 5),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: 'Phương Tiện'),
                        Tab(text: 'Điểm Đánh Dấu'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: VehicleSearchBox(
                              vehicles: vehicles,
                              onTap: (value) =>
                                  widget.onMoveLatLng(value.x, value.y),
                            ),
                          ),
                          PlaceSearchBox(
                            places: places,
                            onTap: (value) =>
                                widget.onMoveLatLng(value.x, value.y),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            color: primaryColor,
            icon: Icon(
              size: 35,
              _isContainerVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            ),
            onPressed: toggleContainerVisibility,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:talkie_v2/models/map_model.dart';
import 'package:talkie_v2/utils/global.dart';

class PlaceSearchBox extends StatefulWidget {
  final List<PlaceMark> places;
  final Function(PlaceMark value) onTap;
  const PlaceSearchBox({super.key, required this.places, required this.onTap});

  @override
  State<PlaceSearchBox> createState() => _PlaceSearchBoxState();
}

class _PlaceSearchBoxState extends State<PlaceSearchBox> {
  int _selectedIndex = -1;
  int iconID = -1;
  List<int> idList = [];
  TextEditingController searchController = TextEditingController();
  List<PlaceMark> filteredPlaces = [];

  void filterPlaceMarker(String query) {
    setState(() {
      filteredPlaces = widget.places
          .where((e) => e.englishName.contains(query))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    idList = widget.places.map((e) => e.iconID).toSet().toList()..sort();
    filteredPlaces = widget.places;
  }

  @override
  Widget build(BuildContext context) {
    filteredPlaces = widget.places;
    if (searchController.text.isNotEmpty) {
      filterPlaceMarker(searchController.text);
    } else if (iconID != -1) {
      filteredPlaces = filteredPlaces
          .where((element) => element.iconID == iconID)
          .toList();
    }
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 1, child: Text("Loại Icon")),
              Expanded(
                flex: 3,
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      value: iconID,
                      hint: Center(child: Text("Tất cả")),
                      items: [
                        DropdownMenuItem<int?>(
                          value: -1,
                          child: Center(child: Text("Tất cả")),
                        ),
                        ...idList.map(
                          (id) => DropdownMenuItem<int?>(
                            value: id,
                            child: Center(
                              child: Image.asset(
                                'assets/images/places/$id.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          iconID = value!;
                        });
                      },
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
                    onChanged: (value) => filterPlaceMarker(value),
                    onEditingComplete: () =>
                        filterPlaceMarker(searchController.text),
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
                  tableHeaderWidget("Địa điểm"),
                  tableHeaderWidget("Tên"),
                ],
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPlaces.length,
              itemBuilder: (context, index) {
                final place = filteredPlaces[index];
                return SizedBox(
                  height: 40,
                  child: GestureDetector(
                    onTap: () => widget.onTap(place),
                    child: MouseRegion(
                      onEnter: (PointerEvent details) =>
                          setState(() => _selectedIndex = index),
                      onExit: (PointerEvent details) =>
                          setState(() => _selectedIndex = -1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        decoration: BoxDecoration(
                          color: _selectedIndex == index ? Colors.grey : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.blue.shade100,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Image.asset(
                                'assets/images/places/${place.iconID}.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                place.englishName,
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
        ],
      ),
    );
  }

  Widget tableHeaderWidget(String label) {
    return Container(
      color: secondaryColor,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:talkie_v2/models/map_model.dart';
import 'package:talkie_v2/models/vehicle_model.dart';

class MarkerPopup extends StatelessWidget {
  final Marker marker;
  final Vehicle? vehicle;
  final PlaceMark? place;
  const MarkerPopup({
    super.key,
    required this.marker,
    this.vehicle,
    this.place,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(padding: EdgeInsets.all(10), child: _markerDetail()),
      ),
    );
  }

  Widget _markerDetail() {
    if (vehicle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Plate No: ${vehicle!.plateNo}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            "Staff Name: ${vehicle!.staffName}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            "Latitude: ${vehicle!.y}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            "Longitude: ${vehicle!.x}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: 25,
            child: Row(
              children: [
                Text(
                  "Phone: ",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                // if (vehicle!.phoneNo.isNotEmpty)
                //   IconButton(
                //     padding: const EdgeInsets.only(top: 2),
                //     tooltip: 'Call',
                //     hoverColor: Colors.transparent,
                //     icon: const Icon(
                //       Icons.call,
                //       size: 16.0,
                //       color: Colors.green,
                //     ),
                //     onPressed: () {
                //       WidgetsBinding.instance.addPostFrameCallback((_) {
                //         if (softPhoneKey.currentState != null) {
                //           softPhoneKey.currentState?.callPhoneFromOtherWidget(
                //             vehicle!.phoneNo,
                //           );
                //         } else {
                //           log('softPhoneKey.currentState is null');
                //         }
                //       });
                //     },
                //   ),
              ],
            ),
          ),
        ],
      );
    } else if (place != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Name: ${place!.englishName}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            "Description: ${place!.description}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            "Latitude: ${place!.y}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            "Longitude: ${place!.x}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      );
    } else {
      return Text("No data available");
    }
  }
}

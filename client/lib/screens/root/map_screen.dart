import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:talkie_v2/models/map_model.dart';
import 'package:talkie_v2/models/vehicle_model.dart';
import 'package:talkie_v2/screens/map/marker_search_box.dart';
import 'package:talkie_v2/services/map_service.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/string_utils.dart';
import 'package:talkie_v2/widgets/help_dialog.dart';
import 'package:talkie_v2/screens/map/marker_popup.dart';
import 'package:talkie_v2/widgets/tab_widget.dart';
import 'package:toastification/toastification.dart';

class MapScreen extends TabWidget {
  const MapScreen({super.key})
    : super(icon: Icons.map_outlined, title: "Bản đồ");

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<Marker> tappedMarkers = [];
  late final AnimatedMapController _animatedMapController;
  PopupController popupController = PopupController();
  List<LatLng> polylinePoints = [];
  List<PlaceMark> places = [];
  List<Vehicle> vehicles = [];
  List<Marker> vehicleMarkers = [];
  List<Marker> placeMarkers = [];
  ValueNotifier<List<Marker>> markersNotifier = ValueNotifier([]);
  Map<int, String> vehicleStateMap = {};
  Map<int, String> placeStateMap = {};
  bool showPolyline = false;
  LatLng currentLocation = LatLng(21.051873, 105.777787);
  Timer? timer;

  void _getListMapObject() async {
    MapService service = MapService();
    final response = await service.listMapObjects();
    if (response.errorMessage.isEmpty) {
      places = response.places;
      vehicles = response.vehicles;
      updateMarkerVerhicle();
      updateMarkerPlace();
    }
  }

  void updateMarkerVerhicle() {
    for (var vehicle in vehicles) {
      final keyString = "v:${vehicle.vehicleID}";
      bool existed = vehicleMarkers.any(
        (m) => m.key.toString() == "[<'$keyString'>]",
      );
      String state =
          "${vehicle.engineState}${vehicle.currentSpeed}${vehicle.iconID}${vehicle.x}${vehicle.y}";

      if (!existed) {
        Marker marker = createVehicleMarker(vehicle);
        vehicleMarkers.add(marker);
        vehicleStateMap[vehicle.vehicleID] = state;
      } else {
        String oldState = nvl(vehicleStateMap[vehicle.vehicleID]);
        if (state != oldState) {
          vehicleStateMap.update(vehicle.vehicleID, (value) => state);
          vehicleMarkers.removeWhere(
            (element) => element.key.toString() == "[<'$keyString'>]",
          );
          Marker marker = createVehicleMarker(vehicle);
          vehicleMarkers.add(marker);
        }
      }
    }

    filterMarkersInBounds();
  }

  void updateMarkerPlace() {
    for (var place in places) {
      final keyString = "p:${place.placeID}";
      bool existed = placeMarkers.any(
        (m) => m.key.toString() == "[<'$keyString'>]",
      );
      String state = "${place.iconID}${place.englishName}${place.x}${place.y}";

      if (!existed) {
        Marker marker = createPlaceMarker(place);
        placeMarkers.add(marker);
        placeStateMap[place.placeID] = state;
      } else {
        String oldState = nvl(placeStateMap[place.placeID]);
        if (state != oldState) {
          placeStateMap.update(place.placeID, (value) => state);
          placeMarkers.removeWhere(
            (element) => element.key.toString() == "[<'$keyString'>]",
          );
          Marker marker = createPlaceMarker(place);
          placeMarkers.add(marker);
        }
      }
    }

    filterMarkersInBounds();
  }

  void filterMarkersInBounds() {
    LatLngBounds bounds =
        _animatedMapController.mapController.camera.visibleBounds;
    List<Marker> visibleVehicles = vehicleMarkers
        .where((marker) => bounds.contains(marker.point))
        .toList();
    List<Marker> visiblePlaces = placeMarkers
        .where((marker) => bounds.contains(marker.point))
        .toList();

    if (mounted) {
      setState(() {
        markersNotifier.value = [
          ...visibleVehicles,
          ...visiblePlaces,
          ...tappedMarkers,
        ];
      });
    }
  }

  // void getCurrentLocation() async {
  //   bool enabled = await Geolocator.isLocationServiceEnabled();
  //   if (!enabled) {
  //     showToast(
  //       "Vui lòng bật location của Windows để sử dụng tính năng này!",
  //       ToastificationType.warning,
  //     );
  //     return;
  //   }

  //   var permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied ||
  //       permission == LocationPermission.deniedForever) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       showToast(
  //         "Quyền truy cập vị trí bị từ chối. Vui lòng cấp quyền để sử dụng tính năng này!",
  //         ToastificationType.warning,
  //       );
  //       return;
  //     } else if (permission == LocationPermission.deniedForever) {
  //       showToast(
  //         "Quyền truy cập vị trí bị từ chối. Vui lòng cấp quyền trong cài đặt để sử dụng tính năng này!",
  //         ToastificationType.warning,
  //       );
  //       return;
  //     }
  //   }

  //   final position = await Geolocator.getCurrentPosition(
  //     locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
  //   );
  //   currentLocation = LatLng(position.latitude, position.longitude);
  //   setState(() {
  //     polylinePoints.add(currentLocation);
  //   });
  // }

  void animateToCurrentLocation() {
    _animatedMapController.animateTo(
      dest: currentLocation,
      zoom: 18.0,
      rotation: 0,
      curve: Curves.easeInBack,
    );
  }

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
    _getListMapObject();
    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _getListMapObject();
    });
    // getCurrentLocation();
  }

  @override
  void dispose() {
    timer?.cancel();
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        FlutterMap(
          mapController: _animatedMapController.mapController,
          options: MapOptions(
            initialCenter: LatLng(21.051873, 105.777787),
            initialZoom: 16.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            keepAlive: true,
            onMapEvent: (event) {
              updateMarkerVerhicle();
            },
            onTap: (tapPosition, point) {
              popupController.hideAllPopups();
            },
          ),

          children: [
            TileLayer(
              urlTemplate: "$skymapUrl/web_tile.jsp?c={x}&r={y}&z={z}",
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'dev.fleaflet.flutter_map.example',
            ),
            Visibility(
              visible: showPolyline,
              child: PolylineLayer(
                polylines: [
                  Polyline(
                    strokeWidth: 5.5,
                    color: Colors.greenAccent,
                    points: polylinePoints,
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<List<Marker>>(
              valueListenable: markersNotifier,
              builder: (context, markers, child) {
                return PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    popupController: popupController,
                    markers: markers,
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (BuildContext context, Marker marker) {
                        return _buildMarerPopup(marker);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Center(
              child: Icon(Icons.add, color: Colors.black, size: 30),
            ),
          ),
        ),
        Positioned(
          top: 16.0,
          right: 16.0,
          child: Material(
            color: Colors.transparent,
            child: MarkerSearchBox(
              vehicles: vehicles,
              places: places,
              onMoveLatLng: (x, y) {
                _animatedMapController.animateTo(
                  dest: LatLng(y, x),
                  zoom: 18.0,
                  rotation: 0,
                  curve: Curves.easeIn,
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 16.0,
          left: 16.0,
          child: IconButton(
            iconSize: 30,
            color: primaryColor,
            icon: const Icon(Icons.help),
            onPressed: showHelpDialog,
          ),
        ),
      ],
    );
  }

  MarkerPopup _buildMarerPopup(Marker marker) {
    String key = marker.key.toString();
    Vehicle? vehicle;
    PlaceMark? place;
    if (key.contains("v")) {
      final match = RegExp(r'v:(\d+)').firstMatch(key);
      int vehicleID = int.parse(match?.group(1) ?? '0');
      bool existed = vehicles.any((v) => v.vehicleID == vehicleID);
      if (existed) {
        vehicle = vehicles.firstWhere((v) => v.vehicleID == vehicleID);
      }
    } else if (key.contains("p")) {
      final match = RegExp(r'p:(\d+)').firstMatch(key);
      int placeID = int.parse(match?.group(1) ?? '0');
      bool existed = places.any((p) => p.placeID == placeID);
      if (existed) {
        place = places.firstWhere((p) => p.placeID == placeID);
      }
    }
    return MarkerPopup(marker: marker, vehicle: vehicle, place: place);
  }

  void showHelpDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return HelpDialog();
      },
    );
  }

  Marker createVehicleMarker(Vehicle item) {
    return Marker(
      key: Key("v:${item.vehicleID}"),
      width: 200,
      height: 50,
      point: LatLng(item.y, item.x),
      child: Column(
        children: [
          Stack(
            children: [
              Text(
                item.plateNo,
                style: TextStyle(
                  fontSize: 12,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 0.5
                    ..color = Colors.lightGreen,
                ),
              ),
              Text(
                item.plateNo,
                style: TextStyle(fontSize: 12, color: Color(item.textColor)),
              ),
            ],
          ),
          Image.asset(
            'assets/images/vehicles/${item.iconID}.png',
            width: 25,
            height: 25,
          ),
        ],
      ),
    );
  }

  Marker createPlaceMarker(PlaceMark item) {
    return Marker(
      key: Key("p:${item.placeID}"),
      width: 500,
      height: 50,
      point: LatLng(item.y, item.x),
      child: Column(
        children: [
          Stack(
            children: [
              Text(
                item.englishName,
                style: TextStyle(
                  fontSize: 12,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 0.5
                    ..color = Colors.lightGreen,
                ),
              ),
              Text(
                item.englishName,
                style: TextStyle(fontSize: 12, color: Color(item.textColor)),
              ),
            ],
          ),
          Image.asset(
            'assets/images/places/${item.iconID}.png',
            width: 25,
            height: 25,
          ),
        ],
      ),
    );
  }
}

import 'package:talkie_v2/models/action_result.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/string_utils.dart';

class Vehicle {
  int vehicleID = 0;
  int customerID = 0;
  double x = 0;
  double y = 0;
  String plateNo = "";
  String vehicleCode = "";
  String deviceType = "";
  String showPlateNo = "";
  double currentSpeed = 0;
  int pulseSpeed = 0;
  int direction = 0;
  String contactNo = "";
  DateTime? createDate;
  DateTime? updateDate;
  String gpsDate = "";
  String engineState = "";
  String gpsState = "";
  int vibrator = 0;
  double fuelAmount = 0;
  double fuelAmount2 = 0;
  double totalFuelAmount = 0;
  double totalFuelAmount2 = 0;
  bool hasTemper = false;
  double temper1 = 0;
  double temper2 = 0;
  int staffID = 0;
  String staffName = "";
  String licenseNo = "";
  String versionNo = "";
  String vehicleNo = "";
  bool hasCamera = false;
  bool hasFuelSensor = false;
  int cameraEnable = 0;
  bool shareCam = false;
  int status = 0;
  String iconID = "";
  int textColor = 0;
  DateTime? stopDate;
  int stopDuration = 0;
  int dailyDrivingDuration = 0;
  int drivingDuration = 0;
  int numOfOverSpeed = 0;
  int dailyEstFuelUsage = 0;
  double dailyDistance = 0;
  bool locked = false;
  bool sendToMT = false;
  int seatChartID = 0;
  int vehicleStatus = 0;
  int vehicleConfig = 0;
  int totalPassenger = 0;
  bool isExcavator = false;
  int excavatorID = 0;
  String colorState = ""; // Color state of the vehicle (UI)

  Vehicle();

  String getVehicleColorState() {
    // Tránh lỗi nếu iconID bị rỗng hoặc không đúng định dạng chứa dấu '_'
    if (iconID.isEmpty || !iconID.contains('_')) {
      return "green"; // Trả về màu mặc định hoặc màu dự phòng tùy ý bạn
    }

    Map<String, List<String>> data = {
      "0": ["green", "red", "yellow", "purple", "lightpink"],
      "1": ["green", "red", "lightpink", "lightblue", "yellow", "purple"],
      "2": [
        "heavy pink",
        "cyan",
        "heavy blue",
        "green",
        "yellow",
        "red",
        "gray",
        "brown",
        "purple",
      ],
      "3": ["green", "red", "lightpink", "lightblue", "yellow"],
      "4": [
        "green",
        "red",
        "lightpink",
        "lightblue",
        "yellow",
        "purple",
        "lightgray",
      ],
    };

    List<String> strSplit = iconID.split("_");

    // Kiểm tra xem mảng sau khi split có đủ phần tử không (ít nhất phải có 3 phần tử để lấy index 2)
    if (strSplit.length < 3) {
      return "green";
    }

    String start = strSplit[0];

    // Kiểm tra xem key `start` có tồn tại trong map `data` không
    if (!data.containsKey(start)) {
      return "green";
    }

    int index = (int.tryParse(strSplit[2]) ?? 1) - 1;
    List<String> colorList = data[start]!;

    // Đảm bảo index nằm trong khoảng hợp lệ của mảng tránh lỗi RangeError
    if (index >= 0 && index < colorList.length) {
      return colorList[index];
    }

    // Nếu index vẫn vượt quá giới hạn, trả về phần tử đầu tiên hoặc mặc định
    return colorList.isNotEmpty ? colorList[0] : "green";
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    Vehicle model = Vehicle();
    model.vehicleID = json[F_VEHICLE_ID] ?? 0;
    model.customerID = json[F_CUSTOMER_ID] ?? 0;
    model.x = json[F_X] ?? 0;
    model.y = json[F_Y] ?? 0;
    model.plateNo = nvl(json[F_PLATE_NO]);
    model.vehicleCode = nvl(json[F_VEHICLE_CODE]);
    model.deviceType = nvl(json[F_DEVICE_TYPE]);
    model.showPlateNo = nvl(json[F_SHOW_PLACE_NO]);
    model.currentSpeed = json[F_CURRENT_SPEED] ?? 0;
    model.pulseSpeed = json[F_PULSE_SPEED] ?? 0;
    model.direction = json[F_DIRECTION] ?? 0;
    model.contactNo = nvl(json[F_CONTACT_NO]);
    model.createDate = nvl(json[F_CREATE_DATE]).parseTz;
    model.updateDate = nvl(json[F_UPDATE_DATE]).parseTz;
    model.gpsDate = nvl(json[F_GPS_DATE]);
    model.engineState = nvl(json[F_ENGINE_STATE]);
    model.gpsState = nvl(json[F_GPS_STATE]);
    model.vibrator = json[F_VIBRATOR] ?? 0;
    model.fuelAmount = json[F_FUEL_AMOUNT] ?? 0;
    model.fuelAmount2 = json[F_FUEL_AMOUNT_2] ?? 0;
    model.totalFuelAmount = json[F_TOTAL_FUEL_AMOUNT] ?? 0;
    model.totalFuelAmount2 = json[F_TOTAL_FUEL_AMOUNT_2] ?? 0;
    model.hasTemper = json[F_HAS_TEMPER];
    model.temper1 = json[F_TEMPER_1] ?? 0;
    model.temper2 = json[F_TEMPER_2] ?? 0;
    model.staffID = json[F_STAFF_ID] ?? 0;
    model.staffName = nvl(json[F_STAFF_NAME]);
    model.licenseNo = nvl(json[F_LICENSE_NO]);
    model.versionNo = nvl(json[F_VERSION_NO]);
    model.vehicleNo = nvl(json[F_VEHICLE_NO]);
    model.hasCamera = json[F_HAS_CAMERA] ?? false;
    model.hasFuelSensor = json[F_HAS_FUEL_SENSOR] ?? false;
    model.cameraEnable = json[F_CAMERA_ENABLE] ?? 0;
    model.shareCam = json[F_SHARE_CAM] ?? false;
    model.status = json[F_STATUS] ?? 0;
    model.iconID = nvl(json[F_ICON_ID]);
    model.textColor = json[F_TEXT_COLOR] ?? 0;
    model.stopDate = nvl(json[F_STOP_DATE]).parseTz;
    model.stopDuration = json[F_STOP_DURATION] ?? 0;
    model.dailyDrivingDuration = json[F_DAILY_DRIVING_DURATION] ?? 0;
    model.drivingDuration = json[F_DRIVING_DURATION] ?? 0;
    model.numOfOverSpeed = json[F_NUM_OF_OVER_SPEED] ?? 0;
    model.dailyEstFuelUsage = json[F_DAILY_EST_FUEL_USAGE] ?? 0;
    model.dailyDistance = json[F_DAILY_DISTANCE] ?? 0;
    model.locked = json[F_LOCKED] ?? false;
    model.sendToMT = json[F_SEND_TO_MT] ?? false;
    model.seatChartID = json[F_SEAT_CHART_ID] ?? 0;
    model.vehicleStatus = json[F_VEHICLE_STATUS] ?? 0;
    model.vehicleConfig = json[F_VEHICLE_CONFIG] ?? 0;
    model.totalPassenger = json[F_TOTAL_PASSENGER] ?? 0;
    model.excavatorID = json[F_EXCAVATOR_ID] ?? 0;
    model.isExcavator = json[F_IS_EXCAVATOR] ?? false;
    model.colorState = model.getVehicleColorState();
    return model;
  }
}

class VehiclesResponse extends ActionResult {
  List<Vehicle> vehicles = [];

  VehiclesResponse(super.errorCode, super.errorMessage);

  factory VehiclesResponse.fromJson(Map<String, dynamic> json) {
    VehiclesResponse response = VehiclesResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    if (response.errorMessage.isNotEmpty) {
      return response;
    }

    var vehicles = json[F_VEHICLES];

    if (vehicles != null) {
      response.vehicles = (vehicles as List)
          .map((e) => Vehicle.fromJson(e))
          .toList();
    }

    return response;
  }
}

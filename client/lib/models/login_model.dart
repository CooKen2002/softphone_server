import '../models/action_result.dart';
import '../utils/string_utils.dart';

import '../utils/constants.dart';

class LoginRequest {
  String userName = "";
  String password = "";
  String? appOs = "";
  String? osVersion = "";
  String? deviceID = "";
  String? deviceName = "";
  String? deviceModel = "";
  String? deviceBrand = "";
  String? appVersion = "";
  String? fireBaseToken = "";
  bool reconnect = false;

  @override
  String toString() {
    return '{appOs: $appOs, deviceName: $deviceName, firebaseTo: $fireBaseToken}';
  }

  LoginRequest();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_USER_NAME: nvl(userName).trim(),
      F_PASSWORD: nvl(password).trim(),
      F_DEVICE_ID: nvl(deviceID),
      F_DEVICE_NAME: nvl(deviceName),
      F_DEVICE_MODEL: nvl(deviceModel),
      F_DEVICE_BRAND: nvl(deviceBrand),
      F_APP_OS: nvl(appOs),
      F_OS_VERSION: nvl(osVersion),
      F_APP_VERSION: nvl(appVersion),
      F_FIREBASE_TOKEN: nvl(fireBaseToken),
      F_RECONNECT: reconnect,
    };

    return map;
  }
}

class LoginResponse extends ActionResult {
  String loginState = "";
  String userName = "";
  int customerID = -1;
  String customerName = "";
  String tokenID = "";
  int userID = 0;
  List<int> seatCapacities = [];

  LoginResponse(super.errorCode, super.errorMessage);

  static Future<LoginResponse> fromJson(Map<String, dynamic> json) async {
    LoginResponse response = LoginResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    response.loginState = nvl(json[F_LOGIN_STATE]);
    if (response.loginState != "OK") {
      return response;
    }

    response.userName = nvl(json[F_USER_NAME]);
    response.customerID = json[F_CUSTOMER_ID] ?? 0;
    response.customerName = nvl(json[F_CUSTOMER_NAME]);
    response.tokenID = nvl(json[F_TOKEN_ID]);
    response.userID = json[F_USER_ID] ?? 0;

    var seatCapacities = json[F_SEAT_CAPACITIES];
    if (seatCapacities != null) {
      response.seatCapacities = seatCapacities.cast<int>();
    }

    return response;
  }
}

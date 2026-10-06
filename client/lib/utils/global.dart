// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:talkie_v2/models/login_model.dart';
import 'package:toastification/toastification.dart';

import 'bare_sip.dart';

// const String baseUrl = "https://tracking.skysoft.vn";
const String baseUrl = "https://dev.skysoft.vn";
const String skymapUrl = "https://maps.skysoft.vn";

FlutterSecureStorage secureStorage = const FlutterSecureStorage();

LoginRequest loginRequest = LoginRequest();
LoginResponse loginResponse = LoginResponse("", "");

Color primaryColor = Color(0xff124B82);
Color secondaryColor = Color(0xff3FB9D0);

// soft phone
late BareSip bareSip;
// BareSipReceiver receiver = BareSipReceiver();

Future<void> saveData(String key, String value) async {
  await secureStorage.write(key: key, value: value);
}

Future<String?> readData(String key) async {
  return secureStorage.read(key: key);
}

void showToast(String msg, ToastificationType type) {
  toastification.show(
    title: Text(msg),
    type: type,
    style: ToastificationStyle.flatColored,
    alignment: Alignment.bottomCenter,
    autoCloseDuration: Duration(seconds: 3),
  );
}

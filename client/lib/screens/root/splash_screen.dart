import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:page_transition/page_transition.dart';
import 'package:talkie_v2/models/login_model.dart';
import 'package:talkie_v2/screens/root/login_screen.dart';
import 'package:talkie_v2/screens/root/main_screen.dart';
import 'package:talkie_v2/services/admin_service.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/string_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadStatus = "Loading.";

  void _initPlatformState() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final appInfo = await PackageInfo.fromPlatform();
    if (Platform.isWindows) {
      final deviceData = await deviceInfoPlugin.windowsInfo;
      loginRequest.appOs = "win";
      loginRequest.osVersion = deviceData.displayVersion;
      loginRequest.deviceID = deviceData.deviceId;
      loginRequest.deviceName = deviceData.computerName;
      loginRequest.appVersion = appInfo.version;
    }
  }

  void startApp() async {
    setState(() {
      _loadStatus = "Loading..";
    });

    String? userName = await readData(F_USER_NAME);
    String? password = await readData(F_PASSWORD);
    String firebaseToken = nvl(await readData(F_FIREBASE_TOKEN));

    setState(() {
      _loadStatus = "Starting...";
    });

    loginRequest.fireBaseToken = firebaseToken;

    if (nvl(userName).isNotEmpty) {
      loginRequest.userName = nvl(userName);
      loginRequest.password = nvl(password);
      loginRequest.reconnect = true;

      setState(() {
        _loadStatus = "Logging in...";
      });

      AdminService service = AdminService();
      LoginResponse response = await service.login(loginRequest);
      if (response.loginState == "OK") {
        setState(() {
          _loadStatus = "Logging OK...";
        });
        loginResponse = response;
        _gotoHomeScreen();
      } else {
        setState(() {
          _loadStatus = "Login failed...";
        });
        _gotoLoginScreen();
      }
    } else {
      setState(() {
        _loadStatus = "No config found...";
      });
      _gotoLoginScreen();
    }
  }

  void _gotoLoginScreen() {
    Navigator.of(context).pushReplacement(
      PageTransition(
        child: LoginScreen(),
        type: PageTransitionType.leftToRight,
      ),
    );
  }

  void _gotoHomeScreen() {
    Navigator.of(context).pushReplacement(
      PageTransition(child: MainScreen(), type: PageTransitionType.leftToRight),
    );
  }

  @override
  void initState() {
    super.initState();
    _initPlatformState();
    startApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/skysoft_logo_ok_h80.png",
              fit: BoxFit.fitHeight,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_loadStatus),
          ],
        ),
      ),
    );
  }
}

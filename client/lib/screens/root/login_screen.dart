import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:talkie_v2/models/login_model.dart';
import 'package:talkie_v2/screens/root/main_screen.dart';
import 'package:talkie_v2/services/admin_service.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/widgets/progress_hud.dart';

import '../../utils/global.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isApiCallProcess = false;
  bool _passVis = true;
  String _errorMessage = "";
  FocusNode passwordFocusNode = FocusNode();

  void _doLogin() async {
    setState(() {
      isApiCallProcess = true;
    });

    FocusScope.of(context).unfocus();

    AdminService service = AdminService();

    LoginResponse value = await service.login(loginRequest);

    _processLoginResult(value);
  }

  Future<void> _processLoginResult(LoginResponse value) async {
    if (mounted) {
      setState(() {
        isApiCallProcess = false;
      });
    }

    if (value.loginState == "OK") {
      loginResponse = value;
      await saveData(F_USER_NAME, loginRequest.userName);
      await saveData(F_PASSWORD, loginRequest.password);

      _gotoHomeScreen();
    } else {
      if (value.errorMessage.contains("SocketException")) {
        _errorMessage = "Lỗi kết nối mạng";
      } else {
        _errorMessage = value.errorMessage;
      }
      setState(() {});
    }
  }

  void _gotoHomeScreen() {
    Navigator.of(context).pushReplacement(
      PageTransition(child: MainScreen(), type: PageTransitionType.leftToRight),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      inAsyncCall: isApiCallProcess,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 100.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/skysoft_logo_ok_h80.png',
                  fit: BoxFit.fitHeight,
                ),
                SizedBox(height: 50),
                Text(
                  "Đăng nhập",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                SizedBox(height: 20),
                Card(
                  // elevation: 5.0,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          onChanged: (value) => loginRequest.userName = value,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: "Tên truy nhập",
                            hintStyle: TextStyle(
                              color: Color(0xFFBDC2CB),
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.0),
                        TextFormField(
                          onChanged: (value) => loginRequest.password = value,
                          onEditingComplete: _doLogin,
                          focusNode: passwordFocusNode,
                          obscureText: _passVis,
                          decoration: InputDecoration(
                            hintText: "Mật khẩu",
                            hintStyle: const TextStyle(
                              color: Color(0xFFBDC2CB),
                              fontSize: 18.0,
                            ),
                            suffixIcon: Focus(
                              descendantsAreFocusable: false,
                              canRequestFocus: false,
                              child: IconButton(
                                icon: _passVis
                                    ? const Icon(Icons.visibility_off)
                                    : const Icon(Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _passVis = !_passVis;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Visibility(
                          visible: _errorMessage.isNotEmpty,
                          child: Text(
                            _errorMessage,
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        ),
                        SizedBox(height: 22.0),
                        TextButton(
                          style: ButtonStyle(
                            foregroundColor: WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                          ),
                          onPressed: _doLogin,
                          child: Container(
                            height: 50.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35.0),
                              color: Colors.blue,
                            ),
                            child: Center(
                              child: Text(
                                "Đăng nhập",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

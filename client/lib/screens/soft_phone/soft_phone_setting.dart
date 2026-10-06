import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:talkie_v2/models/soft_phone_model.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:toastification/toastification.dart';

class SoftPhoneSetting extends StatefulWidget {
  const SoftPhoneSetting({
    super.key,
    required this.uaList,
    required this.uA,
    required this.onRegister,
    required this.onUnRegister,
    required this.onRefesh,
    required this.onStop,
  });
  final List<UA> uaList;
  final ValueNotifier<String> uA;
  final Function(UA model) onRegister;
  final Function(UA model) onUnRegister;
  final Function(UA model) onRefesh;
  final Function onStop;
  @override
  State<SoftPhoneSetting> createState() => _SoftPhoneSettingState();
}

class _SoftPhoneSettingState extends State<SoftPhoneSetting> {
  Color buttonClose = Colors.red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt soft phone'),
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          SizedBox(
            height: 45,
            width: 45,
            child: IconButton(
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onHover: (value) {
                setState(() {
                  buttonClose = value ? Colors.red.shade200 : Colors.red;
                });
              },
              icon: Icon(Icons.close, color: buttonClose),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Spacer(),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.blue.shade100,
                    ),
                  ),
                  onPressed: () async {
                    UA? ua = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Edituser(uaList: widget.uaList);
                      },
                    );

                    if (ua != null) {
                      setState(() {
                        widget.uaList.add(ua);
                      });
                      List<String> value = widget.uaList
                          .map((user) => jsonEncode(user.toJson()))
                          .toList();

                      await saveData(F_ALL_USER, jsonEncode(value));
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_sharp),
                      const SizedBox(width: 5),
                      Text("Thêm đầu số"),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.red.shade100,
                    ),
                  ),
                  onPressed: () {
                    for (var element in widget.uaList) {
                      if (element.status == STATUS_UA.NOTCONNECT) continue;
                      element.status = STATUS_UA.NOTCONNECT;
                      widget.onUnRegister(element);
                    }
                    // if (kDebugMode) widget.onStop.call();
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.stop_circle_outlined, color: Colors.red),
                      SizedBox(width: 5),
                      Text(
                        "Ngắt kết nối tất cả  ",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Container(
              height: 45,
              color: Colors.blue,
              child: Row(
                children: [
                  createCellTable(
                    'Trạng Thái',
                    flex: 1,
                    colorText: Colors.white,
                    colorSpacing: Colors.white,
                  ),
                  createCellTable(
                    'Tự Động\nKết Nối',
                    flex: 1,
                    colorText: Colors.white,
                    colorSpacing: Colors.white,
                  ),
                  createCellTable(
                    'SIP',
                    flex: 4,
                    colorText: Colors.white,
                    colorSpacing: Colors.white,
                  ),
                  createCellTable(
                    'Đầu Số',
                    flex: 4,
                    colorText: Colors.white,
                    colorSpacing: Colors.white,
                  ),
                  createCellTable(
                    'Mật Khẩu',
                    flex: 4,
                    colorText: Colors.white,
                    colorSpacing: Colors.white,
                  ),
                  createCellTable(
                    'Hành Động',
                    flex: 4,
                    colorText: Colors.white,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.uaList.length,
                itemBuilder: (context, index) {
                  UA ua = widget.uaList[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: index % 2 == 0
                          ? Colors.white
                          : Colors.grey.shade100,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Icon(
                              Icons.circle,
                              color: ua.status == STATUS_UA.CONNECTED
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Checkbox(
                              splashRadius: 0,
                              value: ua.autoConnect,
                              onChanged: (value) {
                                setState(() {
                                  ua.autoConnect = value ?? false;
                                });
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Center(child: Text(ua.server ?? "")),
                        ),
                        Expanded(
                          flex: 4,
                          child: Center(child: Text(ua.hotLine ?? "")),
                        ),
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    ua.showPass ? "**********" : ua.pass ?? "",
                                  ),
                                ),
                              ),
                              IconButton(
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                icon: Icon(
                                  ua.showPass
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    ua.showPass = !ua.showPass;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Row(
                            spacing: 10,
                            children: [
                              IconButton(
                                color: Colors.green,
                                icon: const Icon(Icons.link),
                                onPressed: () {
                                  if (ua.status == STATUS_UA.CONNECTED) return;
                                  widget.onRegister(ua);
                                },
                              ),
                              IconButton(
                                color: Colors.blueGrey,
                                icon: const Icon(Icons.link_off),
                                onPressed: () async {
                                  if (ua.status == STATUS_UA.NOTCONNECT) return;
                                  widget.onUnRegister(ua);
                                },
                              ),
                              IconButton(
                                color: Colors.red,
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  bool? ret = await showConfirmDialog();
                                  if (ret ?? false) {
                                    if (ua.status == STATUS_UA.CONNECTED) {
                                      widget.onUnRegister(ua);
                                    }

                                    if (widget.uaList.remove(ua)) {
                                      List<String> uaStrings = widget.uaList
                                          .map(
                                            (user) => jsonEncode(user.toJson()),
                                          )
                                          .toList();

                                      await secureStorage.write(
                                        key: F_ALL_USER,
                                        value: jsonEncode(uaStrings),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget createCellTable(
    String label, {
    int? flex,
    Color? colorText,
    Color? colorSpacing,
    TextAlign? textAlign,
  }) {
    return Expanded(
      flex: flex ?? 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          border: BoxBorder.fromLTRB(
            right: BorderSide(color: colorSpacing ?? Colors.transparent),
          ),
        ),
        child: Text(
          style: TextStyle(color: colorText ?? Colors.black),
          label,
          textAlign: textAlign ?? TextAlign.center,
        ),
      ),
    );
  }

  Future<bool?> showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận"),
        content: Text("Bạn có chắc chắn muốn xoá đầu số này không?"),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Xác nhận"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Hủy"),
          ),
        ],
      ),
    );
  }
}

class Edituser extends StatefulWidget {
  const Edituser({super.key, this.user, required this.uaList});
  final UA? user;
  final List<UA> uaList;

  @override
  State<Edituser> createState() => _EditUserState();
}

class _EditUserState extends State<Edituser> {
  bool _isObscure = true;
  bool _autoConnect = false;

  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void getInfoUser() {
    if (widget.user == null) return;
    _serverController.text = widget.user!.server ?? '';
    _userController.text = widget.user!.hotLine ?? '';
    _passwordController.text = widget.user!.pass ?? '';
    _autoConnect = widget.user!.autoConnect!;
  }

  @override
  void initState() {
    super.initState();
    getInfoUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.user == null ? "Thêm mới" : "Cập nhật",
        style: TextStyle(fontWeight: FontWeight.w400),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 14.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextFormField(
              "SIP/Register Server",
              "192.168.1.1",
              Icons.router,
              _serverController,
            ),
            const SizedBox(height: 10, width: 300),
            _buildTextFormField("User", "1991", Icons.person, _userController),
            const SizedBox(height: 10),
            _buildPasswordFormField(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: () {
                    setState(() {
                      _autoConnect = !_autoConnect;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        splashRadius: 0,
                        value: _autoConnect,
                        onChanged: (bool? value) {
                          setState(() {
                            _autoConnect = value ?? false;
                          });
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Auto Connect',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Save", style: TextStyle(fontSize: 18)),
          onPressed: () async {
            for (var ua in widget.uaList) {
              if (ua.server == _serverController.text &&
                  ua.hotLine == _userController.text) {
                showToast(
                  "Bạn đã đăng ký đầu số này rồi !!!",
                  ToastificationType.warning,
                );
                return;
              }
            }

            UA model = UA.fromJson({
              F_SOFTPHONE_REGISTER_SERVER: _serverController.text,
              F_SOFTPHONE_USER: _userController.text,
              F_SOFTPHONE_PASSWORD: _passwordController.text,
              F_SOFTPHONE_AUTOCONNECT: _autoConnect,
            });

            Navigator.of(context).pop(model);
          },
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildTextFormField(
    String labelText,
    String hintText,
    IconData icon,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFormField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Password",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: "*********",
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            ),
            border: const OutlineInputBorder(),
          ),
          obscureText: _isObscure,
        ),
      ],
    );
  }
}

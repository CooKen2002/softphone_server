import 'package:flutter/material.dart';
import 'package:flutter_soft_phone/flutter_soft_phone.dart';
import 'package:flutter_voice_chatbot/voice_chatbot_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SoftPhonePage());
  }
}

class SoftPhonePage extends StatefulWidget {
  const SoftPhonePage({super.key});

  @override
  State<SoftPhonePage> createState() => _SoftPhonePageState();
}

class _SoftPhonePageState extends State<SoftPhonePage> {
  SoftPhoneController? _phone;
  // Websocket controller
  late final VoiceChatBotController _wsServer = VoiceChatBotController();

  String _status = 'Chưa khởi động';

  final _server = TextEditingController();
  final _ws_server = TextEditingController();
  final _hotline = TextEditingController();
  final _password = TextEditingController();
  final _number = TextEditingController();

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Mở DLL và khởi động baresip. Nếu DLL không load được, lỗi sẽ hiện ở đây.
  Future<void> _start() async {
    try {
      final phone = SoftPhoneController();
      await phone.init();
      setState(() {
        _phone = phone;
        _status = 'baresip đã chạy (DLL load OK)';
      });
    } catch (e) {
      setState(() => _status = 'Lỗi khởi động: $e');
    }
  }

  @override
  void dispose() {
    _phone?.shutdown();
    _phone?.dispose();
    for (final c in [_server, _ws_server, _hotline, _password, _number]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    final phone = _phone;
    if (phone == null) return;
    final account = SipAccount(
      uid: "",
      server: _server.text.trim(),
      hotline: _hotline.text.trim(),
      password: _password.text,
    );
    // Chờ baresip báo kết quả thật từ server SIP (tối đa 10 giây).
    final ok = await phone.registerAndWait(account);
    if (!mounted) return;
    setState(() {
      _status = ok
          ? 'Đăng ký ${account.hotline} thành công'
          : 'Đăng ký ${account.hotline} thất bại hoặc quá thời gian chờ';
    });
  }

  @override
  Widget build(BuildContext context) {
    final phone = _phone;
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_soft_phone example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: phone == null
            ? Text(_status)
            : ListenableBuilder(
                listenable: phone,
                builder: (context, _) => ListView(
                  children: [
                    Text(_status),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _server,
                      decoration: const InputDecoration(
                        labelText: 'SIP server',
                      ),
                    ),
                    TextField(
                      controller: _hotline,
                      decoration: const InputDecoration(labelText: 'Hotline'),
                    ),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: _register,
                          child: const Text('Đăng ký'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: phone.isOnline
                              ? phone.unregisterAll
                              : null,
                          child: const Text('Huỷ đăng ký'),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          phone.isOnline ? 'Online' : 'Offline',
                        ), // Thay phone bằng ws
                      ],
                    ),
                    const Divider(height: 32),
                    // MARK: CONNECT WS SV
                    TextField(
                      controller: _ws_server,
                      decoration: const InputDecoration(
                        labelText: 'Websocket IP server',
                        hintText: 'ws://your_server_ip:port',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () async {
                            // Gán URL từ TextField vào controller trước khi kết nối
                            _wsServer.webSocketURL = _ws_server.text.trim();
                            await _wsServer.connectWebSocketChatBot();
                            setState(() {}); // Cập nhật lại giao diện trạng thái Online/Offline
                          },
                          child: const Text('Kết nối'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: () async {
                            // Gán URL từ TextField vào controller trước khi kết nối
                            _wsServer.webSocketURL = _ws_server.text.trim();
                            await _wsServer.disconnectWebSocketChatBot();
                            setState(() {}); // Cập nhật lại giao diện trạng thái Online/Offline
                          },
                          child: const Text('Đóng kết nối'),
                        ),
                        const SizedBox(width: 16),
                        Text(_wsServer.isConnected ? 'Online' : 'Offline'),
                      ],
                    ),
                    const Divider(height: 32),
                    TextField(
                      controller: _number,
                      decoration: const InputDecoration(
                        labelText: 'Số cần gọi',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: phone.hasCall
                              ? null
                              : () => phone.dial(_number.text.trim()),
                          child: const Text('Gọi'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed:
                              phone.currentCall?.isIncoming == true &&
                                  phone.currentCall?.isRinging == true
                              ? phone.answer
                              : null,
                          child: const Text('Trả lời'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: phone.hasCall ? phone.hangup : null,
                          child: const Text('Cúp máy'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (phone.currentCall != null)
                      Text('Cuộc gọi: ${phone.currentCall}'),
                    if (phone.message.isNotEmpty)
                      Text(
                        phone.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

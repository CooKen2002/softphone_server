import 'package:flutter/material.dart';
import 'package:flutter_soft_phone/flutter_soft_phone.dart';
import 'package:flutter_voice_chatbot/flutter_voice_chatbot.dart';

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
  VoiceChatbot? _bot;
  bool _botEnabled = false; // bật thì bot tự nhận cuộc gọi đến và nói chuyện
  BotState _botState = BotState.idle;
  final List<String> _botTexts = [];

  String _status = 'Chưa khởi động';

  final _company = TextEditingController();
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

      final bot = VoiceChatbot(
        // URL thật được gán lúc có cuộc gọi (xem _onCallChanged)
        transport: ChatbotTransport(Uri.parse('ws://localhost')),
        detector: SpeechDetector(),
        playReply: phone.audioOut.playWav, // giọng bot phát ra cuộc gọi
        cancelReply: phone.audioOut.reset, // cúp máy thì xoá phần chưa phát
      );
      bot.states.listen((s) {
        if (mounted) setState(() => _botState = s);
      });
      bot.texts.listen((t) {
        if (!mounted) return;
        setState(() {
          _botTexts.add(t);
          if (_botTexts.length > 5) _botTexts.removeAt(0);
        });
      });
      bot.errors.listen((e) {
        if (mounted) setState(() => _status = 'Bot: $e');
      });
      _bot = bot;

      // Một callback duy nhất xử lý cả trả lời tự động lẫn bật/tắt bot
      phone.onCallChanged = (call) async {
        debugPrint('[Call] $call | botEnabled=$_botEnabled');
        if (call == null) {
          await bot.stop(); // cuộc gọi kết thúc
          return;
        }
        if (!_botEnabled) return;

        if (call.isIncoming && call.isRinging) {
          phone.answer(); // bot tự nhận máy
        } else if (call.isActive) {
          final url = _ws_server.text.trim();
          final company = _company.text.trim();
          if (url.isEmpty || company.isEmpty) {
            if (mounted)
              setState(
                () => _status = 'Cần nhập Websocket server và tên công ty',
              );
            return;
          }
          try {
            bot.transport.url = Uri.parse(url);
          } on FormatException {
            if (mounted) setState(() => _status = 'URL websocket không hợp lệ');
            return;
          }
          final ok = await bot.start(
            phone.audioIn.frames,
            company: company,
            phone: call.remoteNumber, // số người gọi (cuộc gọi đến) hoặc số mình gọi (cuộc gọi ra)
          );
          if (!ok) phone.hangup();
        }
      };

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
    _bot?.dispose(); // trước khi shutdown phone
    _phone?.onCallChanged = null;
    _phone?.shutdown();
    _phone?.dispose();
    for (final c in [
      _server,
      _ws_server,
      _company,
      _hotline,
      _password,
      _number,
    ]) {
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
                        Text(phone.isOnline ? 'Online' : 'Offline'),
                      ],
                    ),
                    const Divider(height: 32),

                    // MARK: BOT + WEBSOCKET
                    TextField(
                      controller: _ws_server,
                      decoration: const InputDecoration(
                        labelText: 'Websocket IP server',
                        hintText: 'ws://your_server_ip:port',
                      ),
                    ),
                    TextField(
                      controller: _company,
                      decoration: const InputDecoration(
                        labelText: 'Tên công ty',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bot tự trả lời cuộc gọi'),
                      subtitle: Text('Trạng thái bot: ${_botState.name}'),
                      value: _botEnabled,
                      onChanged: (v) => setState(() => _botEnabled = v),
                    ),
                    for (final t in _botTexts) Text('Bot: $t'),
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

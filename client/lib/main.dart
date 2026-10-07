import 'package:flutter/material.dart';

void main() => runApp(const SoftphoneApp());

const _navy = Color(0xFF17243A);
const _muted = Color(0xFF7C8798);
const _blue = Color(0xFF3969E8);
const _background = Color(0xFFF5F7FB);

class SoftphoneApp extends StatelessWidget {
  const SoftphoneApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Talkie',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
    ),
    themeMode: ThemeMode.system,
    home: const SoftphoneHomePage(),
  );
}

class SoftphoneHomePage extends StatefulWidget {
  const SoftphoneHomePage({super.key});

  @override
  State<SoftphoneHomePage> createState() => _SoftphoneHomePageState();
}

class _SoftphoneHomePageState extends State<SoftphoneHomePage> {
  String _number = '';
  bool _inCall = false;
  int _selectedTab = 0;

  void _append(String value) => setState(() => _number += value);

  void _toggleCall() {
    if (_number.isEmpty && !_inCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a number to start a call')),
      );
      return;
    }
    setState(() => _inCall = !_inCall);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      _connectionCard(),
                      const SizedBox(height: 20),
                      _dialer(),
                      const SizedBox(height: 20),
                      _recentCalls(),
                    ],
                  ),
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.headset_mic_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Softphone',
                style: TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'HOST COMMUNICATIONS',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined, color: _navy),
        ),
        const CircleAvatar(
          radius: 19,
          backgroundColor: Color(0xFFE6ECFA),
          child: Text(
            'C',
            style: TextStyle(color: _blue, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  Widget _connectionCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF315FD4), Color(0xFF5485F4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: _blue.withOpacity(.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.cloud_done_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected to host',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Your line is ready to make calls',
                style: TextStyle(color: Color(0xFFDDE7FF), fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: Color(0xFF7BF0B0), size: 8),
              SizedBox(width: 6),
              Text(
                'ONLINE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dialer() => Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: _navy.withOpacity(.05),
          blurRadius: 22,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Make a call',
                style: TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.contacts_outlined, size: 17),
              label: const Text('Contacts'),
              style: TextButton.styleFrom(
                foregroundColor: _blue,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_in_talk_outlined, color: _muted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _number.isEmpty ? 'Enter name or number' : _number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _number.isEmpty ? const Color(0xFFA7AFBC) : _navy,
                    fontSize: 18,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_number.isNotEmpty)
                IconButton(
                  tooltip: 'Delete digit',
                  onPressed: () => setState(
                    () => _number = _number.substring(0, _number.length - 1),
                  ),
                  icon: const Icon(
                    Icons.backspace_outlined,
                    color: _muted,
                    size: 19,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['*', '0', '#'],
        ])
          Row(
            children: row
                .map((digit) => Expanded(child: _digitButton(digit)))
                .toList(),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _toggleCall,
                  icon: Icon(
                    _inCall ? Icons.call_end_rounded : Icons.call_rounded,
                    size: 21,
                  ),
                  label: Text(
                    _inCall ? 'End call' : 'Call',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _inCall
                        ? const Color(0xFFE54D5D)
                        : const Color(0xFF27B879),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => _append('+'),
                icon: const Icon(Icons.add, color: _muted),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _digitButton(String digit) {
    final letters = switch (digit) {
      '2' => 'ABC',
      '3' => 'DEF',
      '4' => 'GHI',
      '5' => 'JKL',
      '6' => 'MNO',
      '7' => 'PQRS',
      '8' => 'TUV',
      '9' => 'WXYZ',
      _ => '',
    };
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _append(digit),
      child: SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: const TextStyle(
                color: _navy,
                fontSize: 21,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 8,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _recentCalls() {
    const calls = [
      (
        name: 'Alex Morgan',
        detail: 'Mobile · 10:42 AM',
        icon: Icons.call_made_rounded,
        color: Color(0xFF27B879),
      ),
      (
        name: 'Support desk',
        detail: 'Work · Yesterday',
        icon: Icons.call_received_rounded,
        color: _blue,
      ),
      (
        name: 'Jamie Chen',
        detail: 'Missed call · Yesterday',
        icon: Icons.call_missed_rounded,
        color: Color(0xFFE45B69),
      ),
    ];
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent calls',
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View all',
                style: TextStyle(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (var i = 0; i < calls.length; i++) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 1,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF0F3F9),
                    child: Text(
                      calls[i].name.substring(0, 1),
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    calls[i].name,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    calls[i].detail,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                  trailing: Icon(
                    calls[i].icon,
                    color: calls[i].color,
                    size: 19,
                  ),
                  onTap: () => setState(() => _number = calls[i].name),
                ),
                if (i < calls.length - 1)
                  const Divider(height: 1, indent: 68, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    const tabs = [
      (label: 'Keypad', icon: Icons.dialpad_rounded),
      (label: 'Recents', icon: Icons.history_rounded),
      (label: 'Contacts', icon: Icons.people_alt_outlined),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _selectedTab = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[i].icon,
                        color: _selectedTab == i ? _blue : _muted,
                        size: 21,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          color: _selectedTab == i ? _blue : _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

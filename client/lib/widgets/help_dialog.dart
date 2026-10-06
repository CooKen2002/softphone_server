import 'package:flutter/material.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hãy liên hệ với chúng tôi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                'CÔNG TY CỔ PHẦN CÔNG NGHỆ TRỰC TUYẾN SKYSOFT\n'
                'SKYSOFT ONLINE TECHNOLOGIES CORPORATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Hotline 1: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    TextSpan(
                      text: '0906.308.308',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Hotline 2: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    TextSpan(
                      text: '0984.308.308',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tổng đài CSKH: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    TextSpan(
                      text: '1900 0085',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  Uri url = Uri.parse('https://skysoft.vn/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Trang chủ: ',
                        style: TextStyle(fontSize: 16),
                      ),
                      TextSpan(
                        text: 'Skysoft.vn',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              'assets/images/skysoft_logo_ok_h80.png',
              width: 180,
              height: 100,
            ),
          ),
        ],
      ),
      actions: [
        // Copy button to copy selected text without dots
        Container(
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: primaryColor,
          ),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

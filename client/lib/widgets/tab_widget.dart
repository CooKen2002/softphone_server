import 'package:flutter/material.dart';

class TabWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  const TabWidget({super.key, required this.icon, required this.title});

  @override
  State<TabWidget> createState() => _TabWidgetState();
}

class _TabWidgetState extends State<TabWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

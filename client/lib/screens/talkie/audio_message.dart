import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';

class AudioMessage extends StatefulWidget {
  final bool starMark;
  final String tag;
  final bool isOwner;
  final DateTime createDate;
  final bool isPlay;
  final String userName;
  final Function() actionPlay;
  final Function() actionReply;
  final Function(bool starMark)? actionStarMark;

  const AudioMessage({
    super.key,
    required this.createDate,
    required this.actionPlay,
    required this.actionReply,
    this.isPlay = false,
    this.starMark = false,
    this.tag = "",
    this.isOwner = false,
    this.userName = "",
    this.actionStarMark,
  });

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  bool starMark = false;

  Color? colorBg(bool isRight, bool isTag, bool isStarred) {
    if (isTag) {
      return Colors.red[300];
    }

    if (isStarred) {
      return Colors.green[300];
    }

    if (!isRight) {
      return Colors.grey[300];
    }

    return secondaryColor;
  }

  Color colorBorder(bool isRight, bool isTag, bool isStarred) {
    if (isTag) {
      return Colors.red;
    }

    if (isStarred) {
      return Colors.green;
    }

    if (!isRight) {
      return Colors.grey;
    }

    return primaryColor;
  }

  @override
  void initState() {
    super.initState();
    starMark = widget.starMark;
  }

  @override
  Widget build(BuildContext context) {
    return widget.isOwner ? leftSideChatWidget() : rightSideChatWidget();
  }

  Widget leftSideChatWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20.0, child: Icon(Icons.person)),
              SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: colorBg(widget.isOwner, widget.tag == "1", starMark),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: colorBorder(
                      widget.isOwner,
                      widget.tag == "1",
                      starMark,
                    ),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(width: 5),
                        IconButton(
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          icon: Icon(
                            widget.isPlay ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () {
                            widget.actionPlay();
                          },
                        ),
                        AudioWave(isPlaying: widget.isPlay),
                        SizedBox(width: 5),
                        IconButton(
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          icon: starMark
                              ? Icon(Icons.star, color: Colors.yellow)
                              : Icon(Icons.star_border),
                          onPressed: () {
                            setState(() {
                              starMark = !starMark;
                            });
                          },
                        ),
                        IconButton(
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          icon: Icon(Icons.reply),
                          onPressed: () {
                            widget.actionReply();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              widget.createDate.formatTime,
              style: TextStyle(fontSize: 12.0, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget rightSideChatWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: colorBg(widget.isOwner, widget.tag == "1", starMark),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: colorBorder(
                      widget.isOwner,
                      widget.tag == "1",
                      starMark,
                    ),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.userName,
                      style: TextStyle(fontSize: 12.0, color: Colors.black),
                    ),
                    Row(
                      children: [
                        IconButton(
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          icon: starMark
                              ? Icon(Icons.star, color: Colors.yellow)
                              : Icon(Icons.star_border),
                          onPressed: () {
                            setState(() {
                              starMark = !starMark;
                              widget.actionStarMark?.call(starMark);
                            });
                          },
                        ),
                        IconButton(
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          icon: Icon(Icons.reply),
                          onPressed: () {
                            widget.actionReply();
                          },
                        ),
                        SizedBox(width: 5),
                        AudioWave(isPlaying: widget.isPlay),
                        SizedBox(width: 5),
                        IconButton(
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          icon: Icon(
                            widget.isPlay ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () {
                            widget.actionPlay();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 5),
              CircleAvatar(radius: 20.0, child: Icon(Icons.person)),
            ],
          ),
          SizedBox(height: 5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              children: [
                Text(
                  widget.createDate.formatDate,
                  style: TextStyle(fontSize: 12.0, color: Colors.black),
                ),
                Spacer(),
                Text(
                  widget.createDate.formatTime,
                  style: TextStyle(fontSize: 12.0, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AudioWave extends StatefulWidget {
  final bool isPlaying;
  const AudioWave({super.key, this.isPlaying = false});

  @override
  State<AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave> {
  late Timer _timer;
  late List<double> _waveHeights;
  @override
  void initState() {
    super.initState();
    _waveHeights = List.generate(10, (index) => _generateRandomHeight());
    _startWaveAnimation();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startWaveAnimation() {
    _timer = Timer.periodic(Duration(milliseconds: 300), (Timer timer) {
      setState(() {
        _waveHeights = List.generate(10, (index) => _generateRandomHeight());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (index) => _buildWaveBar(index)),
      ),
    );
  }

  Widget _buildWaveBar(int index) {
    final double waveHeight = widget.isPlaying ? _waveHeights[index] : 15.0;
    const double waveSpacing = 2.0;

    return Container(
      width: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: waveSpacing),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: waveHeight * (index + 1) / 10,
          decoration: BoxDecoration(
            color: widget.isPlaying ? Colors.red : Colors.black,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2.0),
              topRight: Radius.circular(2.0),
            ),
          ),
        ),
      ),
    );
  }

  double _generateRandomHeight() {
    final random = math.Random();
    return (random.nextDouble() * 20.0) +
        5.0; // Tạo ra giá trị ngẫu nhiên từ 5.0 đến 25.0
  }
}

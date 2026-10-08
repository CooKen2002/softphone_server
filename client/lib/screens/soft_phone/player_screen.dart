import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  final AudioPlayer player;
  final Function onPlayDone;

  const PlayerScreen({
    required this.player,
    required this.onPlayDone,
    super.key,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  // bool get _isPlaying => _playerState == PlayerState.playing;
  //
  // bool get _isPaused => _playerState == PlayerState.paused;

  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';

  AudioPlayer get player => widget.player;

  @override
  void initState() {
    super.initState();

    player.getDuration().then(
      (value) => setState(() {
        _duration = value;
      }),
    );
    player.getCurrentPosition().then(
      (value) => setState(() {
        _position = value;
      }),
    );

    _initStreams();

    // Start the player as soon as the app is displayed. AssetSource('audio/05-08-2024_10-40-19_1635_to_1630.mp3')
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   if (widget.isPlay) {
    //     await player.stop();
    //     String url =
    //         "https://tracking.skysoft.vn/rest/app/getVoiceMessage/66a085925495a0610b83ad26.mp3";
    //     // await player.setSource(UrlSource(url));
    //     await player.play(UrlSource(url));

    //     // await player.resume();
    //   }
    // });
  }

  @override
  void setState(VoidCallback fn) {
    // Subscriptions only can be closed asynchronously,
    // therefore events can occur after widget has been disposed.
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();

    // log("PlayerWigdet: dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     IconButton(
        //       key: const Key('play_button'),
        //       onPressed: _isPlaying ? null : _play,
        //       // iconSize: 48.0,
        //       icon: const Icon(Icons.play_arrow),
        //       color: color,
        //     ),
        //     IconButton(
        //       key: const Key('pause_button'),
        //       onPressed: _isPlaying ? _pause : null,
        //       // iconSize: 48.0,
        //       icon: const Icon(Icons.pause),
        //       color: color,
        //     ),
        //     IconButton(
        //       key: const Key('stop_button'),
        //       onPressed: _isPlaying || _isPaused ? _stop : null,
        //       // iconSize: 48.0,
        //       icon: const Icon(Icons.stop),
        //       color: color,
        //     ),
        //   ],
        // ),
        Text(
          _position != null
              ? '$_positionText / $_durationText'
              : _duration != null
              ? _durationText
              : '',
          style: const TextStyle(fontSize: 12.0),
        ),
        SizedBox(
          height: 20,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
            ),
            child: Slider(
              onChanged: (value) {
                final duration = _duration;
                if (duration == null) {
                  return;
                }
                final position = value * duration.inMilliseconds;
                player.seek(Duration(milliseconds: position.round()));
              },
              value:
                  (_position != null &&
                      _duration != null &&
                      _position!.inMilliseconds > 0 &&
                      _position!.inMilliseconds < _duration!.inMilliseconds)
                  ? _position!.inMilliseconds / _duration!.inMilliseconds
                  : 0.0,
            ),
          ),
        ),
      ],
    );
  }

  void _initStreams() {
    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _position = Duration.zero;
        widget.onPlayDone();
      });
    });
  }
}

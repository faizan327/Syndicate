import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class WavePlayer extends StatefulWidget {
  final String audioUrl;

  const WavePlayer({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _WavePlayerState createState() => _WavePlayerState();
}

class _WavePlayerState extends State<WavePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;  // Default speed is 1x

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Set the audio source
      await _audioPlayer.setUrl(widget.audioUrl);
      _duration = _audioPlayer.duration ?? Duration.zero;

      // Listen to audio position updates
      _audioPlayer.positionStream.listen((pos) {
        setState(() {
          _position = pos;
        });
      });

      // Listen to playback completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
          _audioPlayer.seek(Duration.zero);
        }
      });

      setState(() {});
    } catch (e) {
      print("Error initializing WavePlayer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error initializing audio: $e")),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Play or pause audio
  Future<void> _playPauseAudio() async {
    if (widget.audioUrl == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // Change playback speed
  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _audioPlayer.setSpeed(speed);  // Set the new speed
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_duration == Duration.zero) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                _isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.blue,
                size: 36,
              ),
              onPressed: _playPauseAudio,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  Slider(
                    min: 0.0,
                    max: _duration.inMilliseconds.toDouble(),
                    value: _position.inMilliseconds.toDouble() >
                        _duration.inMilliseconds.toDouble()
                        ? _duration.inMilliseconds.toDouble()
                        : _position.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Speed control buttons
            IconButton(
              icon: Icon(Icons.speed),
              onPressed: () => _changeSpeed(1.0),  // 1x speed
            ),
            IconButton(
              icon: Icon(Icons.fast_forward),
              onPressed: () => _changeSpeed(2.0),  // 2x speed
            ),
            IconButton(
              icon: Icon(Icons.fast_rewind),
              onPressed: () => _changeSpeed(1.5),  // 1.5x speed
            ),
          ],
        ),
      ],
    );
  }
}

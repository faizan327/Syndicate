import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syndicate/widgets/reels_item.dart';
import 'package:video_player/video_player.dart';

class ReelsVideoScreen extends StatefulWidget {
  final Map<String, dynamic> snapshot;

  const ReelsVideoScreen({Key? key, required this.snapshot}) : super(key: key);

  @override
  _ReelsVideoScreenState createState() => _ReelsVideoScreenState();
}

class _ReelsVideoScreenState extends State<ReelsVideoScreen> {
  bool _isFullScreen = false;
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize VideoPlayerController
    try {
      _controller = VideoPlayerController.network(
        widget.snapshot['reelsvideo'],
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )..initialize().then((_) {
        setState(() {
          _controller.setLooping(true);
          _controller.setVolume(1);
          _controller.play();
        });
      }).catchError((e) {
        print("Error initializing video player: $e");
      });
    } catch (e) {
      print("Error initializing video player: $e");
    }
    // Ensure portrait orientation on start
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    // Show status bar initially
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // Force landscape and hide status bar
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Revert to portrait and show status bar
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    }
  }

  @override
  void dispose() {
    // Dispose the controller
    _controller.dispose();
    // Reset orientation and system UI when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String collectionType = 'chapters';

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.black54,
        onPressed: _toggleFullScreen,
        child: Icon(
          _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
          color: Colors.white,
          size: 25,
        ),
      ),
      body: _isFullScreen
          ? ReelsItem(
        widget.snapshot,
        collectionType: collectionType,
        controller: _controller,
      )
          : SafeArea(
        child: ReelsItem(
          widget.snapshot,
          collectionType: collectionType,
          controller: _controller,
        ),
      ),
    );
  }
}
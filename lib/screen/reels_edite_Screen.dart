import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/firebase_service/storage.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:syndicate/generated/l10n.dart';
import '../data/firebase_service/RoleChecker.dart';

class ReelsEditeScreen extends StatefulWidget {
  File videoFile;
  final String? categoryName;
  final String? subcategoryId; // Add this
  final String source;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  ReelsEditeScreen(this.videoFile, {this.categoryName,this.subcategoryId,required this.source,required this.scaffoldMessengerKey, super.key});

  @override
  State<ReelsEditeScreen> createState() => _ReelsEditeScreenState();
}

class _ReelsEditeScreenState extends State<ReelsEditeScreen> {
  final caption = TextEditingController();
  late VideoPlayerController controller;
  bool loading = false;
  bool isPlaying = true;
  bool isMuted = false;
  File? compressedVideo;
  Uint8List? thumbnail;
  double videoPosition = 0.0;
  bool isAdmin = false;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
    //compressVideo();
    checkAdminStatus();
    requestStoragePermissions();
    // checkCodecs();
  }

  // Future<void> checkCodecs() async {
  //   final session = await FFmpegKit.execute('-codecs');
  //   final logs = await session.getAllLogsAsString();
  //   print("Available codecs:\n$logs");
  // }

  Future<void> requestStoragePermissions() async {
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission denied");
    }
  }

  Future<void> initializeVideoPlayer() async {
    controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
        controller.setLooping(false);
        controller.setVolume(1.0);
        controller.play();
        controller.addListener(() {
          final currentPosition = controller.value.position.inMilliseconds.toDouble();
          setState(() {
            videoPosition = currentPosition;
          });
        });
      });
  }

  Future<void> compressVideo() async {
    setState(() => loading = true);
    try {
      final info = await VideoCompress.compressVideo(
        widget.videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      if (info != null) {
        compressedVideo = File(info.path!);
        final thumb = await VideoCompress.getFileThumbnail(
          info.path!,
          quality: 75,
          position: -1,
        );
        if (thumb != null) {
          thumbnail = thumb.readAsBytesSync();
        }
      }
    } catch (e) {
      print("Error compressing video: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> checkAdminStatus() async {
    String userRole = await RoleChecker.checkUserRole();
    setState(() {
      isAdmin = userRole == 'admin';
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }




  Future<void> _handleShare() async {
    setState(() => loading = true);
    String videoId = Uuid().v4();

    // Cache the original video file
    Directory tempDir = await getTemporaryDirectory();
    String cachedVideoPath = '${tempDir.path}/$videoId-original.mp4';
    File cachedVideo = await widget.videoFile.copy(cachedVideoPath);

    // Create initial processing document
    if (widget.source == 'VideoListPage') {
      await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).set({
        'videoId': videoId,
        'status': 'uploading',
        'progress': 0,
        'categoryName': widget.categoryName ?? 'Default',
        'subcategoryId': widget.subcategoryId ?? '',
        'videoPath': cachedVideoPath,
        'totalBytes': cachedVideo.lengthSync(),
        'bytesTransferred': 0,
        'startTime': DateTime.now().millisecondsSinceEpoch,
        'chunkCount': 0,
        'uploadedChunks': 0,
      });
    }

    // Show uploading SnackBar
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(width: 24.w, height: 24.h, child: CircularProgressIndicator()),
            SizedBox(width: 12.w),
            Expanded(child: Text('Uploading Reel', style: TextStyle(color: Colors.white, fontSize: 16.sp))),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate back immediately
    Navigator.pop(context);

    // Split and upload in background
    _uploadInBackground(videoId, cachedVideoPath);
  }



  Future<void> _uploadInBackground(String videoId, String videoPath) async {
    try {
      // Simulate compression progress (commented out since compression is removed)
      /*
    if (widget.source == 'VideoListPage') {
      Timer.periodic(Duration(milliseconds: 500), (timer) async {
        // Check if compression is still ongoing
        if (File(videoPath).existsSync()) {
          double simulatedProgress = (timer.tick * 2).toDouble(); // Increment by 2% every 500ms
          if (simulatedProgress >= 25) {
            simulatedProgress = 25; // Cap at 25% until compression finishes
            timer.cancel(); // Stop timer when compression is assumed complete
          }
          await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({
            'progress': simulatedProgress,
            'lastUpdateTime': DateTime.now().millisecondsSinceEpoch,
          });
        } else {
          timer.cancel();
        }
      });
    }
    */

      // Compress video (commented out)
      /*
    final info = await VideoCompress.compressVideo(
      videoPath,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );
    if (info == null) throw Exception("Compression failed");
    File compressedVideo = File(info.path!);
    */
      File videoFile = File(videoPath); // Use the original video file directly

      // Update status to uploading (adjusted since no compression phase)
      if (widget.source == 'VideoListPage') {
        await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({
          'status': 'uploading',
          'progress': 0, // Start at 0% since no compression
          'totalBytes': videoFile.lengthSync(), // Use original file size
        });
      }

      // Generate thumbnail (using original videoPath instead of compressed path)
      File? thumbnailFile = await VideoCompress.getFileThumbnail(videoPath, quality: 75, position: -1);
      if (thumbnailFile == null) throw Exception("Thumbnail generation failed");
      Uint8List thumbnail = await thumbnailFile.readAsBytes();

      // Upload video (using original videoFile)
      Reference videoRef = FirebaseStorage.instance.ref().child('Reels/$videoId.mp4');
      UploadTask uploadTask = videoRef.putFile(videoFile);

      if (widget.source == 'VideoListPage') {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({
            'progress': progress.clamp(0, 100), // Full range since no compression
            'bytesTransferred': snapshot.bytesTransferred,
            'lastUpdateTime': DateTime.now().millisecondsSinceEpoch,
          });
        }, onError: (e) {
          FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({
            'status': 'failed',
            'error': e.toString(),
          });
        });
      }

      String videoUrl = await uploadTask.then((snapshot) => snapshot.ref.getDownloadURL());

      Directory tempDir = await getTemporaryDirectory();
      File tempThumbnailFile = File('${tempDir.path}/thumbnail.png');
      await tempThumbnailFile.writeAsBytes(thumbnail);
      String thumbnailUrl = await StorageMethod().uploadImageToStorage('Reels/Thumbnails', tempThumbnailFile);

      // Update progress (adjusted since no compression phase)
      if (widget.source == 'VideoListPage') {
        await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({'progress': 100});
      }

      String collectionName = widget.source == 'VideoListPage' ? 'chapters' : (isAdmin ? 'AdminReels' : 'reels');
      String categoryName = widget.categoryName ?? 'Default';

      bool result = await Firebase_Firestor().CreatReels(
        video: videoUrl,
        caption: caption.text,
        thumbnail: thumbnailUrl,
        collectionName: collectionName,
        categoryName: categoryName,
        subcategoryId: widget.subcategoryId,
      );

      if (result && widget.source == 'VideoListPage') {
        await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({'progress': 100});
        await Future.delayed(Duration(milliseconds: 500));
        await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).delete();
        if (File(videoPath).existsSync()) await File(videoPath).delete();
      }
    } catch (e) {
      print("Background Upload Error: $e");
      if (widget.source == 'VideoListPage') {
        await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({
          'status': 'failed',
          'error': e.toString(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          centerTitle: false,
          title: Text(S.of(context).newReels, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          actions: [
            GestureDetector(
              onTap: _handleShare,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  alignment: Alignment.center,
                  height: 30.h,
                  width: 100.w,
                  decoration: BoxDecoration(
                    color: Color(0xffe0993d),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Text(
                    S.of(context).share,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 600.h,
                          color: Colors.black,
                          child: controller.value.isInitialized
                              ? AspectRatio(
                            aspectRatio: controller.value.aspectRatio != 0
                                ? controller.value.aspectRatio
                                : 16 / 9,
                            child: VideoPlayer(controller),
                          )
                              : const CircularProgressIndicator(),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isPlaying ? controller.pause() : controller.play();
                                      isPlaying = !isPlaying;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    isMuted ? Icons.volume_off : Icons.volume_up,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isMuted = !isMuted;
                                      controller.setVolume(isMuted ? 0.0 : 1.0);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20.h,
                          left: 0,
                          right: 0,
                          child: VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: Color(0xffa96d1f),
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: TextField(
                          controller: caption,
                          decoration: InputDecoration(
                            hintText: S.of(context).writeACaption,
                            hintStyle: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 16.sp,
                            ),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (loading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xffe0993d)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/firebase_service/storage.dart';
import 'package:syndicate/generated/l10n.dart';
import '../data/firebase_service/RoleChecker.dart';
import 'Story/story_edit_screen.dart';

class StoryPreviewScreen extends StatefulWidget {
  /// If taking a photo via camera, pass that [File] here
  final File? cameraFile;

  /// A list of gallery assets. If you only have one item, pass a single-element list.
  final List<AssetEntity>? assets;

  /// True for images, false for videos (applies to all assets if multi)
  final bool isImage;
  final bool isEdited; // New flag

  const StoryPreviewScreen({
    Key? key,
    this.cameraFile,
    this.assets,
    required this.isImage,
    this.isEdited = false, // Default to false
  }) : super(key: key);

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  bool _isUploading = false;

  /// We keep a list of video controllers if we have multiple items and they are videos
  final List<VideoPlayerController?> _videoControllers = [];

  /// Which page is currently visible in the PageView (if multiple)
  int _currentPageIndex = 0;

  /// True if the user passed only one item (or a cameraFile)
  bool get _isSingleItem {
    if (widget.cameraFile != null) return true;
    // If the assets list has exactly 1 item, that's single
    return (widget.assets?.length ?? 0) == 1;
  }

  Future<void> _initCameraVideoController() async {
    if (!widget.isImage && widget.cameraFile != null) {
      final controller = VideoPlayerController.file(widget.cameraFile!);
      await controller.initialize();
      controller.setLooping(true);
      await controller.play();
      _videoControllers.add(controller);
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();if (widget.isImage && !widget.isEdited) { // Only redirect if not edited
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("StoryPreviewScreen: Redirecting to StoryEditScreen (not edited)");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoryEditScreen(
              cameraFile: widget.cameraFile,
              asset: widget.assets?.first,
            ),
          ),
        );
      });
    } else if (!widget.isImage) {
      if (widget.cameraFile != null) {
        _initCameraVideoController();
      } else if (widget.assets?.length == 1) {
        final asset = widget.assets!.first;
        if (!widget.isImage) _initSingleVideoController(asset);
      } else if (widget.assets != null && !widget.isImage) {
        _initMultipleVideoControllers();
      }
    }

  }

  // ---------------------------
  //   VIDEO CONTROLLER SETUP
  // ---------------------------

  /// Single video from gallery
  Future<void> _initSingleVideoController(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    controller.setLooping(true);
    await controller.play();
    _videoControllers.add(controller);
    setState(() {});
  }

  /// Multiple videos from gallery
  Future<void> _initMultipleVideoControllers() async {
    if (widget.assets == null) return;
    for (final asset in widget.assets!) {
      final file = await asset.file;
      if (file == null) {
        _videoControllers.add(null);
        continue;
      }
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(true);
      _videoControllers.add(controller);
    }

    // Start playing the first video automatically
    if (_videoControllers.isNotEmpty && _videoControllers[0] != null) {
      _videoControllers[0]!.play();
    }
    setState(() {});
  }

  /// When user swipes in PageView, we stop previous video and play the new one
  void _onPageChanged(int index) {
    if (!widget.isImage) {
      // Pause old video
      final old = _videoControllers[_currentPageIndex];
      old?.pause();

      // Play new video if it exists
      final newController = _videoControllers[index];
      newController?.play();
    }
    setState(() => _currentPageIndex = index);
  }

  @override
  void dispose() {
    for (final vc in _videoControllers) {
      vc?.dispose();
    }
    super.dispose();
  }

  // ---------------------------
  //   UPLOAD LOGIC
  // ---------------------------

  /// Upload all items if multiple, or just one if single
  Future<void> _onUploadPressed() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).noUserLoggedIn)),
      );
      return;
    }

    try {
      // 1) If there's a camera file, only upload that
      if (widget.cameraFile != null) {
        await _uploadFileToFirebase(widget.cameraFile!, userId, widget.isImage);
      }
      // 2) If there's an asset list
      else if (widget.assets != null && widget.assets!.isNotEmpty) {
        // If single item:
        if (_isSingleItem) {
          final singleAsset = widget.assets!.first;
          final file = await singleAsset.file;
          if (file != null) {
            await _uploadFileToFirebase(file, userId, widget.isImage);
          }
        }
        // If multiple items:
        else {
          for (final asset in widget.assets!) {
            final file = await asset.file;
            if (file != null) {
              await _uploadFileToFirebase(file, userId, widget.isImage);
            }
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSingleItem
              ? S.of(context).storyUploadedSuccessfully
              : S.of(context).allStoriesUploadedSuccessfully),
        ),
      );
      Navigator.pop(context);
      Navigator.pop(context); // go back to the main story screen
    } catch (e) {
      debugPrint('Error uploading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorUploadingStory)),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Helper to upload a single file
  Future<void> _uploadFileToFirebase(File file, String userId, bool isImage) async {
    final mediaType = isImage ? 'image' : 'video';
    final videoController = VideoPlayerController.file(file);
    await videoController.initialize();
    print('Video dimensions: ${videoController.value.size.width}x${videoController.value.size.height}');
    videoController.dispose();

    final mediaUrl = await StorageMethod().uploadStoryMedia(
      userId: userId,
      file: file,
      mediaType: mediaType,
    );
    String userRole = await RoleChecker.checkUserRole();
    String collectionName = (userRole == 'admin') ? 'AdminStories' : 'stories';

    // 2) Add Firestore doc
    await Firebase_Firestor().addStory(mediaUrl: mediaUrl, mediaType: mediaType, collectionName: collectionName,);
  }

  // ---------------------------
  //   BUILD PREVIEW
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get screen dimensions for dynamic thumbnail sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSingleItem
              ? 'Preview'
              : 'Preview (${widget.assets?.length ?? 1})',
          style: TextStyle(fontSize: 18.sp), // Scale font size
        ),
      ),
      body: Stack(
        children: [
          if (widget.cameraFile != null)
          // If camera file is present, show a single image
            Center(child: _buildCameraPreview())
          else if (widget.assets != null && widget.assets!.isNotEmpty)
            _isSingleItem
                ? _buildSingleAssetPreview(widget.assets!.first, screenWidth, screenHeight)
                : _buildMultiAssetsPreview(widget.assets!, screenWidth, screenHeight)
          else
            Center(
              child: Text(
                S.of(context).noMediaToPreview,
                style: TextStyle(fontSize: 16.sp), // Scale font size
              ),
            ),

          if (_isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4.w, // Scale stroke width
                ),
              ),
            ),
        ],
      ),
      // Bottom bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: SizedBox(
            height: 50.h, // Scale button height
            child: ElevatedButton(
              onPressed: _onUploadPressed,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r), // Scale radius
                ),
              ),
              child: Text(
                _isUploading
                    ? S.of(context).uploading
                    : (_isSingleItem ? S.of(context).uploadStory : S.of(context).uploadAll),
                style: TextStyle(fontSize: 16.sp), // Scale font size
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Camera file is always a single image
  Widget _buildCameraPreview() {
    if (widget.isImage) {
      return Image.file(
        widget.cameraFile!,
        fit: BoxFit.contain, // Maintain aspect ratio
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // Handle video preview
      final controller = VideoPlayerController.file(widget.cameraFile!);
      return FutureBuilder(
        future: controller.initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            controller.setLooping(true);
            controller.play();
            return Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'couldNotLoadVideo',
                style: TextStyle(fontSize: 16.sp), // Scale font size
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 4.w, // Scale stroke width
              ),
            );
          }
        },
      );
    }
  }

  /// Single asset from the gallery (could be image or video)
  Widget _buildSingleAssetPreview(AssetEntity asset, double screenWidth, double screenHeight) {
    if (widget.isImage) {
      // Single image
      return FutureBuilder<Uint8List?>(
        future: asset.thumbnailDataWithSize(
          ThumbnailSize(screenWidth.toInt(), screenHeight.toInt()), // Dynamic size based on screen
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 4.w, // Scale stroke width
              ),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(
                S.of(context).couldNotLoadImage,
                style: TextStyle(fontSize: 16.sp), // Scale font size
              ),
            );
          }
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          );
        },
      );
    } else {
      // Single video
      if (_videoControllers.isEmpty || _videoControllers.first == null) {
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 4.w, // Scale stroke width
          ),
        );
      }
      final controller = _videoControllers.first!;
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }
  }

  /// Multiple assets: use PageView to swipe through them
  Widget _buildMultiAssetsPreview(List<AssetEntity> assets, double screenWidth, double screenHeight) {
    return PageView.builder(
      itemCount: assets.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final asset = assets[index];
        if (widget.isImage) {
          // Multiple images
          return FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(
              ThumbnailSize(screenWidth.toInt(), screenHeight.toInt()), // Dynamic size based on screen
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 4.w, // Scale stroke width
                  ),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Text(
                    S.of(context).couldNotLoadImage,
                    style: TextStyle(fontSize: 16.sp), // Scale font size
                  ),
                );
              }
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              );
            },
          );
        } else {
          // Multiple videos
          final controller = _videoControllers[index];
          if (controller == null || !controller.value.isInitialized) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 4.w, // Scale stroke width
              ),
            );
          }
          return Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          );
        }
      },
    );
  }
}
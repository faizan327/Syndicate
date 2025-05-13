import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/model/story_model.dart';
import 'package:syndicate/data/model/usermodel.dart';
import 'package:syndicate/screen/profile_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syndicate/generated/l10n.dart';
import 'dart:async';

class StoryViewScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> activeUsers;

  const StoryViewScreen({
    Key? key,
    required this.userId,
    required this.activeUsers,
  }) : super(key: key);

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  final Firebase_Firestor _firestoreService = Firebase_Firestor();
  List<StoryModel> _stories = [];
  int _currentIndex = 0;
  int _currentUserIndex = 0;
  VideoPlayerController? _videoController;
  Usermodel? _userModel;
  late AnimationController _progressController;
  bool _isPaused = false;
  final TextEditingController _replyController = TextEditingController();
  FocusNode _replyFocusNode = FocusNode();
  double? _tapPosition;
  Timer? _tapTimer;
  bool _isLongPressing = false;
  bool isCurrentUserStory = false;
  bool isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 17),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isPaused) {
        _nextStory();
      }
    });

    _replyController.addListener(() {
      if (_replyController.text.isNotEmpty) {
        _pauseProgressBar();
      }
    });

    _replyFocusNode.addListener(_focusListener);

    _currentUserIndex = widget.activeUsers.indexWhere((user) => user['userId'] == widget.userId);
    _fetchUserStories();
    _fetchUserData();
    _checkUserStatus();
  }

  void _checkUserStatus() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    print("Checking user status for $currentUserId");
    setState(() {
      isCurrentUserStory = (widget.userId == currentUserId);
      print("isCurrentUserStory: $isCurrentUserStory");
    });

    Usermodel currentUser = await _firestoreService.getUser(UID: currentUserId);
    setState(() {
      isAdmin = (currentUser.role == 'admin');
      _isLoading = false;
      print("isAdmin: $isAdmin, role: ${currentUser.role}");
    });
  }

  void _focusListener() {
    if (_replyFocusNode.hasFocus) {
      _pauseProgressBar();
    } else if (_replyController.text.isEmpty) {
      _resumeProgressBar();
    }
  }

  void _fetchUserStories() {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    Stream<List<StoryModel>> storiesStream1 = _firestoreService.getUserStories(widget.userId, 'stories');
    Stream<List<StoryModel>> storiesStream2 = _firestoreService.getUserStories(widget.userId, 'AdminStories');

    Stream<List<StoryModel>> combinedStoriesStream = Rx.combineLatest2(
      storiesStream1,
      storiesStream2,
          (List<StoryModel> stories1, List<StoryModel> stories2) {
        List<StoryModel> combined = [...stories1, ...stories2];
        combined.sort((a, b) {
          bool aViewed = a.viewedBy.contains(currentUserId);
          bool bViewed = b.viewedBy.contains(currentUserId);
          if (!aViewed && bViewed) return -1;
          if (aViewed && !bViewed) return 1;
          int timeCompare = b.uploadTime.compareTo(a.uploadTime);
          if (timeCompare != 0) return timeCompare;
          return a.storyId.compareTo(b.storyId);
        });
        return combined;
      },
    );

    combinedStoriesStream.listen((stories) {
      setState(() {
        _stories = stories;
        _currentIndex = 0;
      });
      if (_stories.isNotEmpty) {
        _initializeMedia(_stories[0]);
      }
    });
  }

  void _fetchUserData() async {
    try {
      Usermodel user = await _firestoreService.getUser(UID: widget.userId);
      setState(() {
        _userModel = user;
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _resumeProgressBar() {
    if (_isPaused) {
      _progressController.forward(from: _progressController.value);
      if (_videoController != null && _videoController!.value.isInitialized) {
        _videoController!.play();
      }
      setState(() {
        _isPaused = false;
      });
    }
  }

  void _deleteStory(String storyId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          elevation: 5,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.orangeAccent,
                  size: 50.w,
                ),
                SizedBox(height: 15.h),
                Text(
                  S.of(context).confirmDeletion,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  S.of(context).deletePostConfirmation,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        foregroundColor: Colors.grey[700],
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text(
                        "No",
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text(
                        "Yes",
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        String collectionName;
        List<StoryModel> storiesFromStories =
        await _firestoreService.getUserStories(widget.userId, 'stories').first;
        if (storiesFromStories.any((s) => s.storyId == storyId)) {
          collectionName = 'stories';
        } else {
          collectionName = 'AdminStories';
        }
        _pauseProgressBar();
        await _firestoreService.deleteStory(storyId: storyId, collectionName: collectionName);
        setState(() {
          _stories.removeWhere((story) => story.storyId == storyId);
          if (_currentIndex >= _stories.length && _stories.isNotEmpty) {
            _currentIndex = _stories.length - 1;
          }
        });
        if (_stories.isNotEmpty) {
          _initializeMedia(_stories[_currentIndex]);
        } else {
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error deleting story: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete story: $e")),
        );
      }
    }
  }

  void _pauseProgressBar() {
    if (!_isPaused) {
      _progressController.stop();
      if (_videoController != null && _videoController!.value.isInitialized) {
        _videoController!.pause();
      }
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _initializeMedia(StoryModel story) {
    if (story.mediaType == 'video') {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(story.mediaUrl)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _progressController.duration = _videoController!.value.duration;
          if (!_isPaused) {
            _progressController.forward(from: 0);
          }
        }).catchError((error) {
          print("Video initialization error: $error");
        });
    } else {
      _videoController?.dispose();
      _videoController = null;
      _progressController.duration = const Duration(seconds: 5);
      if (!_isPaused) {
        _progressController.forward(from: 0);
      }
    }
    _markStoryAsViewed(story);
  }

  void _markStoryAsViewed(StoryModel story) async {
    try {
      String collectionName;
      List<StoryModel> storiesFromStories =
      await _firestoreService.getUserStories(widget.userId, 'stories').first;
      if (storiesFromStories.any((s) => s.storyId == story.storyId)) {
        collectionName = 'stories';
      } else {
        collectionName = 'AdminStories';
      }
      await _firestoreService.markStoryAsViewed(story.storyId, collectionName);
    } catch (e) {
      print("Error marking story as viewed: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _progressController.dispose();
    _replyFocusNode.removeListener(_focusListener);
    _replyFocusNode.dispose();
    _replyController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }

  void _submitReply() async {
    String replyText = _replyController.text.trim();
    if (replyText.isNotEmpty) {
      StoryModel currentStory = _stories[_currentIndex];
      await Firebase_Firestor().saveStoryReply(
        storyId: currentStory.storyId,
        replyText: replyText,
      );
      String chatId = await Firebase_Firestor().getOrCreateChat(
        userId: currentStory.userId,
      );
      await _firestoreService.sendChatMessage(
        chatId: chatId,
        message: replyText,
        storyReference: currentStory.storyId,
        mediaUrl: currentStory.mediaUrl,
      );
      _replyController.clear();
      _resumeProgressBar();
    }
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _initializeMedia(_stories[_currentIndex]);
    } else {
      _nextUser();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _initializeMedia(_stories[_currentIndex]);
    } else {
      _previousUser();
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.activeUsers.length - 1) {
      String nextUserId = widget.activeUsers[_currentUserIndex + 1]['userId'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewScreen(
            userId: nextUserId,
            activeUsers: widget.activeUsers,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousUser() {
    if (_currentUserIndex > 0) {
      String prevUserId = widget.activeUsers[_currentUserIndex - 1]['userId'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewScreen(
            userId: prevUserId,
            activeUsers: widget.activeUsers,
          ),
        ),
      );
    }
  }

  void _showViewersBottomSheet() {
    _pauseProgressBar();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        StoryModel currentStory = _stories[_currentIndex];
        return Container(
          height: 300.h, // Scale height
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  S.of(context).viewersOfThisStory,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: currentStory.viewedBy.isEmpty
                    ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20.w,
                          backgroundColor: Colors.grey,
                        ),
                        title: Container(
                          color: Colors.grey,
                          height: 10.h,
                          width: 100.w,
                        ),
                      );
                    },
                  ),
                )
                    : ListView.builder(
                  itemCount: currentStory.viewedBy.length,
                  itemBuilder: (context, index) {
                    String viewerId = currentStory.viewedBy[index];
                    return FutureBuilder<Usermodel>(
                      future: _firestoreService.getUser(UID: viewerId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 20.w,
                                backgroundColor: Colors.grey,
                              ),
                              title: Container(
                                color: Colors.grey,
                                height: 10.h,
                                width: 100.w,
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        Usermodel viewer = snapshot.data!;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(Uid: viewerId),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 20.w,
                              backgroundImage: NetworkImage(viewer.profile),
                            ),
                            title: Text(
                              viewer.username,
                              style: TextStyle(fontSize: 16.sp),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _resumeProgressBar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print("Building UI - isCurrentUserStory: $isCurrentUserStory, isAdmin: $isAdmin");
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 4.w, // Scale stroke width
          ),
        ),
      );
    }
    if (_stories.isEmpty && _userModel == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 4.w, // Scale stroke width
          ),
        ),
      );
    }
    if (_stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            '',
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
          ),
        ),
      );
    }

    StoryModel currentStory = _stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) {
          setState(() {
            _isLongPressing = true;
          });
          _tapTimer?.cancel();
          _pauseProgressBar();
        },
        onLongPressEnd: (_) {
          setState(() {
            _isLongPressing = false;
          });
          _resumeProgressBar();
        },
        onTapDown: (TapDownDetails details) {
          _tapPosition = details.globalPosition.dx;
          _tapTimer?.cancel();
          _tapTimer = Timer(const Duration(milliseconds: 500), () {
            if (!_isLongPressing && _tapPosition != null) {
              final screenWidth = MediaQuery.of(context).size.width;
              if (_tapPosition! < screenWidth / 2) {
                _previousStory();
              } else {
                _nextStory();
              }
              _tapPosition = null;
            }
          });
        },
        onTapUp: (_) {},
        onTapCancel: () {
          _tapTimer?.cancel();
          _tapPosition = null;
        },
        onHorizontalDragUpdate: (details) {
          if (details.primaryDelta! > 5) {
            _previousUser();
          } else if (details.primaryDelta! < -5) {
            _nextUser();
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: currentStory.mediaType == 'image'
                  ? Image.network(
                currentStory.mediaUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              )
                  : _videoController != null && _videoController!.value.isInitialized
                  ? Center(
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain, // Maintain aspect ratio
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
              )
                  : Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4.w, // Scale stroke width
                ),
              ),
            ),
            Positioned(
              top: 30.h,
              left: 0,
              right: 0,
              child: Row(
                children: List.generate(
                  _stories.length,
                      (index) {
                    return Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2.r),
                          child: ValueListenableBuilder<double>(
                            valueListenable: _progressController,
                            builder: (context, value, child) {
                              double progressValue;
                              if (index < _currentIndex) {
                                progressValue = 1.0;
                              } else if (index == _currentIndex) {
                                progressValue = value;
                              } else {
                                progressValue = 0.0;
                              }
                              return LinearProgressIndicator(
                                value: progressValue,
                                minHeight: 2.h,
                                color: Colors.white,
                                backgroundColor: Colors.grey.withOpacity(0.5),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 50.h,
              left: 16.w,
              right: 16.w,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(Uid: widget.userId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20.w,
                      backgroundImage: NetworkImage(_userModel?.profile ?? ''),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      _userModel?.username ?? 'User',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    ),
                    const Spacer(),
                    if (currentStory.userId == FirebaseAuth.instance.currentUser?.uid)
                      GestureDetector(
                        onTap: _showViewersBottomSheet,
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_red_eye,
                              color: Colors.white,
                              size: 20.w,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${currentStory.viewedBy.length}',
                              style: TextStyle(color: Colors.white, fontSize: 16.sp),
                            ),
                          ],
                        ),
                      ),
                    if (isCurrentUserStory || isAdmin)
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.deepOrangeAccent,
                          size: 20.w,
                        ),
                        onPressed: () => _deleteStory(currentStory.storyId),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 50.h,
              left: 16.w,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onBackground,
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: Offset(0, 2.h),
                      blurRadius: 5.r,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _replyController,
                      focusNode: _replyFocusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) => _submitReply(),
                      decoration: InputDecoration(
                        hintText: 'Type your reply...',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 16.sp,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                      ),
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16.sp,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: theme.primaryColor,
                          size: 24.w,
                        ),
                        onPressed: _submitReply,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
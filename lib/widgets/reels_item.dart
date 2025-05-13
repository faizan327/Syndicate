import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/util/image_cached.dart';
import 'package:syndicate/widgets/comment.dart';
import 'package:syndicate/widgets/like_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/widgets/verified_badge.dart';
import 'package:video_player/video_player.dart';
import 'package:syndicate/screen/profile_screen.dart';
import '../data/model/usermodel.dart';
import '../screen/share_reel_bottom_sheet.dart';
import 'package:syndicate/generated/l10n.dart';

class ReelsItem extends StatefulWidget {
  final Map<String, dynamic> snapshot;
  final String collectionType;
  final VideoPlayerController? controller;

  const ReelsItem(
      this.snapshot, {
        required this.collectionType,
        this.controller,
        super.key,
      });

  @override
  State<ReelsItem> createState() => _ReelsItemState();
}

class _ReelsItemState extends State<ReelsItem> {
  late VideoPlayerController _controller;
  bool _isControllerInternal = false;
  bool play = true;
  bool isAnimating = false;
  String user = '';
  bool isFollowing = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userRole;
  bool isCaptionExpanded = false;
  final int maxCaptionLength = 50;
  double currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    user = _auth.currentUser!.uid;
    _checkFollowingStatus();

    if (widget.controller != null) {
      // Use provided controller
      _controller = widget.controller!;
    } else {
      // Create internal controller
      _isControllerInternal = true;
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
    }
  }

  Future<void> fetchUserRole() async {
    try {
      Usermodel postOwner =
      await Firebase_Firestor().getUser(UID: widget.snapshot['uid']);
      setState(() {
        userRole = postOwner.role;
      });
    } catch (e) {
      print("Error fetching user role: $e");
      setState(() {
        userRole = 'user';
      });
    }
  }

  Future<void> _checkFollowingStatus() async {
    bool followingStatus =
    await Firebase_Firestor().isFollowing(uid: widget.snapshot['uid']);
    setState(() {
      isFollowing = followingStatus;
    });
  }

  void _toggleFollow() async {
    await Firebase_Firestor().follow(uid: widget.snapshot['uid']);
    _checkFollowingStatus();
  }

  Future<bool> isAdmin() async {
    try {
      var user = await Firebase_Firestor().getUser();
      return user.role == 'admin';
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteReel() async {
    try {
      String collectionType = widget.snapshot['collectionType'] ?? 'reels';
      String? categoryName = widget.snapshot['categoryName'];
      String? subcategoryId = widget.snapshot['subcategoryId'];
      await Firebase_Firestor().deleteReel(
        postId: widget.snapshot['postId'],
        collectionType: collectionType,
        categoryName: categoryName,
        subcategoryId: subcategoryId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel deleted successfully')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error deleting reel')));
    }
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          elevation: 8,
          backgroundColor: theme.colorScheme.onBackground,
          child: Container(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration:
                  BoxDecoration(shape: BoxShape.circle, color: Colors.red[100]),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 32.sp, color: Colors.red[800]),
                ),
                SizedBox(height: 16.h),
                Text("Confirm ${S.of(context).delete}",
                    style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color)),
                SizedBox(height: 12.h),
                Text(S.of(context).deletePostConfirmation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16.sp,
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5)),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[800],
                        padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Cancel",
                          style:
                          TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        foregroundColor: Colors.white,
                        padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        deleteReel();
                      },
                      child: Text("Delete",
                          style:
                          TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool isPostOwner() {
    return _auth.currentUser!.uid == widget.snapshot['uid'];
  }

  void showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedReason = 'Spam';
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          backgroundColor: theme.dialogBackgroundColor,
          title: Row(
            children: [
              Icon(Icons.report, color: Colors.red[700], size: 24.sp),
              SizedBox(width: 8.w),
              Text("Report Reel",
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.headlineSmall?.color)),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Please select a reason for reporting:",
                        style: TextStyle(
                            fontSize: 14.sp, color: theme.textTheme.bodyMedium?.color)),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor, width: 1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedReason,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                          items: <String, IconData>{
                            S.of(context).spam: Icons.report_gmailerrorred,
                            S.of(context).sexualContent: Icons.no_adult_content,
                            S.of(context).violence: Icons.warning_amber,
                            S.of(context).harassment: Icons.person_off,
                            S.of(context).other: Icons.help_outline,
                          }.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Row(
                                children: [
                                  Icon(entry.value,
                                      size: 20.sp, color: theme.iconTheme.color),
                                  SizedBox(width: 12.w),
                                  Text(entry.key,
                                      style: TextStyle(
                                          fontSize: 16.sp,
                                          color: theme.textTheme.bodyLarge?.color)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedReason = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.textTheme.bodyMedium?.color,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              onPressed: () {
                Firebase_Firestor().reportPost(
                  postId: widget.snapshot['postId'],
                  reason: selectedReason,
                  reporterId: _auth.currentUser!.uid,
                  collectionType: widget.collectionType,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Reel reported successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              child: Text(S.of(context).report),
            ),
          ],
        );
      },
    );
  }

  void _showPlaybackSpeedBottomSheet() {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Responsive sizing based on orientation
    double containerPadding = isLandscape ? 5.sp : 16.sp;
    double titleFontSize = isLandscape ? 8.sp : 18.sp;
    double handleWidth = isLandscape ? 30.w : 40.w;
    double handleHeight = isLandscape ? 3.h : 4.h;
    double handleMarginBottom = isLandscape ? 6.h : 8.h;
    double separatorHeight = isLandscape ? 10.h : 13.h;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isLandscape ? 15.r : 20.r)),
          ),
          padding: EdgeInsets.all(containerPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: handleWidth,
                height: handleHeight,
                margin: EdgeInsets.only(bottom: handleMarginBottom),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Text(
                'Playback Speed',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: separatorHeight),
              isLandscape
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSpeedOption(1.0, isLandscape),
                  _buildSpeedOption(1.25, isLandscape),
                  _buildSpeedOption(1.5, isLandscape),
                  _buildSpeedOption(2.0, isLandscape),
                ],
              )
                  : Column(
                children: [
                  _buildSpeedOption(1.0, isLandscape),
                  _buildSpeedOption(1.25, isLandscape),
                  _buildSpeedOption(1.5, isLandscape),
                  _buildSpeedOption(2.0, isLandscape),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedOption(double speed, bool isLandscape) {
    bool isSelected = currentSpeed == speed;

    // Responsive sizing for speed option
    double optionFontSize = isLandscape ? 8.sp : 16.sp;
    double verticalPadding = isLandscape ? 8.h : 8.h;
    double containerVerticalPadding = isLandscape ? 8.h : 12.h;
    double containerHorizontalPadding = isLandscape ? 10.w : 16.w;
    double borderRadius = isLandscape ? 6.r : 8.r;
    double buttonWidth = isLandscape ? 40.w : double.infinity; // Fixed width in landscape

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: isLandscape ? 4.w : 0,
      ),
      child: GestureDetector(
        onTap: () {
          if (_controller.value.isInitialized) {
            setState(() {
              currentSpeed = speed;
              _controller.setPlaybackSpeed(speed);
            });
            Navigator.pop(context);
          }
        },
        child: Container(
          width: buttonWidth,
          padding: EdgeInsets.symmetric(
            vertical: containerVerticalPadding,
            horizontal: containerHorizontalPadding,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Text(
            '${speed}x',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: optionFontSize,
              color: isSelected
                  ? Colors.orangeAccent
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    if (_isControllerInternal) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> likes = widget.snapshot['like'] ?? [];
    bool isLiked = likes.contains(user);
    String caption = widget.snapshot['caption'] ?? '';
    bool isCaptionLong = caption.length > maxCaptionLength;
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Responsive sizing based on orientation
    double profileSize = isLandscape ? 16.w : 35.w;
    double usernameFontSize = isLandscape ? 8.sp : 13.sp;
    double captionFontSize = isLandscape ? 7.sp : 13.sp;
    double followButtonWidth = isLandscape ? 50.w : 100.w;
    double followButtonHeight = isLandscape ? 30.h : 25.h;
    double followButtonFontSize = isLandscape ? 6.sp : 13.sp;
    double verifiedBadgeSize = isLandscape ? 9.sp : 14.sp;
    double captionWidth = isLandscape
        ? MediaQuery.of(context).size.width - 100.w
        : MediaQuery.of(context).size.width - 150.w;
    double bottomPadding = isLandscape ? 20.h : 40.h;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onDoubleTap: () {
            Firebase_Firestor().like(
              like: widget.snapshot['like'] ?? [],
              type: widget.collectionType,
              uid: user,
              postId: widget.snapshot['postId'],
            );
            setState(() {
              isAnimating = true;
              if (!isLiked) {
                likes.add(user);
              } else {
                likes.remove(user);
              }
            });
          },
          onTap: () {
            setState(() {
              play = !play;
            });
            if (play) {
              _controller.play();
            } else {
              _controller.pause();
            }
          },
          onLongPress: () {
            if (_controller.value.isInitialized) {
              _showPlaybackSpeedBottomSheet();
            }
          },
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: _controller.value.isInitialized
                ? FittedBox(
              fit: isLandscape ? BoxFit.contain : BoxFit.fitWidth,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
                : const SizedBox.shrink(),
          ),
        ),
        if (!play)
          Center(
            child: CircleAvatar(
              backgroundColor: Colors.white30,
              radius: isLandscape ? 25.r : 35.r,
              child: Icon(Icons.play_arrow,
                  size: isLandscape ? 25.w : 35.w, color: Colors.white),
            ),
          ),
        if (currentSpeed != 1.0)
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 8.w : 12.w,
                  vertical: isLandscape ? 4.h : 6.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${currentSpeed}x',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isLandscape ? 14.sp : 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isAnimating ? 1 : 0,
            child: LikeAnimation(
              child: Icon(Icons.favorite,
                  size: isLandscape ? 50.w : 100.w, color: Colors.red),
              isAnimating: isAnimating,
              duration: const Duration(milliseconds: 400),
              iconlike: false,
              End: () {
                setState(() {
                  isAnimating = false;
                });
              },
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xffa96d1f),
              bufferedColor: Colors.white38,
              backgroundColor: Colors.grey,
            ),
          ),
        ),
        Visibility(
          visible: !isLandscape, // Hide when in landscape mode
          child:  Positioned(
            top: isLandscape ? 80.h : 400.h,
            right: isLandscape ? 10.w : 15.w,
            child: Column(
              children: [
                LikeAnimation(
                  child: IconButton(
                    onPressed: () {
                      Firebase_Firestor().like(
                        like: widget.snapshot['like'] ?? [],
                        type: widget.collectionType,
                        uid: user,
                        postId: widget.snapshot['postId'],
                      );
                      setState(() {
                        if (!isLiked) {
                          likes.add(user);
                        } else {
                          likes.remove(user);
                        }
                      });
                    },
                    icon: SvgPicture.asset(
                      isLiked
                          ? 'images/icons/heartfillslim.svg'
                          : 'images/icons/heartslim.svg',
                      color: isLiked ? Colors.red : Colors.white,
                      width: isLandscape ? 15.w : 33.w,
                      height: isLandscape ? 15.w : 33.w,
                    ),
                  ),
                  isAnimating: isLiked,
                ),
                SizedBox(height: isLandscape ? 1.h : 2.h),
                Text(likes.length.toString(),
                    style: TextStyle(
                        fontSize: isLandscape ? 8.sp : 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: isLandscape ? 6.h : 9.h),
                GestureDetector(
                  onTap: () {
                    showBottomSheet(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: DraggableScrollableSheet(
                            maxChildSize: 0.6,
                            initialChildSize: 0.6,
                            minChildSize: 0.2,
                            builder: (context, scrollController) {
                              return Comment('reels', widget.snapshot['postId']);
                            },
                          ),
                        );
                      },
                    );
                  },
                  child: Transform.scale(
                    scaleX: -1,
                    child: SvgPicture.asset(
                      'images/icons/commentright1.svg',
                      color: Colors.white,
                      width: isLandscape ? 13.w : 28.w,
                      height: isLandscape ? 13.w : 28.w,
                    ),
                  ),
                ),
                SizedBox(height: isLandscape ? 3.h : 5.h),
                StreamBuilder<QuerySnapshot>(
                  stream: Firebase_Firestor()
                      .getReelComments(postId: widget.snapshot['postId']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('0',
                          style: TextStyle(
                              fontSize: isLandscape ? 9.sp : 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return Text('Err',
                          style: TextStyle(
                              fontSize: isLandscape ? 11.sp : 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white));
                    }
                    final commentCount = snapshot.data?.docs.length ?? 0;
                    return Text(commentCount.toString(),
                        style: TextStyle(
                            fontSize: isLandscape ? 9.sp : 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white));
                  },
                ),
                SizedBox(height: isLandscape ? 1.h : 2.h),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: DraggableScrollableSheet(
                          maxChildSize: 0.6,
                          initialChildSize: 0.4,
                          minChildSize: 0.4,
                          builder: (context, scrollController) {
                            return ShareReelBottomSheet(reelData: widget.snapshot);
                          },
                        ),
                      ),
                    );
                  },
                  icon: SvgPicture.asset(
                    'images/icons/share.svg',
                    color: Colors.white,
                    width: isLandscape ? 15.w : 37.w,
                    height: isLandscape ? 15.w : 37.w,
                  ),
                ),
                SizedBox(height: isLandscape ? 2.h : 3.h),
                FutureBuilder<bool>(
                  future: isAdmin(),
                  builder: (context, snapshot) {
                    bool isAdminUser = snapshot.data ?? false;
                    bool isOwner = isPostOwner();
                    return PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          color: Colors.white, size: isLandscape ? 15.sp : 30.sp),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      elevation: 3,
                      color: Theme.of(context).dialogBackgroundColor,
                      offset: const Offset(-10, 0),
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuEntry<String>> menuItems = [];
                        if (!isPostOwner()) {
                          menuItems.add(
                            PopupMenuItem<String>(
                              value: 'report',
                              height: isLandscape ? 10.h : 36.h,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isLandscape ? 4.w : 12.w,
                                  vertical: isLandscape ? 2.h : 4.h),
                              child: Row(
                                children: [
                                  Icon(Icons.report_outlined,
                                      color: Colors.grey[700],
                                      size: isLandscape ? 6.sp : 18.sp),
                                  SizedBox(width: isLandscape ? 4.w : 8.w),
                                  Text('Report',
                                      style: TextStyle(
                                          fontSize: isLandscape ? 8.sp : 14.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ],
                              ),
                            ),
                          );
                        }
                        if (isAdminUser || isOwner) {
                          menuItems.add(
                            PopupMenuItem<String>(
                              value: 'delete',
                              height: isLandscape ? 10.h : 36.h,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isLandscape ? 4.w : 12.w,
                                  vertical: isLandscape ? 2.h : 4.h),
                              child: Row(
                                children: [
                                  SvgPicture.asset('images/icons/cross.svg',
                                      color: Colors.red[700],
                                      width: isLandscape ? 8.sp : 18.sp,
                                      height: isLandscape ? 8.sp : 18.sp),
                                  SizedBox(width: isLandscape ? 4.w : 8.w),
                                  Text(S.of(context).delete,
                                      style: TextStyle(
                                          fontSize: isLandscape ? 8.sp : 14.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ],
                              ),
                            ),
                          );
                        }
                        if (menuItems.length > 1) {
                          menuItems.insert(1, const PopupMenuDivider(height: 1));
                        }
                        return menuItems;
                      },
                      onSelected: (String result) {
                        if (result == 'report' && !isPostOwner()) {
                          showReportDialog();
                        } else if (result == 'delete') {
                          showDeleteConfirmationDialog();
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: !isLandscape, // Hide when in landscape mode
          child: Positioned(
            bottom: bottomPadding,
            left: isLandscape ? 5.w : 10.w,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    _controller.pause();
                    setState(() {
                      play = false;
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => ProfileScreen(Uid: widget.snapshot['uid'])),
                    );
                  },
                  child: ClipOval(
                    child: SizedBox(
                      height: profileSize,
                      width: profileSize,
                      child: CachedImage(widget.snapshot['profileImage']),
                    ),
                  ),
                ),
                SizedBox(width: isLandscape ? 5.w : 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _controller.pause();
                              setState(() {
                                play = false;
                              });
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ProfileScreen(Uid: widget.snapshot['uid'])),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  widget.snapshot['username'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: usernameFontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (userRole == 'admin') ...[
                                  SizedBox(width: isLandscape ? 1.w : 2.w),
                                  VerifiedBadge(size: verifiedBadgeSize, color: Colors.orange),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: isLandscape ? 10.w : 20.w),
                          if (!isPostOwner())
                            GestureDetector(
                              onTap: _toggleFollow,
                              child: Container(
                                alignment: Alignment.center,
                                width: followButtonWidth,
                                height: followButtonHeight,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  border: Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(5.r),
                                ),
                                child: Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: TextStyle(
                                      fontSize: followButtonFontSize, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: isLandscape ? 4.h : 8.h),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height / 2,
                        ),
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: captionWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  caption,
                                  maxLines: isCaptionExpanded ? null : 2,
                                  overflow:
                                  isCaptionExpanded ? null : TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: captionFontSize, color: Colors.white),
                                ),
                                if (isCaptionLong)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isCaptionExpanded = !isCaptionExpanded;
                                      });
                                    },
                                    child: Text(
                                      isCaptionExpanded ? 'See less' : 'See more..',
                                      style: TextStyle(
                                        fontSize: isLandscape ? 6.sp : 12.sp,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isLandscape ? 5.w : 10.w),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
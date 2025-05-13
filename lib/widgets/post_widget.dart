import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/util/image_cached.dart';
import 'package:syndicate/widgets/comment.dart';
import 'package:syndicate/widgets/like_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/screen/profile_screen.dart';
import 'package:syndicate/screen/Saved_Post.dart';
import 'package:syndicate/generated/l10n.dart';

import 'package:flutter/material.dart';
import 'package:syndicate/widgets/verified_badge.dart';

import '../data/model/usermodel.dart';
import '../screen/EditPostPage.dart';
import '../screen/addpost_text.dart';
import '../screen/share_bottom_sheet.dart'; // Import ProfileScreen
import 'package:timeago/timeago.dart' as timeago;

class PostWidget extends StatefulWidget {
  final snapshot;
  final String collectionType;
  PostWidget(this.snapshot, {required this.collectionType, super.key});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isAnimating = false;
  bool isPostSaved = false; // Track if the post is saved
  String user = '';

  // Add a variable to store the user's role
  String? userRole;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TransformationController _transformationController = TransformationController();

  Future<bool> isAdmin() async {
    try {
      var user = await Firebase_Firestor().getUser();  // Fetch the current user
      return user.role == 'admin';  // Check if the role is admin
    } catch (e) {
      return false;
    }
  }

  Future<void> deletePost() async {
    try {
      // Delete the post from Firestore
      await Firebase_Firestor().deletePost(postId: widget.snapshot['postId'], collectionType: widget.collectionType);
      // Optionally, show a success message or feedback
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted successfully')));
    } catch (e) {
      // Handle any errors during deletion
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting post')));
    }
  }




  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 8,
          backgroundColor: theme.colorScheme.onBackground,
          child: Container(
            padding: EdgeInsets.all(20.sp),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.onBackground,
                  theme.colorScheme.onBackground,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Icon and Title
                Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red[100],
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 32.sp,
                    color: Colors.red[800],
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Confirm ${S.of(context).delete}",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 12.h),
                // Content
                Text(
                  S.of(context).deletePostConfirmation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24.h),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[800],
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        deletePost();
                      },
                      child: Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
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
  }


  bool isPostOwner() {
    return _auth.currentUser!.uid == widget.snapshot['uid'];
  }
  @override
  void initState() {

    super.initState();
    user = _auth.currentUser!.uid;
    checkIfPostSaved();

    // Fetch the post owner's role when the widget initializes
    fetchUserRole();
  }

  // Method to fetch the post owner's role
  Future<void> fetchUserRole() async {
    try {
      Usermodel postOwner = await Firebase_Firestor().getUser(UID: widget.snapshot['uid']);
      setState(() {
        userRole = postOwner.role;
      });
    } catch (e) {
      print("Error fetching user role: $e");
      setState(() {
        userRole = 'user'; // Default to 'user' if there's an error
      });
    }
  }

  Future<void> checkIfPostSaved() async {

    bool saved = await Firebase_Firestor().isPostSaved(widget.snapshot['postId']);
    setState(() {
      isPostSaved = saved;
    });
  }

  void toggleSavePost() async {
    final theme = Theme.of(context);

    // Toggle the save status in Firestore
    await Firebase_Firestor().saveOrUnsavePost(widget.snapshot['postId']);

    // Determine the message and colors based on the current saved state
    final snackBarMessage = isPostSaved
        ? 'Post Unsaved' // Use localization if available
        : 'Post Saved';  // Use localization if available
    final gradientColors = isPostSaved
        ? [Colors.red[700]!, Colors.red[500]!]       // Gradient for unsaved
        : [ Color(0xFFE49C3F)!, Colors.orange[400]!]; // Gradient for saved

    // Show the Snackbar with custom style
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Icon and Message
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isPostSaved ? Icons.bookmark_remove : Icons.bookmark_add,
                      key: ValueKey(isPostSaved),
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    snackBarMessage,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Right side: Action
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SavedPostsPage()),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 10.w),
                  child: Text(
                    'Go to Bookmarks',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent, // Transparent to allow gradient
        padding: EdgeInsets.zero, // Remove default padding
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        elevation: 0, // Elevation handled by boxShadow in decoration
      ),
    );

    // Toggle the saved state after showing the Snackbar
    setState(() {
      isPostSaved = !isPostSaved;
    });
  }

  // Add this method in _PostWidgetState class
  void showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedReason = 'Spam'; // Default value
        final theme = Theme.of(context);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: theme.dialogBackgroundColor,
          title: Row(
            children: [
              Icon(
                Icons.report,
                color: Colors.red[700],
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "Report Post",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineSmall?.color,
                ),
              ),
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
                    Text(
                      "Please select a reason for reporting:",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedReason,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: theme.iconTheme.color,
                          ),
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
                                  Icon(
                                    entry.value,
                                    size: 20.sp,
                                    color: theme.iconTheme.color,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
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
                    content: const Text('Post reported successfully'),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                );
              },
              child:  Text(S.of(context).report),
            ),
          ],
        );
      },
    );
  }



  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // Helper function to format like count
  String formatLikes(int count) {
    if (count >= 1000000) {
      double result = count / 1000000;
      return result % 1 == 0 ? '${result.toInt()}M' : '${result.toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      double result = count / 1000;
      return result % 1 == 0 ? '${result.toInt()}k' : '${result.toStringAsFixed(1)}k';
    } else {
      return count.toString();
    }
  }

  void showImagePopup(BuildContext context, String imageUrl, int likesCount, Stream<QuerySnapshot> commentsStream) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9), // Dark semi-transparent background
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop(); // Close the popup on tap
          },
          child: Dialog(
            backgroundColor: Colors.transparent, // No background color
            insetPadding: EdgeInsets.zero, // No padding for the dialog
            child: Stack(
              children: [
                // Fullscreen Image
                InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.contain, // Ensure the image is proportional
                      ),
                    ),
                  ),
                ),
                // Bottom Action Bar
                // Positioned(
                //
                //   bottom: 20, // Position 20 pixels from the bottom
                //   left: 0,
                //   right: 0,
                //   child: Container(
                //     padding: EdgeInsets.symmetric(horizontal: 16),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center, // Center all icons in the screen
                //       children: [
                //         // Likes Section
                //         Row(
                //           children: [
                //             Icon(Icons.favorite_outline_rounded, color: Colors.white, size: 28),
                //             SizedBox(width: 4), // Reduce spacing
                //             Text(
                //               likesCount.toString(),
                //               style: TextStyle(color: Colors.white, fontSize: 16),
                //             ),
                //           ],
                //         ),                        SizedBox(width: 12), // Reduced space between likes and comments
                //
                //         // Comments Section (Dynamic Stream)
                //         Row(
                //           children: [
                //             Icon(Icons.comment, color: Colors.white, size: 28),
                //             SizedBox(width: 4), // Reduce spacing
                //             StreamBuilder<QuerySnapshot>(
                //               stream: commentsStream, // Listen to the comments stream
                //               builder: (context, snapshot) {
                //                 if (snapshot.hasData) {
                //                   int commentsCount = snapshot.data!.docs.length;
                //                   return Text(
                //                     commentsCount.toString(),
                //                     style: TextStyle(
                //                       color: Colors.white,
                //                       fontSize: 16,
                //                     ),
                //                   );
                //                 } else {
                //                   return Text(
                //                     '0',
                //                     style: TextStyle(
                //                       color: Colors.white,
                //                       fontSize: 16,
                //                     ),
                //                   );
                //                 }
                //               },
                //             ),
                //           ],
                //         ),
                //         SizedBox(width: 12), // Reduced space between comments and share
                //
                //         // Share Icon
                //         Icon(Icons.share, color: Colors.white, size: 28),
                //       ],
                //     ),
                //   ),
                // ),

              ],
            ),
          ),
        );
      },
    );
  }

  bool _isExpanded = false; // Tracks if the caption is expanded

// Helper function to truncate text to roughly two lines
  String _truncateCaption(String caption, int maxLines) {
    // This is a simple approximation; for precise truncation, use a TextPainter
    final words = caption.split(' ');
    int charCount = 0;
    String truncated = '';
    const int approxCharsPerLine = 40; // Adjust based on your font size and screen width

    for (var word in words) {
      if (charCount + word.length + 1 > approxCharsPerLine * maxLines) {
        break;
      }
      truncated += '$word ';
      charCount += word.length + 1; // +1 for the space
    }
    return truncated.trim();
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final caption = widget.snapshot['caption'] as String;
    final truncatedCaption = _truncateCaption(caption, 2); // Truncate to ~2 lines
    final isLongCaption = caption.length > truncatedCaption.length;


    // Get the post time from the snapshot and convert it to DateTime
    final postTime = (widget.snapshot['time'] as Timestamp).toDate();
    // final timeAgoText = timeAgo(postTime);
    // Timestamp timestamp = snapshot['timestamp'] as Timestamp;
    String timeAgo = timeago.format(postTime,);

    return Column(
      children: [
        // Profile Information
        Container(
          width: 375.w,
          height: 54.h,
          color: theme.appBarTheme.backgroundColor,
          child: Container(
            width: 375.w,
            height: 54.h,
            color: theme.appBarTheme.backgroundColor,
            child: Center(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 13.w), // Reducing side padding
                leading: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(Uid: widget.snapshot['uid']),
                      ),
                    );
                  },
                  child: ClipOval(
                    child: SizedBox(
                      width: 33.w,
                      height: 33.h,
                      child: CachedImage(widget.snapshot['profileImage']),
                    ),
                  ),
                ),
                title: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(Uid: widget.snapshot['uid']),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.snapshot['username'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      // Add the VerifiedBadge if the user is an admin
                      if (userRole == 'admin') ...[
                        SizedBox(width: 2.w), // Small spacing between username and badge
                        VerifiedBadge(
                          size: 14.sp, // Adjust size as needed
                          color: Colors.orange, // Customize color if desired
                        ),
                      ],
                    ],
                  ),
                ),
                subtitle: Text(
                  widget.snapshot['location'],
                  style: TextStyle(fontSize: 12.sp,  color: theme.textTheme.bodyMedium?.color,),
                ),
                // Modify the trailing widget in the ListTile to include report option
                trailing: FutureBuilder<bool>(
                  future: isAdmin(),
                  builder: (context, snapshot) {
                    bool isAdminUser = snapshot.data ?? false;
                    bool isOwner = isPostOwner();

                    return PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert, // Three vertical dots
                        color: theme.iconTheme.color ?? Colors.grey[600],
                        size: 18.sp, // Reduced size for compactness
                      ),
                      padding: EdgeInsets.zero, // No extra padding around the icon
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r), // Slightly smaller radius
                      ),
                      elevation: 3, // Subtle elevation for a light shadow
                      color: theme.dialogBackgroundColor, // Matches app theme
                      offset: Offset(0, 40), // Positions menu below the icon
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuEntry<String>> menuItems = [];

                        // Report option (only if not the post owner)
                        if (!isPostOwner()) {
                          menuItems.add(
                            PopupMenuItem<String>(
                              value: 'report',
                              height: 36.h, // Reduced height for compactness
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h), // Tighter padding
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.report_outlined,
                                    color: Colors.grey[700],
                                    size: 18.sp, // Smaller icon
                                  ),
                                  SizedBox(width: 8.w), // Reduced spacing
                                  Text(
                                    'Report',
                                    style: TextStyle(
                                      fontSize: 14.sp, // Smaller, readable text
                                      fontWeight: FontWeight.w500,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Delete option (only for admin or post owner)
                        if (isAdminUser || isOwner) {

                          menuItems.add(
                            PopupMenuItem<String>(
                              value: 'edit',
                              height: 36.h,
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue[700], size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Edit',
                                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                                  ),
                                ],
                              ),
                            ),
                          );
                          menuItems.add(
                            PopupMenuItem<String>(
                              value: 'delete',
                              height: 36.h, // Reduced height for compactness
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h), // Tighter padding
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'images/icons/cross.svg',
                                    color: Colors.red[700],
                                    width: 18.sp, // Smaller SVG
                                    height: 18.sp,
                                  ),
                                  SizedBox(width: 8.w), // Reduced spacing
                                  Text(
                                    S.of(context).delete,
                                    style: TextStyle(
                                      fontSize: 14.sp, // Smaller, readable text
                                      fontWeight: FontWeight.w500,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }



                        // Add a divider if both items are present
                        if (menuItems.length > 1) {
                          menuItems.insert(
                            1,
                            PopupMenuDivider(
                              height: 1.h, // Thin divider
                            ),
                          );
                        }

                        return menuItems;
                      },
                      onSelected: (String result) {
                        if (result == 'report' && !isPostOwner()) {
                          showReportDialog();
                        } else if (result == 'delete') {
                          showDeleteConfirmationDialog();
                        } else if (result == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPostTextScreen(
                                postId: widget.snapshot['postId'],
                                caption: widget.snapshot['caption'],
                                location: widget.snapshot['location'],
                                postImageUrl: widget.snapshot['postImage'],
                                collectionName: widget.collectionType,
                              ),
                            ),
                          ).then((_) => setState(() {})); // Refresh the widget after editing
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),

        ),
        // Post Image with Like Animation
        GestureDetector(
          onDoubleTap: () {
            Firebase_Firestor().like(
              like: widget.snapshot['like'],
              type: widget.collectionType,
              uid: user,
              postId: widget.snapshot['postId'],
            );
            setState(() {
              isAnimating = true;
            });
          },
          onTap: () {
            showImagePopup(
              context,
              widget.snapshot['postImage'],
              widget.snapshot['like'].length,
              FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.snapshot['postId'])
                  .collection('comments')
                  .snapshots(),
            );
          },
          child: Column(
            children: [
              SizedBox(height: 5.h),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Image Container with dynamic sizing
                  Container(
                    width: double.infinity, // Full width of the screen
                    child: CachedImage(
                      widget.snapshot['postImage'],


                    ),
                  ),
                  // Like Animation Overlay
                  AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    opacity: isAnimating ? 1 : 0,
                    child: LikeAnimation(
                      child: Icon(
                        Icons.favorite,
                        size: 100.w,
                        color: Colors.red,
                      ),
                      isAnimating: isAnimating,
                      duration: Duration(milliseconds: 400),
                      iconlike: false,
                      End: () {
                        setState(() {
                          isAnimating = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Description and Action Icons
        Container(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distributes space between left and right
                children: [
                  // Left-side icons (like, comment, share)
                  Row(
                    mainAxisSize: MainAxisSize.min, // Keeps this group compact
                    children: [
                      SizedBox(width: 13.w), // Optional padding from the left edge
                      LikeAnimation(
                        isAnimating: widget.snapshot['like'].contains(user),
                        child: GestureDetector(
                          onTap: () {
                            Firebase_Firestor().like(
                              like: widget.snapshot['like'],
                              type: 'posts',
                              uid: user,
                              postId: widget.snapshot['postId'],
                            );
                          },
                          child: SvgPicture.asset(
                            widget.snapshot['like'].contains(user)
                                ? 'images/icons/heartfillslim.svg'
                                : 'images/icons/heartslim.svg',
                            color: widget.snapshot['like'].contains(user)
                                ? Colors.red
                                : theme.iconTheme.color ?? Colors.black,
                            width: 28.w,
                            height: 28.w,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Flexible(
                        child: Text(
                          formatLikes(widget.snapshot['like'].length),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true, // Allows the sheet to take up more space and respect keyboard
                            backgroundColor: Colors.transparent, // Transparent background for tap detection
                            builder: (context) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context); // Close the sheet when tapping outside
                                },
                                child: Container(
                                  color: Colors.transparent, // Transparent barrier to capture taps
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context).viewInsets.bottom,
                                    ),
                                    child: DraggableScrollableSheet(
                                      maxChildSize: 0.8,
                                      initialChildSize: 0.6,
                                      minChildSize: 0.4,
                                      builder: (context, scrollController) {
                                        return GestureDetector(
                                          onTap: () {}, // Prevents taps on the sheet from closing it
                                          child: Comment('posts', widget.snapshot['postId']),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scaleX: -1,
                              child: SvgPicture.asset(
                                'images/icons/commentright1.svg',
                                color: theme.iconTheme.color ?? Colors.black,
                                width: 26.0,
                                height: 26.0,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Flexible(
                              fit: FlexFit.loose,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(widget.snapshot['postId'])
                                    .collection('comments')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    int commentCount = snapshot.data!.docs.length;
                                    return Text(
                                      formatLikes(commentCount),
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    );
                                  } else {
                                    return Text(
                                      '0',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w200,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () async {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                                ),
                                child: ShareBottomSheet(
                                  postSnapshot: widget.snapshot,
                                ),
                              );
                            },
                          );
                        },
                        child: SvgPicture.asset(
                          'images/icons/share.svg',
                          color: theme.iconTheme.color ?? Colors.black,
                          width: 30.0,
                          height: 30.0,
                        ),
                      ),
                    ],
                  ),
                  // Right-side bookmark icon
                  Padding(
                    padding: EdgeInsets.only(right: 15.w),
                    child: GestureDetector(
                      onTap: toggleSavePost,
                      child: Icon(
                        isPostSaved ? Icons.bookmark_rounded : Icons.bookmark_border,
                        color: theme.iconTheme.color ?? Colors.black,
                        size: 27.w,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7.w),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${widget.snapshot['username']} ',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            TextSpan(
                              text: _isExpanded ? caption : truncatedCaption,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (!_isExpanded && isLongCaption) // Show "See more..." only if truncated
                              TextSpan(
                                text: ' See more...',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue, // Make it stand out
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    setState(() {
                                      _isExpanded = true;
                                    });
                                  },
                              ),
                          ],
                        ),
                        maxLines: _isExpanded ? null : 2, // Limit to 2 lines when not expanded
                        overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                    ),




                  ],



                ),


              ),

              SizedBox(height: 1.h), // Small spacing between caption and time
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 5, 0, 0),
                child: Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ),



              SizedBox(height: 11.w),
              Divider(
                color: theme.dividerColor,
                thickness: 0.5,
                height: 1,
              ),
            ],
          ),
        ),


      ],
    );
  }
}
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/model/usermodel.dart';
import 'package:syndicate/screen/profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class Comment extends StatefulWidget {
  final String type;
  final String uid;

  const Comment(this.type, this.uid, {super.key});

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  final TextEditingController commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  bool? isAdmin;
  String? replyingToCommentId;
  String? replyingToUsername;
  Set<String> expandedComments = {};

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      Usermodel user = await Firebase_Firestor().getUser();
      setState(() {
        isAdmin = user.role == 'admin';
      });
    } catch (e) {
      print("Error fetching user role: $e");
      setState(() {
        isAdmin = false;
      });
    }
  }

  void _setReplyMode(String commentId, String username) {
    setState(() {
      replyingToCommentId = commentId;
      replyingToUsername = username;
      commentController.text = '@$username ';
    });
  }

  void _clearReplyMode() {
    setState(() {
      replyingToCommentId = null;
      replyingToUsername = null;
    });
  }

  // Function to launch URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  // Function to create a RichText widget with clickable URLs
  Widget _buildCommentText(String commentText, TextStyle style) {
    final urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    final matches = urlRegExp.allMatches(commentText);

    if (matches.isEmpty) {
      return Text(
        commentText,
        style: style,
      );
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: commentText.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: style.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _launchUrl(url);
          },
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < commentText.length) {
      spans.add(TextSpan(
        text: commentText.substring(lastMatchEnd),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r), // Already scaled
        topRight: Radius.circular(20.r), // Already scaled
      ),
      child: Container(
        color: theme.colorScheme.surface,
        height: 400.h, // Already scaled
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 20.h, bottom: 60.h), // Already scaled
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection(widget.type)
                    .doc(widget.uid)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var commentData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return commentItem(commentData, null);
                    },
                  );
                },
              ),
            ),
            Positioned(
              top: 5.h, // Already scaled
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40.w, // Already scaled
                  height: 5.h, // Already scaled
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10.r), // Already scaled
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h), // Already scaled
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: replyingToCommentId != null
                              ? 'Replying to @$replyingToUsername'
                              : 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.r), // Already scaled
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onPrimary,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h), // Already scaled
                        ),
                        style: TextStyle(fontSize: 14.sp), // Scale font size
                      ),
                    ),
                    SizedBox(width: 10.w), // Already scaled
                    GestureDetector(
                      onTap: isLoading ? null : _handleCommentSubmit,
                      child: isLoading
                          ? SizedBox(
                        width: 20.w, // Already scaled
                        height: 20.h, // Already scaled
                        child: CircularProgressIndicator(strokeWidth: 2.w), // Scale stroke width
                      )
                          : Icon(
                        Icons.send,
                        color: Colors.orangeAccent,
                        size: 24.w, // Scale icon size
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

  Future<void> _handleCommentSubmit() async {
    if (commentController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      await Firebase_Firestor().Comments(
        comment: commentController.text.trim(),
        type: widget.type,
        uidd: widget.uid,
        parentCommentId: replyingToCommentId,
      );
      commentController.clear();
      _clearReplyMode();
    } catch (e) {
      print('Error submitting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget commentItem(Map<String, dynamic> snapshot, String? parentCommentId, {int nestingLevel = 0}) {
    final theme = Theme.of(context);
    bool isCurrentUser = snapshot['uid'] == FirebaseAuth.instance.currentUser!.uid;
    String commentId = snapshot['CommentUid'];

    // Safely handle the timestamp
    final timestamp = snapshot['timestamp'];
    String timeAgo;
    if (timestamp is Timestamp) {
      timeAgo = timeago.format(timestamp.toDate(), locale: 'en_short');
    } else {
      timeAgo = 'Just Now'; // Fallback for null or invalid timestamp
    }

    // Rest of your existing code...
    double leftPadding = (40 - (nestingLevel * 10)).clamp(10, 40).w;

    final RegExp urlRegExp = RegExp(
      r'((https?:\/\/)?[^\s]+\.[^\s]+)',
      caseSensitive: false,
    );

    List<TextSpan> textSpans = [];
    String commentText = snapshot['comment'];
    int lastEnd = 0;

    for (Match match in urlRegExp.allMatches(commentText)) {
      if (match.start > lastEnd) {
        textSpans.add(
          TextSpan(
            text: commentText.substring(lastEnd, match.start),
            style: TextStyle(fontSize: 14.sp, color: theme.textTheme.bodyLarge?.color),
          ),
        );
      }
      String matchedUrl = match.group(0)!;
      String urlToLaunch = matchedUrl.startsWith('http') ? matchedUrl : 'https://$matchedUrl';
      textSpans.add(
        TextSpan(
          text: matchedUrl,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.blue,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (await canLaunchUrl(Uri.parse(urlToLaunch))) {
                await launchUrl(Uri.parse(urlToLaunch), mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not launch $urlToLaunch')),
                );
              }
            },
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < commentText.length) {
      textSpans.add(
        TextSpan(
          text: commentText.substring(lastEnd),
          style: TextStyle(fontSize: 14.sp, color: theme.textTheme.bodyLarge?.color),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: parentCommentId != null ? leftPadding : 15.w,
        top: 10.h,
        bottom: 8.h,
        right: 8.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(Uid: snapshot['uid'])),
                ),
                child: CircleAvatar(
                  radius: 13.r,
                  backgroundImage: CachedNetworkImageProvider(snapshot['profileImage']),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfileScreen(Uid: snapshot['uid'])),
                          ),
                          child: Text(
                            snapshot['username'],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          timeAgo,
                          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    RichText(
                      text: TextSpan(children: textSpans),
                    ),
                    SizedBox(height: 5.h),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection(widget.type)
                          .doc(widget.uid)
                          .collection('comments')
                          .doc(commentId)
                          .collection('replies')
                          .snapshots(),
                      builder: (context, replySnapshot) {
                        int replyCount = replySnapshot.hasData ? replySnapshot.data!.docs.length : 0;
                        String replyText = replyCount > 0
                            ? 'Reply  •  View $replyCount ${replyCount == 1 ? "reply" : "replies"}'
                            : 'Reply';
                        return GestureDetector(
                          onTap: () {
                            if (replyCount > 0) {
                              setState(() {
                                if (expandedComments.contains(commentId)) {
                                  expandedComments.remove(commentId);
                                } else {
                                  expandedComments.add(commentId);
                                }
                              });
                            } else {
                              _setReplyMode(commentId, snapshot['username']);
                            }
                          },
                          child: Text(
                            replyText,
                            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Firebase_Firestor().likeComment(
                        type: widget.type,
                        postId: widget.uid,
                        commentId: commentId,
                        parentCommentId: parentCommentId,
                      );
                      setState(() {});
                    },
                    child: Icon(
                      (snapshot['likes'] as List).contains(FirebaseAuth.instance.currentUser!.uid)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18.sp,
                      color: (snapshot['likes'] as List).contains(FirebaseAuth.instance.currentUser!.uid)
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    '${(snapshot['likes'] as List).length}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  if (isCurrentUser || (isAdmin ?? false)) SizedBox(width: 10.w),
                  if (isCurrentUser || (isAdmin ?? false))
                    GestureDetector(
                      onTap: () async {
                        await Firebase_Firestor().deleteComment(
                          type: widget.type,
                          postId: widget.uid,
                          commentId: commentId,
                          parentCommentId: parentCommentId,
                        );
                        setState(() {});
                      },
                      child: Icon(Icons.delete, size: 18.sp, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
          if (expandedComments.contains(commentId))
            Padding(
              padding: EdgeInsets.only(left: 20.w),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection(widget.type)
                    .doc(widget.uid)
                    .collection('comments')
                    .doc(commentId)
                    .collection('replies')
                    .snapshots(),
                builder: (context, replySnapshot) {
                  if (!replySnapshot.hasData) return SizedBox();
                  return Column(
                    children: replySnapshot

                        .data!.docs.map((doc) {
                      var replyData = doc.data() as Map<String, dynamic>;
                      return commentItem(replyData, commentId, nestingLevel: nestingLevel + 1);
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
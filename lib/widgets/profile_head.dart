import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/data/model/usermodel.dart';
import 'package:syndicate/util/image_cached.dart';
import 'package:syndicate/generated/l10n.dart';
import '../Followers/FollowersFollowingPage.dart';
import '../screen/EditProfilePage.dart';
import '../screen/chat_page.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

class ProfileHead extends StatelessWidget {
  final Usermodel user;
  final int postCount;
  final bool isFollowing;
  final bool isCurrentUser;
  final Function followCallback;
  final String userId;

  ProfileHead({
    required this.user,
    required this.postCount,
    required this.isFollowing,
    required this.isCurrentUser,
    required this.followCallback,
    required this.userId,
  });

  // Function to show circular image with blurred background
  void _showCircularImage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              Center(
                child: ClipOval(
                  child: SizedBox(
                    width: 200.w, // Scale width
                    height: 200.h, // Scale height
                    child: CachedImage(user.profile),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to launch URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Function to create a RichText widget with clickable URLs
  Widget _buildBioText(BuildContext context) {
    final theme = Theme.of(context);
    final bioText = user.bio;
    final urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    final matches = urlRegExp.allMatches(bioText);

    if (matches.isEmpty) {
      return Text(
        bioText,
        style: TextStyle(
          fontSize: 12.sp, // Already scaled
          fontWeight: FontWeight.w300,
          color: theme.textTheme.bodyLarge?.color,
        ),
      );
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: bioText.substring(lastMatchEnd, match.start),
          style: TextStyle(
            fontSize: 12.sp, // Already scaled
            fontWeight: FontWeight.w300,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ));
      }

      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          fontSize: 12.sp, // Already scaled
          fontWeight: FontWeight.w300,
          color: Colors.blue,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _launchUrl(url);
          },
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < bioText.length) {
      spans.add(TextSpan(
        text: bioText.substring(lastMatchEnd),
        style: TextStyle(
          fontSize: 12.sp, // Already scaled
          fontWeight: FontWeight.w300,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h), // Already scaled
                child: GestureDetector(
                  onTap: () => _showCircularImage(context),
                  child: ClipOval(
                    child: SizedBox(
                      width: 80.w, // Already scaled
                      height: 80.h, // Already scaled
                      child: CachedImage(user.profile),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              postCount.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp, // Already scaled
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: 4.h), // Already scaled
                            Text(
                              S.of(context).posts,
                              style: TextStyle(
                                fontSize: 13.sp, // Already scaled
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            print("Navigating to Followers list for userId: $userId");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowersFollowingPage(
                                  userId: userId,
                                  isFollowingList: false,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h), // Already scaled
                            child: Column(
                              children: [
                                Text(
                                  user.followers.length.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp, // Already scaled
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                SizedBox(height: 4.h), // Already scaled
                                Text(
                                  S.of(context).followers,
                                  style: TextStyle(
                                    fontSize: 13.sp, // Already scaled
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            print("Navigating to Following list for userId: $userId");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowersFollowingPage(
                                  userId: userId,
                                  isFollowingList: true,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h), // Already scaled
                            child: Column(
                              children: [
                                Text(
                                  user.following.length.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp, // Already scaled
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                SizedBox(height: 4.h), // Already scaled
                                Text(
                                  S.of(context).following,
                                  style: TextStyle(
                                    fontSize: 13.sp, // Already scaled
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w), // Already scaled
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 12.sp, // Already scaled
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 5.h), // Already scaled
                _buildBioText(context),
              ],
            ),
          ),
          SizedBox(height: 20.h), // Already scaled
          Row(
            children: [
              if (!isCurrentUser)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13.w), // Already scaled
                    child: GestureDetector(
                      onTap: () {
                        followCallback();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 30.h, // Already scaled
                        decoration: BoxDecoration(
                          color: isFollowing ? Colors.red : Colors.blue,
                          borderRadius: BorderRadius.circular(5.r), // Already scaled
                          border: Border.all(
                            color: isFollowing ? Colors.red : Colors.blue,
                            width: 1.w, // Scale border width
                          ),
                        ),
                        child: Text(
                          isFollowing ? S.of(context).unfollow : S.of(context).follow,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 14.sp, // Scale font size
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (isCurrentUser)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13.w), // Already scaled
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(userId: userId),
                          ),
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 30.h, // Already scaled
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary,
                          borderRadius: BorderRadius.circular(5.r), // Already scaled
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1.w, // Scale border width
                          ),
                        ),
                        child: Text(
                          S.of(context).editProfile,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 14.sp, // Scale font size
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h), // Already scaled
          if (isFollowing && !isCurrentUser)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 13.w), // Already scaled
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              otherUserId: userId,
                              otherUsername: user.username,
                              otherUserProfile: user.profile,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 30.h, // Already scaled
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(5.r), // Already scaled
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.w, // Scale border width
                          ),
                        ),
                        child: Text(
                          S.of(context).message,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.sp, // Scale font size
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

              ),
            ),
          SizedBox(height: 5.h), // Already scaled
        ],
      ),
    );
  }
}
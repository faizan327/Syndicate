// lib/widgets/story_avatar.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/model/story_model.dart';
import 'package:syndicate/screen/story_view_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../data/firebase_service/firestor.dart';
import 'animated_border.dart';

class StoryAvatar extends StatelessWidget {
  final String userId;
  final String username;
  final String profileImage;
  final bool hasActiveStory;
  final List<Map<String, dynamic>>? activeUsers;

  const StoryAvatar({
    Key? key,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.hasActiveStory,
    this.activeUsers, required StoryModel story,
  }) : super(key: key);

  Future<bool> _isAllStoriesViewed(BuildContext context) async {
    final firestore = Firebase_Firestor();
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch stories from both collections
    List<StoryModel> stories1 = await firestore.getUserStories(userId, 'stories').first;
    List<StoryModel> stories2 = await firestore.getUserStories(userId, 'AdminStories').first;
    List<StoryModel> allStories = [...stories1, ...stories2];

    // Check if all stories are viewed by the current user
    return allStories.isNotEmpty && allStories.every((story) => story.viewedBy.contains(currentUserId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: hasActiveStory
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewScreen(
              userId: userId,
              activeUsers: activeUsers ?? [],
            ),
          ),
        );
      }
          : null,
      child: Column(
        children: [
          FutureBuilder<bool>(
            future: _isAllStoriesViewed(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(radius: 26.w, backgroundImage: NetworkImage(profileImage));
              }
              bool allViewed = snapshot.data ?? false;
              return allViewed
                  ? AnimatedBorder(
                isActive: true, // Always active for grey border effect
                isGreyBorder: true, // Enables grey border animation
                child: CircleAvatar(
                  radius: 26.w,
                  backgroundImage: NetworkImage(profileImage),
                ),
              )
                  : AnimatedBorder(
                isActive: hasActiveStory,
                isGreyBorder: false, // Uses the default orange animation
                child: CircleAvatar(
                  radius: 26.w,
                  backgroundImage: NetworkImage(profileImage),
                ),
              );
            },
          ),

          SizedBox(height: 4.h),
          Text(
            username,
            style: TextStyle(fontSize: 12.sp, color: theme.textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }
}
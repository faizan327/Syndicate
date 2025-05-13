import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syndicate/widgets/post_widget.dart';
import 'package:syndicate/data/model/story_model.dart';
import 'package:syndicate/widgets/story_avatar.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/screen/story_upload_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rxdart/rxdart.dart'; // Add this for combining streams

class Userposts extends StatefulWidget {
  const Userposts({super.key});

  @override
  State<Userposts> createState() => _UserpostsState();
}

class _UserpostsState extends State<Userposts> with AutomaticKeepAliveClientMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final Firebase_Firestor _firestoreService = Firebase_Firestor();
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
  }

  @override
  bool get wantKeepAlive => true;

  /// Fetches active stories from Firestore
  Stream<List<StoryModel>> _fetchActiveStories() {
    return _firestoreService.getActiveStories();
  }

  /// Fetches user data for the current user
  Future<Map<String, dynamic>> _fetchCurrentUserData() async {
    DocumentSnapshot userDoc = await _firebaseFirestore.collection('users').doc(currentUserId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  /// Combines user posts and admin posts into a single stream
  Stream<List<Map<String, dynamic>>> _fetchCombinedPosts() {
    // Stream for user posts
    Stream<QuerySnapshot> userPostsStream = _firebaseFirestore
        .collection('posts')
        .orderBy('time', descending: true)
        .snapshots();

    // Stream for admin posts
    Stream<QuerySnapshot> adminPostsStream = _firebaseFirestore
        .collection('AdminPosts')
        .orderBy('time', descending: true)
        .snapshots();

    // Combine both streams using rxdart
    return Rx.combineLatest2(
      userPostsStream,
      adminPostsStream,
          (QuerySnapshot userPosts, QuerySnapshot adminPosts) {
        // Combine the posts into a single list
        List<Map<String, dynamic>> combinedPosts = [];

        // Add user posts with collection type
        for (var doc in userPosts.docs) {
          Map<String, dynamic> postData = doc.data() as Map<String, dynamic>;
          postData['collectionType'] = 'posts'; // Add collection type to differentiate
          combinedPosts.add(postData);
        }

        // Add admin posts with collection type
        for (var doc in adminPosts.docs) {
          Map<String, dynamic> postData = doc.data() as Map<String, dynamic>;
          postData['collectionType'] = 'AdminPosts'; // Add collection type to differentiate
          combinedPosts.add(postData);
        }

        // Sort combined list by time (descending)
        combinedPosts.sort((a, b) {
          Timestamp timeA = a['time'] ?? Timestamp.now();
          Timestamp timeB = b['time'] ?? Timestamp.now();
          return timeB.compareTo(timeA); // Newest first
        });

        return combinedPosts;
      },
    );
  }

  String _truncateUsername(String username, int maxLength) {
    if (username.length <= maxLength) {
      return username;
    }
    return '${username.substring(0, maxLength)}...';
  }

  Widget _buildShimmerLoading() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.progressIndicatorTheme.color!,
      highlightColor: theme.progressIndicatorTheme.color!,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5, // Placeholder for shimmer effect
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30.w,
                  backgroundColor: Colors.white,
                ),
                SizedBox(height: 2.h),
                Container(
                  width: 60.w,
                  height: 10.h,
                  color: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Stories Section
          SliverToBoxAdapter(
            child: Container(
              height: 100.h,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: StreamBuilder<List<StoryModel>>(
                stream: _fetchActiveStories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerLoading();
                  }
                  List<StoryModel> stories = snapshot.data ?? [];

                  // Extract unique users with active stories
                  Map<String, List<StoryModel>> userStoriesMap = {};
                  for (var story in stories) {
                    if (userStoriesMap.containsKey(story.userId)) {
                      userStoriesMap[story.userId]!.add(story);
                    } else {
                      userStoriesMap[story.userId] = [story];
                    }
                  }

                  // Convert to list of users with active stories
                  List<Map<String, dynamic>> activeUsers = [];
                  userStoriesMap.forEach((userId, userStories) {
                    activeUsers.add({
                      'userId': userId,
                      'stories': userStories,
                    });
                  });

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _fetchCurrentUserData(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerLoading();
                      }
                      Map<String, dynamic> currentUserData = userSnapshot.data ?? {};
                      String currentUsername = currentUserData['username'] ?? 'You';
                      String currentProfile = currentUserData['profile'] ?? '';

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: activeUsers.length + 1, // +1 for current user's story
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Current user's story upload button
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => StoryUploadScreen()),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 30.w,
                                          backgroundColor: theme.colorScheme.secondary,
                                          backgroundImage: NetworkImage(currentProfile),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 20.w,
                                            height: 20.w,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black,
                                              border: Border.all(color: Colors.white, width: 2.w),
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 15.w,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Your Story',
                                      style: TextStyle(fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Display other users' stories
                          var userStories = activeUsers[index - 1]['stories'] as List<StoryModel>;
                          String userId = activeUsers[index - 1]['userId'];
                          StoryModel latestStory = userStories.first;

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firebaseFirestore.collection('users').doc(userId).get(),
                            builder: (context, userDocSnapshot) {
                              if (!userDocSnapshot.hasData) {
                                return SizedBox.shrink();
                              }
                              Map<String, dynamic> userData = userDocSnapshot.data!.data() as Map<String, dynamic>;
                              String username = userData['username'] ?? 'User';
                              String profileImage = userData['profile'] ?? '';

                              bool hasActiveStory = userStories.isNotEmpty;

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w),
                                child: StoryAvatar(
                                  userId: userId,
                                  username: _truncateUsername(username, 9),
                                  profileImage: profileImage,
                                  hasActiveStory: hasActiveStory,
                                  story: latestStory,
                                  activeUsers: activeUsers,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Divider between Stories and Posts
          SliverToBoxAdapter(
            child: Divider(
              color: theme.dividerColor,
              thickness: 0.5,
              height: 1,
            ),
          ),

          // Combined Posts Section (User + Admin Posts)
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _fetchCombinedPosts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              List<Map<String, dynamic>> combinedPosts = snapshot.data!;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    Map<String, dynamic> postData = combinedPosts[index];
                    String collectionType = postData['collectionType'];
                    return PostWidget(postData, collectionType: collectionType);
                  },
                  childCount: combinedPosts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
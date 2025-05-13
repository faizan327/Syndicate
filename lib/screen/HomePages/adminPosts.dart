import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syndicate/screen/notifications.dart';
import 'package:syndicate/widgets/post_widget.dart';
import 'package:syndicate/data/model/story_model.dart';
import 'package:syndicate/widgets/story_avatar.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/screen/story_upload_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../chat_list_page.dart';


class AdminPosts extends StatefulWidget {
  const AdminPosts({super.key});

  @override
  State<AdminPosts> createState() => _AdminPostsState();
}

class _AdminPostsState extends State<AdminPosts> with AutomaticKeepAliveClientMixin {
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // appBar: AppBar(
      //   title: Image.asset(
      //     'images/s4.png', // Replace with your logo path
      //     height: 35, // Adjust height as needed
      //   ),
      //   centerTitle: false,
      //   automaticallyImplyLeading: false,
      //   backgroundColor: Colors.white, // Consistent app bar color
      //   elevation: 0,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.favorite_outline),
      //       onPressed: () {
      //         // TODO: Implement navigation to messages
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (context) => Notifications()),
      //         );
      //       },
      //     ),
      //     IconButton(
      //       icon: Image.asset(
      //         'images/messanger.png', // Replace with your logo path
      //         height: 35, // Adjust height as needed
      //       ),
      //       onPressed: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (context) => const ChatListPage()),
      //         );
      //       },
      //     ),
      //   ],
      // ),
      body: CustomScrollView(
        slivers: [
          // Stories Section
          SliverToBoxAdapter(
            child: Container(
                height: 100.h,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: StreamBuilder<List<StoryModel>>(
                  stream: _firestoreService.getActiveAdminStories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerLoading();
                    }
                    List<StoryModel> stories = snapshot.data ?? [];

                    // Extract unique admins with active stories
                    Map<String, List<StoryModel>> adminStoriesMap = {};
                    for (var story in stories) {
                      if (adminStoriesMap.containsKey(story.userId)) {
                        adminStoriesMap[story.userId]!.add(story);
                      } else {
                        adminStoriesMap[story.userId] = [story];
                      }
                    }

                    // Convert to list of admins with active stories
                    List<Map<String, dynamic>> activeAdmins = [];
                    adminStoriesMap.forEach((userId, userStories) {
                      activeAdmins.add({
                        'userId': userId,
                        'stories': userStories,
                      });
                    });

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: activeAdmins.length,
                      itemBuilder: (context, index) {
                        var adminStories = activeAdmins[index]['stories'] as List<StoryModel>;
                        String adminId = activeAdmins[index]['userId'];
                        StoryModel latestStory = adminStories.first;

                        return FutureBuilder<DocumentSnapshot>(
                          future: _firebaseFirestore.collection('users').doc(adminId).get(),
                          builder: (context, adminDocSnapshot) {
                            if (!adminDocSnapshot.hasData) {
                              return SizedBox.shrink();
                            }
                            Map<String, dynamic> adminData =
                            adminDocSnapshot.data!.data() as Map<String, dynamic>;
                            String username = adminData['username'] ?? 'Admin';
                            String profileImage = adminData['profile'] ?? '';

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w),
                              child: StoryAvatar(
                                userId: adminId,
                                username: _truncateUsername(username, 9),
                                profileImage: profileImage,
                                hasActiveStory: true,
                                story: latestStory,
                                activeUsers: activeAdmins, // Pass the list of active admins

                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                )

            ),
          ),

          // Divider between Stories and Posts
          SliverToBoxAdapter(
            child: Divider(
              color: theme.dividerColor,  // You can customize the color and thickness
              thickness: 0.5,
              height: 1,
            ),
          ),

          // Posts Section (wrapped inside a SliverList)
          StreamBuilder<QuerySnapshot>(
            stream: _firebaseFirestore
                .collection('AdminPosts')
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return PostWidget(snapshot.data!.docs[index].data() as Map<String, dynamic>,collectionType: 'AdminPosts');
                  },
                  childCount: snapshot.data!.docs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
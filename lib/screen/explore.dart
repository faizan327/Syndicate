import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/screen/post_screen.dart';
import 'package:syndicate/screen/profile_screen.dart';
import 'package:syndicate/util/image_cached.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:syndicate/generated/l10n.dart';

import '../data/firebase_service/RoleChecker.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final search = TextEditingController();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  bool show = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate crossAxisCount dynamically based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 150.w).floor(); // Adjust based on desired tile width

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SearchBox(),
            if (show)
              StreamBuilder<QuerySnapshot>(
                stream: _firebaseFirestore.collection('posts').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  // Get the list of posts
                  final postList = snapshot.data!.docs;

                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final post = postList[index];

                        return GestureDetector(
                          onTap: () async {
                            String collectionType = 'posts';
                            try {
                              DocumentSnapshot userDoc = await FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(post['uid'])
                                  .get();
                              String role = userDoc['role'] ?? 'user';
                              if (role == 'admin') {
                                collectionType = 'AdminPosts';
                              }
                            } catch (e) {
                              print('Error fetching post owner role: $e');
                            }

                            String postId = post['postId'] ?? post.id;
                            print(
                                'Post ID: $postId, Image URL: ${post['postImage']}, Collection: $collectionType');

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PostScreen(
                                  collectionType: collectionType,
                                  postId: postId,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                            ),
                            child: CachedImage(
                              post['postImage'],
                            ),
                          ),
                        );
                      },
                      childCount: postList.length,
                    ),
                    gridDelegate: SliverQuiltedGridDelegate(
                      crossAxisCount: crossAxisCount < 3 ? 3 : crossAxisCount, // Minimum 3 columns
                      mainAxisSpacing: 3.w,
                      crossAxisSpacing: 3.w,
                      pattern: [
                        QuiltedGridTile(2, 1),
                        QuiltedGridTile(2, 2),
                        QuiltedGridTile(1, 1),
                        QuiltedGridTile(1, 1),
                        QuiltedGridTile(1, 1),
                      ],
                    ),
                  );
                },
              ),

            if (!show)
              StreamBuilder(
                stream: _firebaseFirestore
                    .collection('users')
                    .where('username', isGreaterThanOrEqualTo: search.text)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 5.h,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final snap = snapshot.data!.docs[index];
                          return Column(
                            children: [
                              SizedBox(height: 10.h),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        ProfileScreen(Uid: snap.id),
                                  ));
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 23.r,
                                      backgroundImage: NetworkImage(
                                        snap['profile'],
                                      ),
                                    ),
                                    SizedBox(width: 15.w),
                                    Text(
                                      snap['username'],
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        childCount: snapshot.data!.docs.length,
                      ),
                    ),
                  );
                },
              )
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter SearchBox() {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Container(
          width: double.infinity,
          height: 36.h,
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary,
            borderRadius: BorderRadius.all(
              Radius.circular(10.r),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: theme.iconTheme.color ?? Colors.black,
                  size: 24.r, // Scale icon size
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        if (value.length > 0) {
                          show = false;
                        } else {
                          show = true;
                        }
                      });
                    },
                    controller: search,
                    style: TextStyle(fontSize: 16.sp), // Scale font size
                    decoration: InputDecoration(
                      hintText: 'Search User',
                      hintStyle: TextStyle(
                        color: theme.textTheme.bodyLarge?.color ?? Colors.black,
                        fontSize: 16.sp, // Scale hint text
                      ),
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
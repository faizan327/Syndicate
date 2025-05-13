import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/widgets/post_widget.dart';

class PostScreen extends StatelessWidget {
  final String collectionType; // 'posts' or 'AdminPosts'
  final String? userId; // The UID of the user whose posts are being displayed (optional for multi-post)
  final String? postId; // The ID of a specific post (optional for single-post)
  final int initialIndex; // The initial post to scroll to (used only for multi-post)

  const PostScreen({
    required this.collectionType,
    this.userId,
    this.postId,
    this.initialIndex = 0, // Default to 0 if not provided
    Key? key,
  }) : super(key: key);

  // Determine whether to fetch a single post or a list of posts
  Stream<dynamic> fetchData() {
    if (postId != null && postId!.isNotEmpty) {
      print('Fetching single post - postId: $postId, collectionType: $collectionType');
      return FirebaseFirestore.instance
          .collection(collectionType)
          .doc(postId)
          .snapshots();
    } else if (userId != null && userId!.isNotEmpty) {
      print('Fetching posts for user - userId: $userId, collectionType: $collectionType');
      return FirebaseFirestore.instance
          .collection(collectionType)
          .where('uid', isEqualTo: userId)
          .snapshots();
    } else {
      throw Exception('Either userId or postId must be provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<dynamic>(
          stream: fetchData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('StreamBuilder error: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (postId != null && postId!.isNotEmpty) {
              // Single-post case
              if (!snapshot.hasData) {
                print('No data received for postId: $postId');
                return const Center(child: Text('Post not found - No data'));
              }
              if (!snapshot.data!.exists) {
                print('Post does not exist for postId: $postId in $collectionType');
                return const Center(child: Text('Post not found'));
              }
              final postData = snapshot.data!;
              print('Single post data: ${postData.data()}');
              return ListView(
                children: [
                  PostWidget(
                    postData,
                    collectionType: collectionType,
                  ),
                ],
              );
            } else {
              // Multi-post case
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                print('No posts found for userId: $userId in $collectionType');
                return const Center(child: Text('No posts available'));
              }
              final postList = snapshot.data!.docs;
              print('Post list length: ${postList.length}');
              return ListView.builder(
                itemCount: postList.length,
                controller: ScrollController(
                  initialScrollOffset: initialIndex * 400,
                ),
                itemBuilder: (context, index) {
                  final post = postList[index];
                  print('Post $index data: ${post.data()}');
                  return PostWidget(
                    post,
                    collectionType: collectionType,
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
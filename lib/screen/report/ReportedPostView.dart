// post_view_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/widgets/post_widget.dart';

class PostViewScreen extends StatelessWidget {
  final String postId;
  final String collectionType;

  const PostViewScreen({
    super.key,
    required this.postId,
    required this.collectionType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // title: const Text('Reported Post'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collectionType)
            .doc(postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Post not found'));
          }

          var postData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: PostWidget(
              postData,
              collectionType: collectionType,
            ),
          );
        },
      ),
    );
  }
}
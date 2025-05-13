import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/widgets/reels_item.dart'; // Adjust the import path if needed

class ReportedReelViewScreen extends StatelessWidget {
  final String postId;
  final String collectionType;

  const ReportedReelViewScreen({
    super.key,
    required this.postId,
    required this.collectionType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(
        // title: Text('data')
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection(collectionType)
            .doc(postId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Reel not found',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          }

          var reelData = snapshot.data!.data() as Map<String, dynamic>;
          return ReelsItem(reelData, collectionType: collectionType);
        },
      ),
    );
  }
}
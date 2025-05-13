import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/util/image_cached.dart';
import 'package:syndicate/widgets/reels_item.dart';

class SingleReelPage extends StatefulWidget {
  final String userId;
  final String reelId;

  const SingleReelPage({required this.userId, required this.reelId, Key? key}) : super(key: key);

  @override
  _SingleReelPageState createState() => _SingleReelPageState();
}

class _SingleReelPageState extends State<SingleReelPage> {
  late Future<List<Map<String, dynamic>>> _reelFuture;

  @override
  void initState() {
    super.initState();
    _reelFuture = Firebase_Firestor().getSpecificReel(widget.userId, widget.reelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.black38,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Reel not found.'));
          } else {
            final reel = snapshot.data!.first;
            print('Reel data: $reel'); // Debug print

            // Pass the full reel data, including collectionType
            return ReelsItem(
              reel, // Pass the full reel map
              collectionType: reel['collectionType'], // Pass the collection type
            );
          }
        },
      ),
    );
  }
}
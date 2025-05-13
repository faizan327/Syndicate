import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/widgets/reels_item.dart';

class AdminReelsPage extends StatelessWidget {
  const AdminReelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final PageController _pageController = PageController();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('AdminReels')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        return PageView.builder(
          scrollDirection: Axis.vertical,
          controller: _pageController,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ReelsItem(data, collectionType: 'AdminReels');
          },
        );
      },
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/widgets/reels_item.dart';
import 'package:rxdart/rxdart.dart';

// Singleton stream
final _combinedReelsStream = _createCombinedStream();

Stream<List<QueryDocumentSnapshot>> _createCombinedStream() {
  final firestore = FirebaseFirestore.instance;
  final userReelsStream = firestore
      .collection('reels')
      .orderBy('time', descending: true)
      .snapshots();

  final adminReelsStream = firestore
      .collection('AdminReels')
      .orderBy('time', descending: true)
      .snapshots();

  return Rx.combineLatest2(
    userReelsStream,
    adminReelsStream,
        (QuerySnapshot userSnapshot, QuerySnapshot adminSnapshot) {
      final combinedDocs = [...userSnapshot.docs, ...adminSnapshot.docs];
      combinedDocs.sort((a, b) =>
          (b.data() as Map<String, dynamic>)['time']
              .compareTo((a.data() as Map<String, dynamic>)['time']));
      return combinedDocs;
    },
  ).shareReplay(maxSize: 1);
}

class FollowingReelsPage extends StatefulWidget {
  const FollowingReelsPage({super.key});

  @override
  State<FollowingReelsPage> createState() => _FollowingReelsPageState();
}

class _FollowingReelsPageState extends State<FollowingReelsPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _combinedReelsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return PageView.builder(
          scrollDirection: Axis.vertical,
          controller: _pageController,
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final data = snapshot.data![index].data() as Map<String, dynamic>;
            final collectionType = snapshot.data![index].reference.parent.id == 'reels'
                ? 'reels'
                : 'AdminReels';
            return ReelsItem(data, collectionType: collectionType);
          },
        );
      },
    );
  }
}
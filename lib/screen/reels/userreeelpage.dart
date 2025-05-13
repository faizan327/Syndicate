import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/util/image_cached.dart';
import 'package:syndicate/widgets/like_animation.dart';
import 'package:syndicate/screen/reels/reelsScreen.dart';
import '../../data/firebase_service/RoleChecker.dart';
import '../../widgets/reels_item.dart';


class UserReelPage extends StatefulWidget {
  final String userId;
  final int initialIndex;

  UserReelPage({required this.userId, this.initialIndex = 0});

  @override
  _UserReelPageState createState() => _UserReelPageState();
}

class _UserReelPageState extends State<UserReelPage> with RouteAware {
  late PageController _pageController;
  late Future<List<Map<String, dynamic>>> _reelsFuture;
  int _currentPage = 0;
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _reelsFuture = Firebase_Firestor().getUserReels(widget.userId);

    _pageController.addListener(() {
      int nextPage = _pageController.page?.round() ?? _currentPage;
      if (nextPage != _currentPage) {
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    _pageController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  @override
  void didPushNext() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.black38,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No reels available for this user.', style: TextStyle(color: Colors.white)));
          } else {
            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final reel = snapshot.data![index];
                return ReelsItem(
                  reel,
                  collectionType: reel['uid'] == FirebaseAuth.instance.currentUser?.uid ? 'reels' : 'AdminReels',
                );
              },
            );
          }
        },
      ),
    );
  }
}
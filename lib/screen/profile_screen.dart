import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/model/usermodel.dart';
import 'package:syndicate/screen/post_screen.dart';
import 'package:syndicate/screen/reels/reelsScreen.dart';
import 'package:syndicate/screen/reels/userreeelpage.dart';
import 'package:syndicate/util/image_cached.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/widgets/profile_head.dart';
import 'package:syndicate/generated/l10n.dart';



import '../widgets/verified_badge.dart';
import 'SettingsPage.dart';
import 'chat_page.dart'; // Ensure this import is correct
// Import the SettingsPage (create this file accordingly)
// import 'package:syndicate/screen/settings_page.dart'; // Adjust the path as needed

class ProfileScreen extends StatefulWidget {
  final String Uid;
  ProfileScreen({super.key, required this.Uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int postLength = 0;
  bool isCurrentUser = false;
  bool isFollowing = false;
  Usermodel? user;
  bool isAdmin = false;


  @override
  void initState() {
    super.initState();
    fetchUser();
    checkIfCurrentUser();
    fetchFollowingData();
    fetchUserRole();
  }
  Future<void> fetchUserRole() async {
    try {
      DocumentSnapshot userDoc = await _firebaseFirestore.collection('users').doc(widget.Uid).get();
      String role = userDoc['role'] ?? 'user';  // Default to 'user' if role is not found
      setState(() {
        isAdmin = (role == 'admin'); // Set the flag if user is admin
      });
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  // Function to fetch posts based on role (admin or user)
  Stream<QuerySnapshot> fetchPosts() {
    String collectionName = isAdmin ? 'AdminPosts' : 'posts';
    return _firebaseFirestore
        .collection(collectionName)
        .where('uid', isEqualTo: widget.Uid)
        .snapshots();
  }

  // Function to fetch reels based on role (admin or user)
  Stream<QuerySnapshot> fetchReels() {
    String collectionName = isAdmin ? 'AdminReels' : 'reels';
    return _firebaseFirestore
        .collection(collectionName)
        .where('uid', isEqualTo: widget.Uid)
        .snapshots();
  }

  // Fetch user data once and store it
  Future<void> fetchUser() async {
    Usermodel fetchedUser = await Firebase_Firestor().getUser(UID: widget.Uid);
    print("Fetched user data in ProfileScreen: ${fetchedUser.username}, followers: ${fetchedUser.followers}, following: ${fetchedUser.following}");
    setState(() {
      user = fetchedUser;
    });
  }

  // Check if the profile belongs to the current user
  void checkIfCurrentUser() {
    if (widget.Uid == _auth.currentUser!.uid) {
      setState(() {
        isCurrentUser = true;
      });
    }
  }

  // Fetch following data to determine if the current user is following this profile
  Future<void> fetchFollowingData() async {
    // Fetch current user's data
    DocumentSnapshot snap = await _firebaseFirestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
    List followingList = (snap.data()! as dynamic)['following'];
    if (followingList.contains(widget.Uid)) {
      setState(() {
        isFollowing = true; // User is following this profile
      });
    } else {
      setState(() {
        isFollowing = false; // User is not following
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          title: Row(
            children: [
              Text(user != null ? user!.username : S.of(context).profile),
              if (isAdmin) ...[
                SizedBox(width: 3), // Add some spacing between username and badge
                VerifiedBadge(), // Use the reusable widget
              ],
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: user == null
              ? Center(child: CircularProgressIndicator())
              : Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _firebaseFirestore
                    .collection('posts')
                    .where('uid', isEqualTo: widget.Uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ProfileHead(
                      user: user!,
                      postCount: 0,
                      isFollowing: isFollowing,
                      isCurrentUser: isCurrentUser,
                      followCallback: () {
                        Firebase_Firestor().follow(uid: widget.Uid);
                        setState(() {
                          isFollowing = true;
                        });
                      },
                      userId: widget.Uid,
                    );
                  }
                  if (snapshot.hasError) {
                    return ProfileHead(
                      user: user!,
                      postCount: 0,
                      isFollowing: isFollowing,
                      isCurrentUser: isCurrentUser,
                      followCallback: () {},
                      userId: widget.Uid,
                    );
                  }
                  int postCount = snapshot.data!.docs.length;
                  return ProfileHead(
                    user: user!,
                    postCount: postCount,
                    isFollowing: isFollowing,
                    isCurrentUser: isCurrentUser,
                    followCallback: () {
                      Firebase_Firestor().follow(uid: widget.Uid);
                      setState(() {
                        isFollowing = !isFollowing; // Toggle follow/unfollow
                      });
                    },
                    userId: widget.Uid,
                  );
                },
              ),
              SizedBox( height: 2,),

              TabBar(

                // indicator: BoxDecoration(
                //   borderRadius: BorderRadius.circular(30), // Rounded corners for the indicator
                //   color: Colors.grey.withOpacity(0.2),       // A subtle background color for the selected tab
                // ),
                // labelColor: Colors.black,                    // Color for the selected icon
                // unselectedLabelColor: theme.iconTheme.color ?? Colors.black54, // Color for unselected icons
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 0.0),  // Padding around the indicator
                tabs: [
                  Tab(
                    icon: Icon(
                      Icons.dashboard_outlined,
                      color: theme.iconTheme.color ?? Colors.black,
                      size: 25.0,
                    ),
                  ),
                  Tab(
                    icon: SvgPicture.asset(
                      'images/icons/reelout.svg',
                      color: theme.iconTheme.color ?? Colors.black,
                      width: 23.0,
                      height: 23.0,
                    ),
                  ),
                ],
              ),


              Expanded(
                child: TabBarView(
                  children: [
                    // Posts Tab

                    StreamBuilder<QuerySnapshot>(

                      stream: fetchPosts(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final postList = snapshot.data!.docs;

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: postList.length,
                          itemBuilder: (context, index) {
                            final post = postList[index];

                            return GestureDetector(
                              onTap: () {
                                String collectionType = isAdmin ? 'AdminPosts' : 'posts';
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PostScreen(
                                      collectionType: collectionType,
                                      userId: widget.Uid, // Pass the user ID
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: CachedImage(post['postImage']),
                            );
                          },
                        );
                      },
                    ),

                    // Reels Tab
                    // Reels Tab
                    StreamBuilder<QuerySnapshot>(
                      stream: fetchReels(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final reelList = snapshot.data!.docs;
                        return GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                            childAspectRatio: 0.6, // Adjusted for better reel thumbnail proportions
                          ),
                          itemCount: reelList.length,
                          itemBuilder: (context, index) {
                            final reel = reelList[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserReelPage(
                                      userId: widget.Uid,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: AspectRatio(
                                  aspectRatio: 0.6, // Match the childAspectRatio for consistency
                                  child: CachedImage(reel['thumbnail']),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
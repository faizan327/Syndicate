import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/model/usermodel.dart';
import 'package:syndicate/screen/profile_screen.dart';
import '../generated/l10n.dart';

class FollowersFollowingPage extends StatefulWidget {
  final String userId;
  final bool isFollowingList;

  const FollowersFollowingPage({
    required this.userId,
    required this.isFollowingList,
    Key? key,
  }) : super(key: key);

  @override
  _FollowersFollowingPageState createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage> {
  List<String> userIds = [];
  List<Map<String, dynamic>> usersData = [];
  bool _isLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize ScreenUtil if not globally initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenUtil.init(context, designSize: const Size(375, 812));
    });
    fetchUsers();
  }

  Future<String> getUserIdByUsername(String username) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      throw Exception("Error fetching user ID: $e");
    }
  }

  Future<void> fetchUsers() async {
    try {
      print("Fetching data for userId: ${widget.userId}");
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      List<String> ids = widget.isFollowingList
          ? List<String>.from(userDoc['following'] ?? [])
          : List<String>.from(userDoc['followers'] ?? []);

      if (ids.isEmpty) {
        setState(() {
          usersData = [];
          _isLoading = false;
        });
        return;
      }

      List<Future<Map<String, dynamic>>> userFutures = ids.map((userId) async {
        final user = await Firebase_Firestor().getUser(UID: userId);
        final isFollowing = await Firebase_Firestor().isFollowing(uid: userId);
        return {
          'user': user,
          'isFollowing': isFollowing,
          'userId': userId,
        };
      }).toList();

      List<Map<String, dynamic>> fetchedUsersData = await Future.wait(userFutures);

      setState(() {
        userIds = ids;
        usersData = fetchedUsersData;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  Future<void> toggleFollow(String targetUserId) async {
    try {
      await Firebase_Firestor().follow(uid: targetUserId);
      setState(() {
        final index = usersData.indexWhere((data) => data['userId'] == targetUserId);
        if (index != -1) {
          usersData[index]['isFollowing'] = !usersData[index]['isFollowing'];
        }
      });
    } catch (e) {
      print("Error toggling follow: $e");
    }
  }

  Future<void> navigateToProfile(String username) async {
    String userId = await getUserIdByUsername(username);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(Uid: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        shadowColor: theme.shadowColor.withOpacity(0.2),
        title: Text(
          widget.isFollowingList ? S.of(context).following : S.of(context).followers,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        // centerTitle: true,
        // backgroundColor: theme.colorScheme.surface,
      ),
      body: RefreshIndicator(
        onRefresh: fetchUsers,
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        )
            : usersData.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 60.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              SizedBox(height: 16.h),
              Text(
                S.of(context).noUsersFound,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: usersData.length,
          itemBuilder: (context, index) {
            final userData = usersData[index];
            final Usermodel user = userData['user'];
            final bool isFollowing = userData['isFollowing'];
            final String userId = userData['userId'];

            return _UserTile(
              user: user,
              isFollowing: isFollowing,
              onTapProfile: () => navigateToProfile(user.username),
              onToggleFollow: () => toggleFollow(userId),
            );
          },
        ),
      ),
    );
  }
}

class _UserTile extends StatefulWidget {
  final Usermodel user;
  final bool isFollowing;
  final VoidCallback onTapProfile;
  final VoidCallback onToggleFollow;

  const _UserTile({
    required this.user,
    required this.isFollowing,
    required this.onTapProfile,
    required this.onToggleFollow,
  });

  @override
  _UserTileState createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 1.h),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child:  InkWell(
          onTapDown: (_) => setState(() => _scale = 0.98),
          onTapUp: (_) {
            setState(() => _scale = 1.0);
            widget.onTapProfile();
          },
          onTapCancel: () => setState(() => _scale = 1.0),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 21.r,
                  backgroundColor: theme.colorScheme.surface,
                  backgroundImage: NetworkImage(widget.user.profile),
                  onBackgroundImageError: (_, __) => Icon(
                    Icons.person,
                    size: 22.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 12.w),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.username,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.user.bio ?? 'No bio available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Follow/Unfollow Button
                _FollowButton(
                  isFollowing: widget.isFollowing,
                  onTap: widget.onToggleFollow,
                ),
              ],
            ),
          ),
        ),

      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowButton({
    required this.isFollowing,
    required this.onTap,
  });

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: widget.isFollowing ? Colors.orange : theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.2),
                blurRadius: 4.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Text(
            widget.isFollowing ? S.of(context).unfollow : S.of(context).follow,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
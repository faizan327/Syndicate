import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/model/usermodel.dart';
import 'package:syndicate/screen/chat_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syndicate/generated/l10n.dart';

class FollowingListPage extends StatefulWidget {
  const FollowingListPage({super.key});

  @override
  _FollowingListPageState createState() => _FollowingListPageState();
}

class _FollowingListPageState extends State<FollowingListPage> {
  final Firebase_Firestor firestoreService = Firebase_Firestor();
  List<Map<String, String>> followingUsers = []; // Store only username and profile
  List<Map<String, String>> filteredUsers = [];
  bool isLoading = true;
  bool isSearching = false;
  bool isLoadingMore = false;
  TextEditingController searchController = TextEditingController();
  final int _limit = 20; // Limit initial fetch
  DocumentSnapshot? _lastDocument;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFollowingUsers();
    searchController.addListener(_liveSearch);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoadingMore) {
        _loadMoreFollowingUsers();
      }
    });
  }

  Future<void> _loadFollowingUsers() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firestoreService.currentUserId)
          .get();

      List<dynamic> followingIds = (userDoc.data() as Map<String, dynamic>)['following'] ?? [];

      if (followingIds.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Fetch initial batch of following users with a limit
      QuerySnapshot followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: followingIds.take(_limit).toList())
          .get();

      _lastDocument = followingSnapshot.docs.isNotEmpty ? followingSnapshot.docs.last : null;

      followingUsers = followingSnapshot.docs.map((doc) {
        return {
          'uid': doc.id,
          'username': doc['username'] as String,
          'profile': doc['profile'] as String,
        };
      }).toList();

      filteredUsers = List.from(followingUsers);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading following users: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreFollowingUsers() async {
    if (_lastDocument == null || isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      List<String> followingIds = await _getFollowingIds();
      QuerySnapshot nextBatch = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: followingIds.skip(followingUsers.length).take(_limit).toList())
          .startAfterDocument(_lastDocument!)
          .limit(_limit)
          .get();

      _lastDocument = nextBatch.docs.isNotEmpty ? nextBatch.docs.last : null;

      setState(() {
        followingUsers.addAll(nextBatch.docs.map((doc) => {
          'uid': doc.id,
          'username': doc['username'] as String,
          'profile': doc['profile'] as String,
        }));
        filteredUsers = List.from(followingUsers);
        isLoadingMore = false;
      });
    } catch (e) {
      print("Error loading more following users: $e");
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<List<String>> _getFollowingIds() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firestoreService.currentUserId)
        .get();
    return List<String>.from((userDoc.data() as Map<String, dynamic>)['following'] ?? []);
  }

  void _liveSearch() {
    String query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredUsers = List.from(followingUsers);
      });
      return;
    }

    // Perform live search on Firestore
    FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff') // Unicode trick for prefix search
        .limit(_limit)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        filteredUsers = snapshot.docs.map((doc) {
          return {
            'uid': doc.id,
            'username': doc['username'] as String,
            'profile': doc['profile'] as String,
          };
        }).where((user) {
          return followingUsers.any((f) => f['uid'] == user['uid']);
        }).toList();
      });
    });
  }

  Widget _buildShimmerEffect() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      itemCount: 15,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            title: Container(
              width: 100,
              height: 16,
              color: Colors.grey[300],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 1,
        title: isSearching
            ? TextField(
          controller: searchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Rechercher pour discuter",
            hintStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            border: InputBorder.none,
          ),
          autofocus: true,
        )
            : Text(
          S.of(context).following,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  filteredUsers = List.from(followingUsers);
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
          Expanded(
            child: isLoading
                ? _buildShimmerEffect()
                : filteredUsers.isEmpty
                ? Center(
              child: Text(
                S.of(context).noUsersFound,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: filteredUsers.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredUsers.length) {
                  return Center(child: CircularProgressIndicator());
                }
                var user = filteredUsers[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(user['profile']!),
                    backgroundColor: backgroundColor,
                  ),
                  title: Text(
                    user['username']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () async {
                    String chatId = await firestoreService.createChat(user['uid']!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          otherUserId: user['uid']!,
                          otherUsername: user['username']!,
                          otherUserProfile: user['profile']!,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
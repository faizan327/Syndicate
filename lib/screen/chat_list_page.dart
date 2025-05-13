import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/model/usermodel.dart';
import 'package:syndicate/screen/Chats/Start_chat.dart';
import 'package:syndicate/screen/chat_page.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syndicate/generated/l10n.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final Firebase_Firestor firestoreService = Firebase_Firestor();
  List<QueryDocumentSnapshot> cachedChats = [];
  List<QueryDocumentSnapshot> filteredChats = [];
  Map<String, Usermodel> userCache = {};
  Map<String, int> unreadCountCache = {};
  bool isLoading = true;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChats();
    searchController.addListener(_filterChats);
  }

  void _loadChats() {
    firestoreService.getUserChats().listen((chatSnapshot) async {
      cachedChats = chatSnapshot.docs;
      filteredChats = cachedChats;

      for (var chat in cachedChats) {
        String otherUserId = chat['users'].firstWhere(
              (uid) => uid != firestoreService.currentUserId,
          orElse: () => '',
        );
        if (otherUserId.isNotEmpty && !userCache.containsKey(otherUserId)) {
          userCache[otherUserId] = await firestoreService.getUser(UID: otherUserId);
        }
      }

      FirebaseFirestore.instance
          .collection('notifications')
          .doc(firestoreService.currentUserId)
          .collection('userNotifications')
          .where('actionType', isEqualTo: 'message')
          .snapshots()
          .listen((notificationSnapshot) {
        unreadCountCache.clear();
        for (var chat in cachedChats) {
          String chatId = chat.id;
          int unreadCount = notificationSnapshot.docs
              .where((notification) =>
          notification['chatId'] == chatId && !(notification['isRead'] ?? true))
              .length;
          unreadCountCache[chatId] = unreadCount;
        }
        if (mounted) {
          setState(() {});
        }
      });

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void _filterChats() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredChats = cachedChats.where((chat) {
        String otherUserId = chat['users'].firstWhere(
              (uid) => uid != firestoreService.currentUserId,
          orElse: () => '',
        );
        if (otherUserId.isEmpty || !userCache.containsKey(otherUserId)) return false;
        return userCache[otherUserId]!.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  Widget _buildShimmerEffect() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            subtitle: Container(
              width: 200,
              height: 12,
              color: Colors.grey[300],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 12,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
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
        automaticallyImplyLeading: false,
        elevation: 1,
        title: isSearching
            ? TextField(
          controller: searchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Rechercher ici',
            hintStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            border: InputBorder.none,
          ),
          autofocus: true,
        )
            : Text(
          'Syndicate',
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
                  filteredChats = cachedChats;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(
            height: 1, // Thin divider
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, // Theme-friendly color
          ),
          Expanded( // Wrap the body content in Expanded to fill remaining space
            child: isLoading
                ? _buildShimmerEffect()
                : filteredChats.isEmpty
                ? Center(
              child: Text(
                S.of(context).noChatsYet,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            )
                : ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                var chat = filteredChats[index];
                String chatId = chat.id;
                String otherUserId = chat['users'].firstWhere(
                      (uid) => uid != firestoreService.currentUserId,
                  orElse: () => '',
                );

                if (otherUserId.isEmpty || !userCache.containsKey(otherUserId)) {
                  return const SizedBox();
                }

                Usermodel otherUser = userCache[otherUserId]!;
                String lastMessage = chat['lastMessage'] ?? '';
                Timestamp timestamp = chat['lastTimestamp'] ?? Timestamp.now();
                DateTime lastTime = timestamp.toDate();
                String formattedTime = DateFormat('hh:mm a').format(lastTime);
                int unreadCount = unreadCountCache[chatId] ?? 0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(otherUser.profile),
                    backgroundColor: backgroundColor,
                  ),
                  title: Text(
                    otherUser.username,
                    style: TextStyle(
                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage.isNotEmpty ? lastMessage : S.of(context).noMessagesYet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (unreadCount == 0)
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    setState(() {
                      unreadCountCache[chatId] = 0; // Optimistic update
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          otherUserId: otherUserId,
                          otherUsername: otherUser.username,
                          otherUserProfile: otherUser.profile,
                        ),
                      ),
                    );

                    // Background Firestore updates
                    await firestoreService.markChatAsRead(chatId);
                    QuerySnapshot notifications = await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(firestoreService.currentUserId)
                        .collection('userNotifications')
                        .where('chatId', isEqualTo: chatId)
                        .where('actionType', isEqualTo: 'message')
                        .where('isRead', isEqualTo: false) // Optimize query
                        .get();
                    if (notifications.docs.isNotEmpty) {
                      WriteBatch batch = FirebaseFirestore.instance.batch();
                      for (var doc in notifications.docs) {
                        batch.update(doc.reference, {'isRead': true});
                      }
                      await batch.commit();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      // In ChatPage.dart
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FollowingListPage()),
          );
        },
        backgroundColor: Colors.transparent, // Make the default background transparent
        child: Container(
          width: 56, // Default FAB size
          height: 56,
          decoration:const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            gradient: LinearGradient(
              colors: [
                Colors.orange,      // Starting color (orange)
                Colors.deepOrange,  // Ending color (deep orange)
                Colors.orange,  // Ending color (deep orange)
                Colors.yellow,  // Ending color (Yellow)
              ],
              begin: Alignment.topLeft,  // Gradient start point
              end: Alignment.bottomRight, // Gradient end point
            ),

          ),
          child:const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: _CustomFabLocation(),
    );
  }



  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class _CustomFabLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Custom offset: 20 pixels from the right, 100 pixels from the bottom
    return Offset(
      scaffoldGeometry.scaffoldSize.width - 80, // Adjust from right
      scaffoldGeometry.scaffoldSize.height - 150, // Adjust from bottom
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syndicate/screen/HomePages/adminPosts.dart';
import 'package:syndicate/screen/HomePages/userPosts.dart';
import 'package:syndicate/screen/chat_list_page.dart';
import 'package:syndicate/screen/notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/generated/l10n.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Two tabs
  }

  Future<void> updateExistingUsers() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      QuerySnapshot usersSnapshot = await firestore.collection('users').get();
      WriteBatch batch = firestore.batch();

      for (var userDoc in usersSnapshot.docs) {
        if (userDoc.data() != null && (userDoc.data() as Map<String, dynamic>)['isSuspended'] == null) {
          batch.update(userDoc.reference, {
            'isSuspended': false,
          });
        }
      }

      await batch.commit();
      print('All existing users updated with isSuspended: false');
    } catch (e) {
      print('Error updating users: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: Image.asset(
                'images/syndicategold.png', // Ensure the path is correct
                height: 50.h, // Scale height with screen
                fit: BoxFit.contain,
              ),
              centerTitle: false,
              automaticallyImplyLeading: false,
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              actions: [
                // Use StreamBuilder for real-time unread notification count
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('userNotifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots(), // Real-time stream
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final unreadNotificationCount = snapshot.data!.docs.length; // Count unread notifications
                      return IconButton(
                        icon: Stack(
                          children: [
                            SvgPicture.asset(
                              'images/icons/heartslim.svg',
                              color: theme.appBarTheme.iconTheme?.color ?? Colors.white,
                              width: 28.w, // Scale width
                              height: 28.h, // Scale height
                            ),
                            if (unreadNotificationCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8.w, // Scale width
                                  height: 8.h, // Scale height
                                  decoration: BoxDecoration(
                                    color: Colors.red, // Dot color
                                    borderRadius: BorderRadius.circular(6.r), // Scale radius
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NotificationsScreen()),
                          );
                        },
                      );
                    } else {
                      return IconButton(
                        icon: SvgPicture.asset(
                          'images/icons/heartout.svg',
                          color: theme.appBarTheme.iconTheme?.color ?? Colors.white,
                          width: 25.w, // Scale width
                          height: 25.h, // Scale height
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NotificationsScreen()),
                          );
                        },
                      );
                    }
                  },
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'images/icons/chatdot.svg',
                    color: theme.appBarTheme.iconTheme?.color ?? Colors.white,
                    width: 26.w, // Scale width
                    height: 26.h, // Scale height
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatListPage()),
                    );
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: theme.textTheme.bodyLarge?.color,
                unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                indicatorColor: Colors.orange[400],
                labelStyle: TextStyle(fontSize: 16.sp), // Scale font size
                unselectedLabelStyle: TextStyle(fontSize: 14.sp), // Scale font size
                tabs: [
                  Tab(text: S.of(context).following),
                  Tab(text: S.of(context).admin),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(child: const Userposts(), onRefresh: _refreshData),
              RefreshIndicator(child: const AdminPosts(), onRefresh: _refreshData),
            ],
          ),
        ),
      ),
    );
  }

  // Function to refresh the data on pull to refresh
  Future<void> _refreshData() async {
    setState(() {}); // Forces the page to rebuild, simulating a data refresh.
  }
}
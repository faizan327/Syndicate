import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/screen/add_screen.dart';
import 'package:syndicate/screen/explor_screen.dart';
import 'package:syndicate/screen/explore.dart';
import 'package:syndicate/screen/home.dart';
import 'package:syndicate/screen/profile_screen.dart';
import 'package:syndicate/screen/reels/reelsScreen.dart';

class Navigations_Screen extends StatefulWidget {
  const Navigations_Screen({super.key});

  @override
  State<Navigations_Screen> createState() => _Navigations_ScreenState();
}

int _currentIndex = 0;

class _Navigations_ScreenState extends State<Navigations_Screen> {
  late PageController pageController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userProfileImageUrl;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    _fetchUserProfileImage();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  // Fetch user profile image URL from Firestore
  _fetchUserProfileImage() async {
    try {
      final userId = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      setState(() {
        userProfileImageUrl = userDoc['profile']; // Assuming 'profile' is the field storing the image URL
      });
    } catch (e) {
      print("Error fetching user profile image: $e");
    }
  }

  onPageChanged(int page) {
    setState(() {
      _currentIndex = page;
    });
  }

  navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    if (_currentIndex == 0) {
      // If on HomeScreen, allow the app to exit
      return true;
    } else {
      // If on any other screen, navigate back to HomeScreen
      setState(() {
        _currentIndex = 0;
      });
      pageController.jumpToPage(0);
      return false; // Prevent the app from exiting
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        bottomNavigationBar: Container(
          child: BottomNavigationBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            currentIndex: _currentIndex,
            onTap: navigationTapped,
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'images/icons/home1out.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 25.0.w,
                  height: 25.0.h,
                ),
                activeIcon: SvgPicture.asset(
                  'images/icons/home1fill.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 25.0.w,
                  height: 25.0.h,
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'images/icons/search1.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 25.0.w,
                  height: 25.0.h,
                ),
                activeIcon: SvgPicture.asset(
                  'images/icons/searchactive.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 25.0.w,
                  height: 25.0.h,
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'images/icons/add.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 25.0.w,
                  height: 25.0.h,
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'images/icons/reelout.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 23.0.w,
                  height: 23.0.h,
                ),
                activeIcon: SvgPicture.asset(
                  'images/icons/reelfill.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 23.0.w,
                  height: 23.0.h,
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: userProfileImageUrl == null
                    ? SvgPicture.asset(
                  'images/icons/profileout.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 25.0.w,
                  height: 25.0.h,
                )
                    : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE49C3F),
                      width: 2.0.w,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(userProfileImageUrl!),
                    radius: 15.0.w, // Changed to .w for consistency
                  ),
                ),
                activeIcon: userProfileImageUrl == null
                    ? SvgPicture.asset(
                  'images/icons/profilefill.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 25.0.w,
                  height: 25.0.h,
                )
                    : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 2.0.w,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(userProfileImageUrl!),
                    radius: 15.0.w, // Changed to .w for consistency
                  ),
                ),
                label: '',
              ),
            ],
          ),
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: onPageChanged,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
          children: [
            const HomeScreen(),
            const ExploreScreen(),
            const AddScreen(),
            const ReelScreen(),
            ProfileScreen(
              Uid: _auth.currentUser!.uid,
            ),
          ],
        ),
      ),
    );
  }
}
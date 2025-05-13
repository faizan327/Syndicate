import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/screen/HomePages/adminPosts.dart';
import 'package:syndicate/screen/report/ReportedPostView.dart';
import 'package:syndicate/util/image_cached.dart';
import 'package:syndicate/screen/profile_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../generated/l10n.dart';
import 'chat_page.dart';
import 'package:syndicate/screen/reels/SingleReelPage.dart';
import 'package:timeago/timeago.dart' as timeago;

// Constants
const Duration _animationDuration = Duration(milliseconds: 300);
const double _avatarSize = 40.0;
const double _notificationDotSize = 10.0;

// Monochrome Color Schemes
final ColorScheme monochromeDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF292929),
  secondary: Color(0xFF505050),
  background: Colors.black,
  surface: Color(0xFF333333),
  onPrimary: Colors.white70,
  onSecondary: Colors.white70,
  onBackground: Colors.white70,
  onSurface: Colors.white70,
  error: Colors.deepOrangeAccent,
  onError: Colors.white,
);

final ColorScheme monochromeLightColorScheme = const ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFF0F0F0),
  secondary: Color(0xFF909090),
  background: Colors.white,
  surface: Color(0xFFEEEEEE),
  onPrimary: Colors.black87,
  onSecondary: Colors.black87,
  onBackground: Colors.black87,
  onSurface: Colors.black87,
  error: Colors.red,
  onError: Colors.white,
);

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Set<String> displayedNotificationIds = {};
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadDisplayedNotificationIds();
    _loadLanguagePreference();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    timeago.setLocaleMessages('en', timeago.EnMessages());
    timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());
    timeago.setLocaleMessages('en_short', timeago.EnShortMessages());
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _language = prefs.getString('language') ?? 'en');
  }

  Future<void> _loadDisplayedNotificationIds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      displayedNotificationIds = prefs.getStringList('displayed_notifications')?.toSet() ?? {};
    });
  }

  Future<void> _clearNotifications() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(currentUserId)
          .collection('userNotifications')
          .get();

      for (var doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        displayedNotificationIds.clear();
        prefs.setStringList('displayed_notifications', []);
      });
    } catch (e) {
      print("Error clearing notifications: $e");
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(currentUserId)
          .collection('userNotifications')
          .get();

      for (var doc in snapshot.docs) batch.update(doc.reference, {'isRead': true});
      await batch.commit();
    } catch (e) {
      print("Error marking notifications as read: $e");
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    String timeagoLocale = _language == 'fr' ? 'fr_short' : 'en_short';
    return timeago.format(
      timestamp.toDate(),
      locale: timeagoLocale,
      allowFromNow: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    ColorScheme themeColor = isDarkMode ? monochromeDarkColorScheme : monochromeLightColorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Activity",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeColor.onBackground,
            fontSize: 22.sp,
          ),
        ),
        backgroundColor: themeColor.background,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: themeColor.onBackground),
            color: themeColor.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            onSelected: (choice) async {
              if (choice == 'clear_notifications') await _clearNotifications();
              if (choice == 'mark_all_read') await _markAllNotificationsAsRead();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'clear_notifications',
                child: Text(S.of(context).clearNotifications, style: TextStyle(color: themeColor.onSurface)),
              ),
              PopupMenuItem<String>(
                value: 'mark_all_read',
                child: Text(S.of(context).markAllAsRead, style: TextStyle(color: themeColor.onSurface)),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: themeColor.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(currentUserId)
            .collection('userNotifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return _buildShimmerLoading(themeColor);

          var notifications = snapshot.data!.docs;
          if (notifications.isEmpty) return _buildEmptyState(themeColor);

          // Group notifications by time period
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final last7Days = today.subtract(Duration(days: 7));
          final last30Days = today.subtract(Duration(days: 30));

          List<QueryDocumentSnapshot> todayNotifications = [];
          List<QueryDocumentSnapshot> last7DaysNotifications = [];
          List<QueryDocumentSnapshot> last30DaysNotifications = [];
          List<QueryDocumentSnapshot> olderNotifications = [];

          for (var notification in notifications) {
            Timestamp? timestamp = notification['timestamp'];
            if (timestamp == null) continue;
            DateTime date = timestamp.toDate();

            if (date.isAfter(today)) {
              todayNotifications.add(notification);
            } else if (date.isAfter(last7Days)) {
              last7DaysNotifications.add(notification);
            } else if (date.isAfter(last30Days)) {
              last30DaysNotifications.add(notification);
            } else {
              olderNotifications.add(notification);
            }
          }

          // Build the list of widgets with headers
          List<Widget> notificationWidgets = [];

          if (todayNotifications.isNotEmpty) {
            notificationWidgets.add(_buildHeader("Today", themeColor));
            notificationWidgets.addAll(_buildNotificationWidgets(todayNotifications, themeColor));
          }

          if (last7DaysNotifications.isNotEmpty) {
            notificationWidgets.add(_buildHeader("Last 7 Days", themeColor));
            notificationWidgets.addAll(_buildNotificationWidgets(last7DaysNotifications, themeColor));
          }

          if (last30DaysNotifications.isNotEmpty) {
            notificationWidgets.add(_buildHeader("Last 30 Days", themeColor));
            notificationWidgets.addAll(_buildNotificationWidgets(last30DaysNotifications, themeColor));
          }

          if (olderNotifications.isNotEmpty) {
            notificationWidgets.add(_buildHeader("Older", themeColor));
            notificationWidgets.addAll(_buildNotificationWidgets(olderNotifications, themeColor));
          }

          return ListView(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            children: notificationWidgets,
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title, ColorScheme themeColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: themeColor.onBackground.withOpacity(0.9),
        ),
      ),
    );
  }

  List<Widget> _buildNotificationWidgets(List<QueryDocumentSnapshot> notifications, ColorScheme themeColor) {
    return notifications.map((notification) {
      String actionType = notification['actionType'] ?? 'default';
      bool isRead = notification['isRead'] ?? false;
      Timestamp? timestamp = notification['timestamp'];
      String formattedTime = timestamp != null ? _formatTimestamp(timestamp) : '';

      return AnimatedContainer(
        duration: _animationDuration,
        color: isRead ? themeColor.background : themeColor.primary.withOpacity(0.05),
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
        child: _buildNotificationItem(
          context: context,
          notification: notification,
          actionType: actionType,
          isRead: isRead,
          formattedTime: formattedTime,
          themeColor: themeColor,
        ),
      );
    }).toList();
  }

  Widget _buildShimmerLoading(ColorScheme themeColor) {
    return Shimmer.fromColors(
      baseColor: themeColor.secondary.withOpacity(0.2),
      highlightColor: themeColor.secondary.withOpacity(0.1),
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: _avatarSize / 2, backgroundColor: Colors.grey),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 220.w, height: 14.h, color: Colors.grey),
                    SizedBox(height: 6.h),
                    Container(width: 120.w, height: 12.h, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme themeColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 70.sp, color: themeColor.secondary),
          SizedBox(height: 20.h),
          Text(
            _language == 'fr' ? "Pas d'activité pour le moment" : "No activity yet",
            style: TextStyle(
              fontSize: 18.sp,
              color: themeColor.onBackground.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required BuildContext context,
    required QueryDocumentSnapshot notification,
    required String actionType,
    required bool isRead,
    required String formattedTime,
    required ColorScheme themeColor,
  }) {
    switch (actionType) {
      case 'follow':
        return _buildFollowItem(context, notification, isRead, formattedTime, themeColor);
      case 'message':
        return _buildMessageItem(notification, isRead, formattedTime, themeColor);
      case 'like':
      case 'comment':
        return _buildPostInteractionItem(
            context, notification, isRead, actionType, formattedTime, themeColor);
      case 'admin_post':
        return _buildAdminPostItem(context, notification, isRead, formattedTime, themeColor);
      default:
        return _buildDefaultItem(notification, isRead, formattedTime, themeColor);
    }
  }

  Widget _buildFollowItem(BuildContext context, QueryDocumentSnapshot notification, bool isRead,
      String formattedTime, ColorScheme themeColor) {
    String followerId = notification['followerId'];
    String profileImage = notification['profileImage'];
    String title = _language == 'fr' ? notification['title_fr'] : notification['title_en'];

    return GestureDetector(
      onTap: () => _navigateToProfile(context, followerId, notification),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(profileImage, isRead, themeColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: _parseTitle(title, themeColor, isRead),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(formattedTime, style: _timeStyle(themeColor)),
              ],
            ),
          ),
          _buildFollowButton(followerId, notification, themeColor),
        ],
      ),
    );
  }

  Widget _buildMessageItem(QueryDocumentSnapshot notification, bool isRead, String formattedTime,
      ColorScheme themeColor) {
    String senderProfile = notification['senderProfile'] ?? '';
    String title = _language == 'fr' ? notification['title_fr'] : notification['title_en'];
    String body = notification['body'];

    return GestureDetector(
      onTap: () => _navigateToChat(notification),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(senderProfile, isRead, themeColor, fallbackIcon: Icons.message),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: _parseTitle(title, themeColor, isRead),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(body, style: _bodyStyle(themeColor)),
                SizedBox(height: 4.h),
                Text(formattedTime, style: _timeStyle(themeColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInteractionItem(BuildContext context, QueryDocumentSnapshot notification,
      bool isRead, String actionType, String formattedTime, ColorScheme themeColor) {
    String postId = notification['postId'];
    String profileImage = notification['profileImage'];
    String title = _language == 'fr' ? notification['title_fr'] : notification['title_en'];
    String collectionType = notification['collectionType'] ?? 'posts';
    String userId = notification['userId'];

    return GestureDetector(
      onTap: () => _navigateToPost(context, notification, collectionType, userId, postId),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(profileImage, isRead, themeColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: _parseTitle(title, themeColor, isRead),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 4.h),
                Text(formattedTime, style: _timeStyle(themeColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPostItem(BuildContext context, QueryDocumentSnapshot notification, bool isRead,
      String formattedTime, ColorScheme themeColor) {
    String profileImage = notification['profileImage'] ?? '';
    String title = _language == 'fr' ? notification['title_fr'] : notification['title_en'];
    String body = notification['body'];

    return GestureDetector(
      onTap: () {
        markNotificationAsRead(notification.reference);
        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPosts()));
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(profileImage, isRead, themeColor, fallbackIcon: Icons.announcement),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: _parseTitle(title, themeColor, isRead),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(body, style: _bodyStyle(themeColor)),
                SizedBox(height: 4.h),
                Text(formattedTime, style: _timeStyle(themeColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultItem(QueryDocumentSnapshot notification, bool isRead, String formattedTime,
      ColorScheme themeColor) {
    String title = _language == 'fr' ? notification['title_fr'] : notification['title_en'];
    String body = notification['body'];

    return GestureDetector(
      onTap: () => markNotificationAsRead(notification.reference),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar('', isRead, themeColor, fallbackIcon: Icons.notifications),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: _parseTitle(title, themeColor, isRead),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(body, style: _bodyStyle(themeColor)),
                SizedBox(height: 4.h),
                Text(formattedTime, style: _timeStyle(themeColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Widgets
  Widget _buildAvatar(String imageUrl, bool isRead, ColorScheme themeColor,
      {IconData? fallbackIcon}) {
    return Stack(
      children: [
        ClipOval(
          child: SizedBox(
            width: _avatarSize.w,
            height: _avatarSize.w,
            child: imageUrl.isNotEmpty
                ? CachedImage(imageUrl)
                : Container(
              color: themeColor.secondary.withOpacity(0.2),
              child: Icon(
                fallbackIcon ?? Icons.person,
                color: themeColor.onBackground,
                size: 28.sp,
              ),
            ),
          ),
        ),
        if (!isRead) _buildUnreadDot(themeColor),
      ],
    );
  }

  Widget _buildUnreadDot(ColorScheme themeColor) {
    return Positioned(
      top: 2.h,
      right: 2.w,
      child: Container(
        width: _notificationDotSize.w,
        height: _notificationDotSize.w,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
          border: Border.all(color: themeColor.background, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFollowButton(String followerId, QueryDocumentSnapshot notification, ColorScheme themeColor) {
    return SizedBox(
      height: 32.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: themeColor.onPrimary,
          backgroundColor: themeColor.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          elevation: 0,
        ),
        onPressed: () async {
          await Firebase_Firestor().follow(uid: followerId);
          await markNotificationAsRead(notification.reference);
        },
        child: Text(
          _language == 'fr' ? "Suivre" : "Follow",
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Text Styles
  List<TextSpan> _parseTitle(String title, ColorScheme themeColor, bool isRead) {
    return title.split(' ').map((word) {
      return TextSpan(
        text: '$word ',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
          color: themeColor.onBackground,
        ),
      );
    }).toList();
  }

  TextStyle _bodyStyle(ColorScheme themeColor) => TextStyle(
    fontSize: 13.sp,
    color: themeColor.onBackground.withOpacity(0.85),


    height: 1.3,
  );

  TextStyle _timeStyle(ColorScheme themeColor) => TextStyle(
    fontSize: 12.sp,
    color: themeColor.onBackground.withOpacity(0.6),
    fontWeight: FontWeight.w400,
  );

  // Navigation Helpers
  void _navigateToProfile(BuildContext context, String followerId, QueryDocumentSnapshot notification) {
    markNotificationAsRead(notification.reference);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(Uid: followerId)));
  }

  void _navigateToChat(QueryDocumentSnapshot notification) {
    markNotificationAsRead(notification.reference);
    String senderId = notification['senderId'];
    String senderUsername = notification['senderUsername'];
    String senderProfile = notification['senderProfile'];
    String? messageId = notification['messageId'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          otherUserId: senderId,
          otherUsername: senderUsername,
          otherUserProfile: senderProfile,
          initialMessageId: messageId,
        ),
      ),
    );
  }

  void _navigateToPost(BuildContext context, QueryDocumentSnapshot notification,
      String collectionType, String userId, String postId) {
    markNotificationAsRead(notification.reference);
    if (collectionType == 'reels' || collectionType == 'AdminReels' || collectionType == 'chapters') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SingleReelPage(userId: userId, reelId: postId)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PostViewScreen(postId: postId, collectionType: collectionType)));
    }
  }

  Future<void> markNotificationAsRead(DocumentReference notificationRef) async {
    await notificationRef.update({'isRead': true});
  }
}
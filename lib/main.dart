import 'dart:convert';
import 'package:syndicate/screen/chat_page.dart'; // Import ChatPage

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syndicate/auth/mainpage.dart';
import 'package:syndicate/firebase_options.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/screen/SettingsPage.dart';
import 'package:syndicate/screen/notifications.dart';
import 'package:syndicate/screen/splash_screen.dart';
import 'package:syndicate/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syndicate/themes/light_theme.dart';
import 'package:syndicate/themes/dark_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/firebase_service/firestor.dart';
import 'dart:io' show Platform;

// Initialize FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");

  // Extract notification data
  String title = message.notification?.title ?? "New Notification";
  String body = message.notification?.body ?? "You have a new notification";
  String? actionType = message.data['actionType'] ?? 'default';
  String notificationId = message.messageId ?? 'default_id'; // Provide a fallback

  // Show local notification
  await showNotification(title, body, notificationId.hashCode, actionType!, payload: jsonEncode(message.data));
}



Future<void> _handleNotificationTap(String payload) async {
  try {
    // Decode the payload (it's a JSON string)
    final Map<String, dynamic> data = jsonDecode(payload);

    // Get the current context from the navigator key (to be added in MyApp)
    final navigator = MyApp.navigatorKey.currentState;
    if (navigator == null) return;
    print("Payload received: $payload");

    // Extract actionType and relevant data
    String? actionType = data['actionType'];
    if (actionType == 'message') {
      // Extract data needed for ChatPage
      String chatId = data['chatId'] ?? '';
      String otherUserId = data['senderId'] ?? '';
      String otherUsername = data['senderUsername'] ?? 'Unknown';
      String otherUserProfile = data['senderProfile'] ?? '';
      String? messageId = data['messageId']; // Optional, for highlighting specific message
      // print("ActionType: $actionType");
      // print("ChatId: $chatId");
      // print("OtherUserId: $otherUserId");
      // print("OtherUsername: $otherUsername");
      // print("OtherUserProfile: $otherUserProfile");
      // print("MessageId: $messageId");

      if (chatId.isNotEmpty && otherUserId.isNotEmpty) {
        // Navigate to ChatPage
        navigator.push(
          MaterialPageRoute(
            builder: (context) => ChatPage(
              otherUserId: otherUserId,
              otherUsername: otherUsername,
              otherUserProfile: otherUserProfile,
              initialMessageId: messageId, // Optional: highlight this message
            ),
          ),
        );
      }
    }
    else {
      print("ActionType is not 'message', navigating to NotificationsScreen");
      MyApp.navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => NotificationsScreen(),
        ),
      );
    }
    // Add more conditions for other actionTypes (e.g., 'admin_post', 'comment') if needed
  } catch (e) {
    print("Error handling notification tap: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest, // Use App Attest for iOS
  );
  // Configure Firebase Messaging
  final messaging = FirebaseMessaging.instance;
  if (Platform.isIOS) {
    String? apnsToken = await messaging.getAPNSToken();
    if (apnsToken == null) {
      // Retry after a delay
      await Future.delayed(Duration(seconds: 2));
      apnsToken = await messaging.getAPNSToken();
      print("Retried APNS Token: $apnsToken");
    }
    if (apnsToken != null && FirebaseAuth.instance.currentUser != null) {
      await Firebase_Firestor().saveFCMToken();
    }
  }

  messaging.onTokenRefresh.listen((newToken) async {
    print("FCM Token refreshed: $newToken");
    if (FirebaseAuth.instance.currentUser != null) {
      await Firebase_Firestor().saveFCMToken();
    }
  });
  // if (Platform.isIOS) {
  //   String? apnsToken = await messaging.getAPNSToken();
  //   if (apnsToken != null) {
  //     print("APNS Token: $apnsToken");
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       await Firebase_Firestor().saveFCMToken();
  //     } else {
  //       print("User is not logged in, skipping FCM token save.");
  //     }
  //   } else {
  //     print("APNS Token not available yet, retrying...");
  //   }
  // } else {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     await Firebase_Firestor().saveFCMToken();
  //   } else {
  //     print("User is not logged in, skipping FCM token save.");
  //   }
  // }

  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/launcher_icon');
  // Add iOS initialization settings
  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      if (notificationResponse.payload != null) {
        await _handleNotificationTap(notificationResponse.payload!);
      }
    },
  );

  // // Request notification permission
   await requestNotificationPermission();

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String language = prefs.getString('language') ?? 'en';
      String title = language == 'fr'
          ? message.data['title_fr'] ?? message.notification?.title ?? "New Notification"
          : message.data['title_en'] ?? message.notification?.title ?? "New Notification";
      String body = message.notification?.body ?? "You have a new notification";
      String notificationId = message.data['notificationId'] ?? message.messageId ?? 'default_id';
      await showNotification(
        title,
        body,
        notificationId.hashCode,
        message.data['actionType'] ?? 'default',
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      print("Error handling foreground message: $e");
    }
  });
// Handle notification tap when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    await _handleNotificationTap(jsonEncode(message.data));
  });
  // Handle notification tap when app is terminated
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    await _handleNotificationTap(jsonEncode(initialMessage.data));
  }
  runApp(const MyApp());
  // Add global notification listener for the current user (for foreground only)
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId != null) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> displayedNotificationIds =
        prefs.getStringList('displayed_notifications')?.toSet() ?? {};

    // FirebaseFirestore.instance
    //     .collection('notifications')
    //     .doc(currentUserId)
    //     .collection('userNotifications')
    //     .orderBy('timestamp', descending: true)
    //     .snapshots()
    //     .listen((snapshot) async {
    //   for (var change in snapshot.docChanges) {
    //     if (change.type == DocumentChangeType.added) {
    //       var notification = change.doc.data()!;
    //       String notificationId = change.doc.id;
    //       String actionType = notification['actionType'] ?? 'default';
    //
    //       if (notification['isRead'] == false &&
    //           !displayedNotificationIds.contains(notificationId)) {
    //         await showNotification(
    //           notification['title'],
    //           'Tap to view details',
    //           notificationId.hashCode,
    //           actionType,
    //         );
    //         displayedNotificationIds.add(notificationId);
    //         await prefs.setStringList(
    //             'displayed_notifications', displayedNotificationIds.toList());
    //       }
    //     }
    //   }
    // });
  }

}

Future<void> requestNotificationPermission() async {
  if (Platform.isIOS) {
    // Request iOS-specific notification permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  } else if (Platform.isAndroid) {
    // Request Android notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}

// Updated showNotification with channel selection
Future<void> showNotification(
    String title, String body, int id, String channelType, {String? payload}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String language = prefs.getString('language') ?? 'en'; // Default to English

  if (payload != null) {
    final Map<String, dynamic> data = jsonDecode(payload);
    title = language == 'fr' ? data['title_fr'] ?? title : data['title_en'] ?? title;
  }
  // Get SharedPreferences instance to track displayed notifications
  Set<String> displayedIds =
      prefs.getStringList('displayed_notifications')?.toSet() ?? {};
    // Check if this notification ID has already been displayed
  String notificationKey = id.toString();
  if (displayedIds.contains(notificationKey)) {
    print("Notification with ID $id already displayed, skipping...");
    return; // Exit if the notification was already shown
  }

  // Define notification channels for each category
  const AndroidNotificationDetails commentChannel = AndroidNotificationDetails(
    'comment_channel',
    'Comments',
    channelDescription: 'Notifications for comments on your posts',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const AndroidNotificationDetails likeChannel = AndroidNotificationDetails(
    'like_channel',
    'Likes',
    channelDescription: 'Notifications for likes on your posts',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const AndroidNotificationDetails followChannel = AndroidNotificationDetails(
    'follow_channel',
    'Follows',
    channelDescription: 'Notifications for new followers',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const AndroidNotificationDetails messageChannel = AndroidNotificationDetails(
    'message_channel',
    'Messages',
    channelDescription: 'Notifications for new messages',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const AndroidNotificationDetails adminPostChannel = AndroidNotificationDetails(
    'admin_post_channel',
    'Admin Posts',
    channelDescription: 'Notifications for new posts by admins',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const AndroidNotificationDetails defaultChannel = AndroidNotificationDetails(
    'default_channel',
    'Other Notifications',
    channelDescription: 'Notifications for other activities',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  // Select Android channel based on actionType
  AndroidNotificationDetails? androidChannel;
  switch (channelType) {
    case 'comment':
      androidChannel = commentChannel;
      break;
    case 'like':
      androidChannel = likeChannel;
      break;
    case 'follow':
      androidChannel = followChannel;
      break;
    case 'message':
      androidChannel = messageChannel;
      break;
    case 'admin_post':
      androidChannel = adminPostChannel;
      break;
    default:
      androidChannel = defaultChannel;
      break;
  }

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidChannel,
    iOS: iosDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    platformChannelSpecifics,
    payload: payload,
  );


  // // Mark the notification as displayed
  // displayedIds.add(notificationKey);
  // await prefs.setStringList('displayed_notifications', displayedIds.toList());
  // print("Notification displayed with ID $id and channel $channelType");
}

// Rest of your MyApp class remains unchanged...
class MyApp extends StatefulWidget {
  const MyApp({super.key});
// Add a navigator key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Add a static method to get the current language
  static String getCurrentLanguage(BuildContext context) {
    return MyApp.of(context)?._locale.languageCode ?? 'en';
  }
  @override
  _MyAppState createState() => _MyAppState();
  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('en');
  ThemeOption _selectedTheme = ThemeOption.system;

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _loadSavedTheme();
  }

  void updateTheme(ThemeOption themeOption) {
    setState(() {
      _selectedTheme = themeOption;
    });
  }

  void _loadSavedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLang = prefs.getString('language');
    if (savedLang != null && savedLang == 'fr') {
      setState(() {
        _locale = Locale('fr');
      });
    } else {
      setState(() {
        _locale = Locale('en');
      });
    }
  }

  void _loadSavedTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTheme = prefs.getString('theme');
    setState(() {
      if (savedTheme == 'light') {
        _selectedTheme = ThemeOption.light;
      } else if (savedTheme == 'dark') {
        _selectedTheme = ThemeOption.dark;
      } else {
        _selectedTheme = ThemeOption.system;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Brightness currentBrightness =
        MediaQuery.of(context).platformBrightness;
    final ThemeData currentTheme =
    currentBrightness == Brightness.dark ? darkTheme : lightTheme;

    ThemeData selectedTheme;
    if (_selectedTheme == ThemeOption.light) {
      selectedTheme = lightTheme;
    } else if (_selectedTheme == ThemeOption.dark) {
      selectedTheme = darkTheme;
    } else {
      selectedTheme =
      currentBrightness == Brightness.dark ? darkTheme : lightTheme;
    }
    return ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: MyApp.navigatorKey,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          supportedLocales: const [
            Locale('en', ''),
            Locale('fr', ''),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          locale: _locale,
          theme: selectedTheme,
          routes: {
            '/': (context) => SplashScreen(),
            '/main': (context) => const MainPage(),
            '/settings': (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}
import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:syndicate/data/model/usermodel.dart';
import 'package:syndicate/util/exeption.dart';
import 'package:uuid/uuid.dart';
import '../../main.dart';
import '../model/story_model.dart';
import 'package:rxdart/rxdart.dart';
import '../model/story_model.dart';


class Firebase_Firestor {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> CreateUser({
    required String uid, // Add UID parameter
    required String email,
    required String username,
    required String bio,
    required String role,
    required String profile,
  }) async {
    try {
      await _firebaseFirestore.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'bio': bio,
        'role': role,
        'profile': profile,
        'followers': [],
        'following': [],
        'isSuspended': false,
      });

      // Optionally save FCM token for the current user (if applicable)
      await saveFCMToken();
      return true;
    } catch (e) {
      print("Error creating user: $e");
      return false;
    }
  }

  // Function to update user profile (username, bio, and profile image URL)
  Future<bool> updateUserProfile({
    required String username,
    required String bio,
    required String profileImageUrl,
  }) async {
    try {
      // Update the user's profile information in Firestore
      await _firebaseFirestore.collection('users').doc(_auth.currentUser!.uid).update({
        'username': username,
        'bio': bio,
        'profile': profileImageUrl,  // Store the profile image URL
      });

      return true;
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }

  Future<void> saveFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _firebaseFirestore.collection('users').doc(_auth.currentUser!.uid).update({
        'fcmToken': token,
      });
    }
  }


  Future<Usermodel> getUser({String? UID}) async {
    try {
      final user = await _firebaseFirestore
          .collection('users')
          .doc(UID ?? _auth.currentUser?.uid)
          .get();
      if (!user.exists || user.data() == null) {
        return Usermodel(
          'N/A', // bio
          'unknown@example.com', // email
          [], // followers
          [], // following
          'https://robohash.org/aviator.png', // profile (e.g., default image URL or empty string)
          'user', // role
          'Unknown User', // username
        );
      }

      final snapuser = user.data()!;
      return Usermodel(
          snapuser['bio'],
          snapuser['email'],
          snapuser['followers'],
          snapuser['following'],
          snapuser['profile'],
          snapuser['role'],
          snapuser['username']);
    } on FirebaseException catch (e) {
      throw exceptions(e.message.toString());
    }
  }

  Future<bool> CreatePost({
    required String postImage,
    required String caption,
    required String location,
    required String collectionName,
  }) async {
    var uid = Uuid().v4();
    DateTime data = DateTime.now();
    Usermodel user = await getUser();

    // Create the post
    await _firebaseFirestore.collection(collectionName).doc(uid).set({
      'postImage': postImage,
      'username': user.username,
      'profileImage': user.profile,
      'caption': caption,
      'location': location,
      'uid': _auth.currentUser!.uid,
      'postId': uid,
      'like': [],
      'time': data,
    });

    // Check if the user is an admin and notify all users if true
    if (user.role == 'admin') {
      await notifyAllUsersOfAdminPost(
        titleEnglish: '${user.username} shared a new post',
        titleFrench: '${user.username} a partagé une nouvelle publication',
        body: caption.isNotEmpty ? caption : 'Check out the new admin post!',
        postId: uid,
        profileImage: user.profile, // Already passed

      );
    }

    return true;
  }

  // New method to notify all users of an admin post
  Future<void> notifyAllUsersOfAdminPost({
    required String titleEnglish,  // English title
    required String titleFrench,   // French title
    required String body,
    required String postId,
    required String profileImage, // Ensure this is required
  }) async {
    try {
      // Fetch all users from the 'users' collection
      QuerySnapshot usersSnapshot = await _firebaseFirestore.collection('users').get();

      // Use a batch to write notifications efficiently
      WriteBatch batch = _firebaseFirestore.batch();

      for (var userDoc in usersSnapshot.docs) {
        String recipientId = userDoc.id;

        // Skip the admin who posted (optional)
        if (recipientId == _auth.currentUser!.uid) continue;

        // Reference to the user's notification subcollection
        DocumentReference notificationRef = _firebaseFirestore
            .collection('notifications')
            .doc(recipientId)
            .collection('userNotifications')
            .doc();

        // Add notification data to the batch
        batch.set(notificationRef, {
          'title_en': titleEnglish,   // Store English title
          'title_fr': titleFrench,    // Store French title
          'body': body,
          'actionType': 'admin_post',
          'postId': postId,
          'profileImage': profileImage, // Add the admin’s profile image

          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      // Commit the batch to send all notifications
      await batch.commit();
      print('Notifications sent to all users for admin post');
    } catch (e) {
      print('Error notifying all users: $e');
      throw exceptions('Failed to notify all users: $e');
    }
  }

  Future<void> deletePost({required String postId, required String collectionType}) async {
    try {
      await _firebaseFirestore.collection(collectionType).doc(postId).delete();
    } catch (e) {
      print("Error deleting post: $e");
      throw exceptions("Failed to delete post");
    }
  }

  Future<bool> CreatReels({
    required String video,
    required String caption,
    required String thumbnail,
    required String collectionName,
    required String categoryName,
    String? subcategoryId, // Add this to handle subcategories
  }) async {
    try {
      var uid = Uuid().v4();
      DateTime data = DateTime.now();
      Usermodel user = await getUser();

      DocumentReference reelRef;
      CollectionReference targetCollection;
      if (collectionName == 'chapters' && subcategoryId != null) {
        // Add reel to subcategory's reels subcollection
        targetCollection = _firebaseFirestore
            .collection('chapters')
            .doc(categoryName)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('reels');
            // .doc(uid);
        reelRef = targetCollection.doc(uid);
      } else if (collectionName == 'chapters') {
        // Add reel to category's reels collection
        targetCollection = _firebaseFirestore
            .collection('chapters')
            .doc(categoryName)
            .collection('reels');
            // .doc(uid);
        reelRef = targetCollection.doc(uid);
      } else {
        // Default to the specified collectionName (e.g., 'reels' or 'AdminReels')
        targetCollection = _firebaseFirestore.collection(collectionName);
        reelRef = _firebaseFirestore.collection(collectionName).doc(uid);
      }
      // Get the current number of reels to set the order
      QuerySnapshot existingReels = await targetCollection.get();
      int order = existingReels.docs.length; // Order is the next index

      await reelRef.set({
        'reelsvideo': video,
        'username': user.username,
        'profileImage': user.profile,
        'caption': caption,
        'uid': _auth.currentUser!.uid,
        'categoryName': categoryName,
        'thumbnail': thumbnail,
        'postId': uid,
        'like': [],
        'time': data,
        'collectionType': collectionName, // Store the collection type
        'subcategoryId': subcategoryId,  // Store the subcategory ID if applicable
        'order': order, // Add the order field here
        //here ad the order term..

      });

      print("Reel uploaded to Firestore under $collectionName");
      return true;
    } catch (e) {
      print("Error uploading reel to Firestore: $e");
      return false;
    }
  }

  Future<void> deleteReel({
    required String postId,
    required String collectionType,
    String? categoryName,
    String? subcategoryId, // Add subcategoryId parameter
  }) async {
    try {
      if (collectionType == 'chapters') {
        if (subcategoryId != null && categoryName != null) {
          // Delete from subcategory reels
          await _firebaseFirestore
              .collection('chapters')
              .doc(categoryName)
              .collection('subcategories')
              .doc(subcategoryId)
              .collection('reels')
              .doc(postId)
              .delete();
          print("Successfully deleted reel: $postId from chapters/$categoryName/subcategories/$subcategoryId/reels");
        } else if (categoryName != null) {
          // Delete from category reels
          await _firebaseFirestore
              .collection('chapters')
              .doc(categoryName)
              .collection('reels')
              .doc(postId)
              .delete();
          print("Successfully deleted reel: $postId from chapters/$categoryName/reels");
        } else {
          throw Exception("categoryName is required when collectionType is 'chapters'");
        }
      } else {
        // Delete from flat collections like 'reels' or 'AdminReels'
        await _firebaseFirestore.collection(collectionType).doc(postId).delete();
        print("Successfully deleted reel: $postId from $collectionType");
      }
    } catch (e) {
      print("Error deleting reel: $e");
      rethrow;
    }
  }

  Future<bool> Comments({
    required String comment,
    required String type,
    required String uidd,
    String? parentCommentId,
  }) async {
    try {
      var uid = Uuid().v4();
      Usermodel user = await getUser();
      DocumentReference commentRef = _firebaseFirestore
          .collection(type)
          .doc(uidd)
          .collection('comments')
          .doc(uid);

      if (parentCommentId != null) {
        commentRef = _firebaseFirestore
            .collection(type)
            .doc(uidd)
            .collection('comments')
            .doc(parentCommentId)
            .collection('replies')
            .doc(uid);
      }

      await commentRef.set({
        'comment': comment,
        'username': user.username,
        'profileImage': user.profile,
        'CommentUid': uid,
        'uid': _auth.currentUser!.uid,
        'likes': [],
        'timestamp': FieldValue.serverTimestamp() ?? Timestamp.now(), // Fallback to local time if server timestamp fails
      });

      // Notify post owner
      var postSnapshot = await _firebaseFirestore.collection(type).doc(uidd).get();
      if (postSnapshot.exists && postSnapshot.data() != null) {
        String? postOwnerId = postSnapshot['uid'];
        if (postOwnerId != null) {
          await sendPostInteractionNotification(
            recipientId: postOwnerId,
            actionType: 'comment',
            titleEnglish: '${user.username} commented on your post',
            titleFrench: '${user.username} a commenté votre publication',
            postId: uidd,
            profileImage: user.profile,
            collectionType: type, userId: '',
          );
        } else {
          print('Post document exists but has no "uid" field.');
        }
      } else {
        print('Post document with ID $uidd in collection $type does not exist.');
      }

      return true;
    } catch (e) {
      print('Error in Comments method: $e');
      rethrow; // Rethrow the exception to allow the caller to handle it
    }
  }

  Future<void> deleteComment({
    required String type,
    required String postId,
    required String commentId,
    String? parentCommentId, // If it's a reply
  }) async {
    Usermodel currentUser = await getUser();
    DocumentReference commentRef;

    if (parentCommentId != null) {
      commentRef = _firebaseFirestore
          .collection(type)
          .doc(postId)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(commentId);
    } else {
      commentRef = _firebaseFirestore
          .collection(type)
          .doc(postId)
          .collection('comments')
          .doc(commentId);
    }

    DocumentSnapshot commentDoc = await commentRef.get();
    String commenterUid = commentDoc['uid'];

    // Role-based deletion logic
    if (currentUser.role == 'admin' || commenterUid == _auth.currentUser!.uid) {
      await commentRef.delete();
    } else {
      throw exceptions("You don't have permission to delete this comment.");
    }
  }
  Future<void> likeComment({
    required String type,
    required String postId,
    required String commentId,
    String? parentCommentId,
  }) async {
    String currentUid = _auth.currentUser!.uid;
    DocumentReference commentRef;

    if (parentCommentId != null) {
      commentRef = _firebaseFirestore
          .collection(type)
          .doc(postId)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(commentId);
    } else {
      commentRef = _firebaseFirestore
          .collection(type)
          .doc(postId)
          .collection('comments')
          .doc(commentId);
    }

    DocumentSnapshot commentDoc = await commentRef.get();
    List likes = commentDoc['likes'] ?? [];

    if (likes.contains(currentUid)) {
      await commentRef.update({
        'likes': FieldValue.arrayRemove([currentUid]),
      });
    } else {
      await commentRef.update({
        'likes': FieldValue.arrayUnion([currentUid]),
      });
    }
  }


  Future<void> sendPostInteractionNotification({
    required String recipientId,
    required String actionType, // 'like' or 'comment'
    required String titleEnglish, // English title
    required String titleFrench,  // French title
    required String postId,
    required String profileImage,
    required String collectionType, // 'posts' or 'reels'
    required String userId, // User who owns the post/reel
  }) async {
    await _firebaseFirestore
        .collection('notifications')
        .doc(recipientId)
        .collection('userNotifications')
        .add({
      'title_en': titleEnglish,
      'title_fr': titleFrench,
      'actionType': actionType,
      'postId': postId,
      'profileImage': profileImage,
      'collectionType': collectionType,
      'userId': userId, // Include userId
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }



  Future<String> like({
    required List like,
    required String type,
    required String uid,
    required String postId,
  }) async {
    String res = 'some error';
    try {
      if (like.contains(uid)) {
        _firebaseFirestore.collection(type).doc(postId).update({
          'like': FieldValue.arrayRemove([uid])
        });
      } else {
        _firebaseFirestore.collection(type).doc(postId).update({
          'like': FieldValue.arrayUnion([uid])
        });

        // Fetch post details
        var postSnapshot = await _firebaseFirestore.collection(type).doc(postId).get();
        String postOwnerId = postSnapshot['uid']; // Get the post owner's UID
        Usermodel user = await getUser(); // Get the current user's details

        // Send Firestore notification
        await sendPostInteractionNotification(
          recipientId: postOwnerId,
          actionType: 'like',
          titleEnglish: '${user.username} liked your post',
          titleFrench: '${user.username} a aimé votre publication',
          postId: postId,
          profileImage: user.profile,
          collectionType: type, userId: '', // Pass the collection type
        );
      }
      res = 'success';
    } on Exception catch (e) {
      res = e.toString();
    }
    return res;
  }
  //
// Follow and Unfollow
  //
  Future<void> follow({required String uid}) async {
    String currentUserId = _auth.currentUser!.uid;

    DocumentReference currentUserRef = _firebaseFirestore.collection('users').doc(currentUserId);
    DocumentReference otherUserRef = _firebaseFirestore.collection('users').doc(uid);

    DocumentSnapshot snap = await currentUserRef.get();
    List following = (snap.data() as dynamic)['following'];

    try {
      if (following.contains(uid)) {
        // Unfollow: Remove from both following & followers lists
        await currentUserRef.update({
          'following': FieldValue.arrayRemove([uid]),
        });
        await otherUserRef.update({
          'followers': FieldValue.arrayRemove([currentUserId]),
        });

        // Remove notification (since they unfollowed)
        await _firebaseFirestore
            .collection('notifications')
            .doc(uid)
            .collection('userNotifications')
            .where('followerId', isEqualTo: currentUserId)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

      } else {
        // Follow: Add to following & followers lists
        await currentUserRef.update({
          'following': FieldValue.arrayUnion([uid]),
        });
        await otherUserRef.update({
          'followers': FieldValue.arrayUnion([currentUserId]),
        });

        // Send Follow Notification
        Usermodel user = await getUser(UID: currentUserId); // Get current user's data
        await sendFollowNotification(
          recipientId: uid,
          followerId: currentUserId,
          followerName: user.username,
          profileImage: user.profile,
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }
  Future<void> sendFollowNotification({
    required String recipientId, // User being followed
    required String followerId, // Current user (who followed)
    required String followerName,
    required String profileImage,
  }) async {
    await _firebaseFirestore
        .collection('notifications')
        .doc(recipientId)
        .collection('userNotifications')
        .add({
      'title_en': "$followerName started following you",  // English title
      'title_fr': "$followerName a commencé à vous suivre", // French title
      'followerId': followerId,
      'profileImage': profileImage,
      'timestamp': FieldValue.serverTimestamp(),
      'actionType': 'follow',
      'isRead': false, // Mark as unread by default
    });
  }



  // Getter for current user ID
  String get currentUserId => _auth.currentUser!.uid;

  // Generate a unique chat ID based on user IDs
  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}$uid2' : '${uid2}$uid1';
  }

  // Create or retrieve an existing chat between two users
  Future<String> createChat(String otherUid) async {
    String currentUid = currentUserId;
    String chatId = getChatId(currentUid, otherUid);

    DocumentReference chatDoc = _firebaseFirestore.collection('chats').doc(chatId);
    DocumentSnapshot docSnapshot = await chatDoc.get();

    if (!docSnapshot.exists) {
      await chatDoc.set({
        'users': [currentUid, otherUid],
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  Future<void> sendMessage(
      String chatId,
      String message, {
        String? imageUrl,
        String? audioUrl,
        String? sharedPostImageUrl,
        String? replyToMessageId,
        String? replyToContent,
        Map<String, dynamic>? sharedPostData,
      }) async {
    String currentUid = currentUserId;
    CollectionReference messages = _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    // Add the message and get its reference
    DocumentReference messageRef = await messages.add({
      'senderId': currentUid,
      'message': message.isNotEmpty ? message : null,
      'image': imageUrl,
      'audio': audioUrl,
      'sharedPostImageUrl': sharedPostImageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'delivered': false,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'reactions': {},
      'sharedPost': sharedPostData,
    });

    String messageId = messageRef.id;

    // Determine the notification message and last message content
    String notificationBody;
    String titleEnglish;
    String titleFrench;
    String lastMessageContent;

    if (sharedPostData != null) {
      notificationBody = "Shared a post";
      titleEnglish = "Shared a post";
      titleFrench = "A partagé une publication";
      lastMessageContent = "Shared a post";
    } else if (imageUrl != null) {
      notificationBody = "You received an image";
      titleEnglish = "You received an image";
      titleFrench = "Vous avez reçu une image";
      lastMessageContent = "Image";
    } else if (audioUrl != null) {
      notificationBody = "You received an audio message";
      titleEnglish = "You received an audio message";
      titleFrench = "Vous avez reçu un message audio";
      lastMessageContent = "Audio";
    } else if (message.isNotEmpty) {
      notificationBody = message;
      titleEnglish = "New message";
      titleFrench = "Nouveau message";
      lastMessageContent = message;
    } else {
      notificationBody = "New message";
      titleEnglish = "New message";
      titleFrench = "Nouveau message";
      lastMessageContent = "";
    }

    // Update the last message in the chat
    await _firebaseFirestore.collection('chats').doc(chatId).update({
      'lastMessage': lastMessageContent,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });

    // Fetch the sender's username
    final senderDoc = await _firebaseFirestore.collection('users').doc(currentUid).get();
    final senderUsername = senderDoc.data()?['username'] ?? currentUid;

    // Notify the recipient
    String recipientId = chatId.replaceAll(currentUid, '').replaceAll('_', '');
    await saveNotification(
      recipientId: recipientId,
      titleEnglish: "$senderUsername: $titleEnglish",
      titleFrench: "$senderUsername: $titleFrench",
      body: notificationBody,
      messageId: messageId,
    );
  }




  Future<void> markMessageAsDelivered(String chatId, String messageId) async {
    await _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'delivered': true});
  }


  Future<void> markMessageAsRead(String chatId, String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'read': true});
  }







  Future<void> saveNotification({
    required String recipientId, // User ID of the recipient
    required String titleEnglish, // English title
    required String titleFrench,  // French title
    required String body,
    String actionType = "message",
    String? messageId, // Add optional messageId parameter
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Usermodel currentUserData = await Firebase_Firestor().getUser(UID: user.uid);
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(recipientId)
          .collection('userNotifications')
          .add({
        'title_en': titleEnglish,  // Store English title
        'title_fr': titleFrench,   // Store French title
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'actionType': actionType,
        'isRead': false,
        'senderId': user.uid,
        'senderUsername': currentUserData.username,
        'senderProfile': currentUserData.profile,
        'chatId': Firebase_Firestor().getChatId(user.uid, recipientId),
        'messageId': messageId, // Include the message ID in the notification
      });
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;

    // Get all unread messages in the chat
    QuerySnapshot unreadMessages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUid)
        .get();

    // Mark each message as read
    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'read': true});
    }
  }



  // Stream of messages in a specific chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Stream of all chats the current user is part of
  Stream<QuerySnapshot> getUserChats() {
    String currentUid = currentUserId;
    return _firebaseFirestore
        .collection('chats')
        .where('users', arrayContains: currentUid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }

  // Delete message for the current user only
  Future<void> deleteMessageForMe(String chatId, String messageId) async {
    String currentUid = _auth.currentUser!.uid;
    await _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedFor': FieldValue.arrayUnion([currentUid]),
    });
  }

// Delete message for everyone (only if sender)
  Future<void> deleteMessageForEveryone(String chatId, String messageId) async {
    String currentUid = _auth.currentUser!.uid;
    DocumentSnapshot messageDoc = await _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (messageDoc['senderId'] == currentUid) {
      await _firebaseFirestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete(); // Fully delete for sender
    }
  }

  // Mark all unread messages as read in a chat
  Future<void> markChatAsRead(String chatId) async {
    String currentUid = currentUserId;
    CollectionReference messages = _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    // Fetch unread messages where sender is not the current user
    QuerySnapshot unreadMessages = await messages
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUid)
        .get();

    // Batch update all unread messages
    WriteBatch batch = _firebaseFirestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }


  // Method to clear all messages in a chat
  Future<void> clearChat(String chatId) async {
    WriteBatch batch = _firebaseFirestore.batch();
    QuerySnapshot messagesSnapshot = await _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Optionally, update the chat's lastMessage and lastTimestamp
    batch.update(_firebaseFirestore.collection('chats').doc(chatId), {
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> addOrUpdateReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    DocumentReference messageRef = _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    try {
      // Fetch the message document
      DocumentSnapshot messageSnapshot = await messageRef.get();

      // Safely cast the data
      final data = messageSnapshot.data() as Map<String, dynamic>?;

      // Access reactions safely
      final reactions = data?['reactions'] as Map<String, dynamic>? ?? {};

      if (reactions[userId] == reaction) {
        // If the same reaction exists, remove it (toggle)
        await messageRef.update({
          'reactions.$userId': FieldValue.delete(),
        });
      } else {
        // Add or update the reaction using update instead of set
        await messageRef.update({
          'reactions.$userId': reaction,
        });
      }
    } catch (e) {
      print("Error adding/updating reaction: $e");
      throw exceptions("Failed to add/update reaction");
    }
  }




  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    DocumentReference messageRef = _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({
      'reactions.$userId': FieldValue.delete(),
    });
  }
  // ****************************
  //        Story Process        **
  // *****************************

  /// Adds a new story to the 'stories' collection
  Future<bool> addStory({
    required String mediaUrl,
    required String mediaType,
    required String collectionName,// 'image' or 'video'
  }) async {
    try {
      String storyId = Uuid().v4();
      DateTime now = DateTime.now();
      DateTime expiry = now.add(Duration(hours: 24));

      await _firebaseFirestore.collection(collectionName).doc(storyId).set({
        'userId': _auth.currentUser!.uid,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'uploadTime': Timestamp.fromDate(now),
        'expiryTime': Timestamp.fromDate(expiry),
        'viewedBy': [],
      });
      return true;
    } catch (e) {
      print('Error adding story: $e');
      return false;
    }
  }

  Future<void> deleteStory({
    required String storyId,
    required String collectionName, // 'stories' or 'AdminStories'
  }) async {
    try {
      await _firebaseFirestore.collection(collectionName).doc(storyId).delete();
      print("Story $storyId deleted successfully from $collectionName");
    } catch (e) {
      print("Error deleting story: $e");
      throw exceptions("Failed to delete story: $e");
    }
  }

  /// Fetches active stories (not expired)
  Stream<List<StoryModel>> getActiveStories() {
    DateTime now = DateTime.now();
    print("Current Time: $now");

    // Fetch stories from both collections
    var storiesStream1 = _firebaseFirestore
        .collection('stories')
        .where('expiryTime', isGreaterThan: Timestamp.fromDate(now)) // Ensure expiryTime is in the future
        .orderBy('uploadTime', descending: true)
        .snapshots();

    var storiesStream2 = _firebaseFirestore
        .collection('AdminStories')
        .where('expiryTime', isGreaterThan: Timestamp.fromDate(now)) // Ensure expiryTime is in the future
        .orderBy('uploadTime', descending: true)
        .snapshots();

    // Combine both story streams
    return Rx.combineLatest2(storiesStream1, storiesStream2, (querySnapshot1, querySnapshot2) {
      var combinedStories = <StoryModel>[];

      // Add stories from the first stream
      for (var doc in querySnapshot1.docs) {
        combinedStories.add(StoryModel.fromFirestore(doc));
      }

      // Add stories from the second stream
      for (var doc in querySnapshot2.docs) {
        combinedStories.add(StoryModel.fromFirestore(doc));
      }
      return combinedStories;
    });
  }




  Stream<List<StoryModel>> getUserStories(String userId, String collectionName) {
    DateTime now = DateTime.now();
    return _firebaseFirestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .where('expiryTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('uploadTime', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => StoryModel.fromFirestore(doc)).toList());
  }

  /// Marks a story as viewed by the current user
  Future<void> markStoryAsViewed(String storyId, String collectionName) async {
    try {
      await _firebaseFirestore.collection(collectionName).doc(storyId).update({
        'viewedBy': FieldValue.arrayUnion([_auth.currentUser!.uid]), // Adds current user's UID
      });
    } catch (e) {
      print("Error updating viewedBy for story $storyId: $e");
    }
  }



  // Add or update the shared post to the selected chat.


  // Add the isFollowing method
  Future<bool> isFollowing({required String uid}) async {
    try {
      // Get the current user's document
      DocumentSnapshot snap = await _firebaseFirestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      // Extract the 'following' field from the document
      List following = (snap.data()! as dynamic)['following'];

      // Check if the 'uid' is in the 'following' list
      return following.contains(uid);
    } catch (e) {
      print(e.toString());
      return false; // Return false if there's an error (assuming not following)
    }
  }

  Future<List<String>> _getFollowingUsers() async {
    String currentUserId = _auth.currentUser!.uid;  // Get the current user ID

    try {
      // Get the document for the current user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      // Safely cast the data to Map<String, dynamic>
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Get the list of following users from the 'following' field
      List<dynamic> following = userData['following'] ?? [];

      return following.map((userId) => userId.toString()).toList();  // Convert to List<String>
    } catch (e) {
      print('Error fetching following list: $e');
      return [];  // Return an empty list in case of error
    }
  }


  Stream<List<StoryModel>> getActiveAdminStories() {
    DateTime now = DateTime.now();

    // Fetch all admin user IDs
    return _firebaseFirestore
        .collection('users')
        .where('role', isEqualTo: 'admin') // Fetch users with the 'admin' role
        .get() // This fetches the admin user documents
        .then((QuerySnapshot usersSnapshot) {
      // Extract admin user IDs
      List<String> adminIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      // If no admins are found, return an empty stream
      if (adminIds.isEmpty) {
        return Stream.value(<StoryModel>[]);
      }

      // Fetch admin stories from both collections
      var adminStoriesStream1 = _firebaseFirestore
          .collection('stories')
          .where('userId', whereIn: adminIds) // Filter stories by admin user IDs
          .where('expiryTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('uploadTime', descending: true)
          .snapshots();

      var adminStoriesStream2 = _firebaseFirestore
          .collection('AdminStories')
          .where('userId', whereIn: adminIds) // Filter admin stories by admin user IDs
          .where('expiryTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('uploadTime', descending: true)
          .snapshots();

      // Combine both streams and return the merged list of admin stories
      return Rx.combineLatest2(adminStoriesStream1, adminStoriesStream2,
              (QuerySnapshot snapshot1, QuerySnapshot snapshot2) {
            var combinedStories = <StoryModel>[];

            // Add stories from the first collection
            combinedStories.addAll(
                snapshot1.docs.map((doc) => StoryModel.fromFirestore(doc)));

            // Add stories from the second collection
            combinedStories.addAll(
                snapshot2.docs.map((doc) => StoryModel.fromFirestore(doc)));

            return combinedStories;
          });
    }).asStream().flatMap((stream) => stream); // This converts Future<Stream<List<StoryModel>>> to Stream<List<StoryModel>>
  }

  Future<List<String>> getCategories() async {
    try {
      // Fetch categories from Firestore under 'AdminReels'
      final snapshot = await _firebaseFirestore.collection('AdminReels').get();
      List<String> categories = [];
      for (var doc in snapshot.docs) {
        categories.add(doc.id); // Category name is stored as the document ID
      }
      return categories;
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  Future<void> createCategory(String categoryName) async {
    try {
      // Create a new category sub-collection inside 'AdminReels'
      await _firebaseFirestore.collection('AdminReels').doc(categoryName).set({
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Category created: $categoryName");
    } catch (e) {
      print("Error creating category: $e");
    }
  }



  //Saved Post Method

  Future<void> saveOrUnsavePost(String postId) async {
    String currentUserId = _auth.currentUser!.uid;

    DocumentReference currentUserRef = _firebaseFirestore.collection('users').doc(currentUserId);

    DocumentSnapshot userDoc = await currentUserRef.get();
    List savedPosts = (userDoc.data() as dynamic)['savedPosts'] ?? [];

    try {
      if (savedPosts.contains(postId)) {
        // If the post is already saved, unsave it by removing it from the list
        await currentUserRef.update({
          'savedPosts': FieldValue.arrayRemove([postId]),
        });
      } else {
        // If the post is not saved, save it by adding it to the list
        await currentUserRef.update({
          'savedPosts': FieldValue.arrayUnion([postId]),
        });
      }
    } catch (e) {
      print("Error saving/unsaving post: $e");
    }
  }

  Future<void> startStream(String streamID) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('live_streams').doc(streamID).set({
        'isLive': true,
        'hostId': user.uid,
        'viewers': [],
      });
    }
  }

  Stream<DocumentSnapshot> getStreamStatus(String streamID) {
    return FirebaseFirestore.instance
        .collection('live_streams')
        .doc(streamID)
        .snapshots();
  }



  Future<bool> isPostSaved(String postId) async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentReference currentUserRef = _firebaseFirestore.collection('users').doc(currentUserId);

    DocumentSnapshot userDoc = await currentUserRef.get();
    List savedPosts = (userDoc.data() as dynamic)['savedPosts'] ?? [];

    return savedPosts.contains(postId);
  }

  Future<List<dynamic>> getSavedPosts() async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentReference currentUserRef = _firebaseFirestore.collection('users').doc(currentUserId);

    DocumentSnapshot userDoc = await currentUserRef.get();
    List savedPosts = (userDoc.data() as dynamic)['savedPosts'] ?? [];

    List<dynamic> posts = [];

    for (var postId in savedPosts) {
      var postSnapshot = await _firebaseFirestore.collection('posts').doc(postId).get();
      if (postSnapshot.exists) {
        posts.add(postSnapshot.data());
      }
    }
    return posts;
  }


  Future<void> saveStoryReply({required String storyId, required String replyText}) async {
    try {
      await _firebaseFirestore.collection('stories').doc(storyId).collection('replies').add({
        'replyText': replyText,
        'userId': _auth.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving story reply: $e");
    }
  }
  Future<String> getOrCreateChat({required String userId}) async {
    String currentUserId = _auth.currentUser!.uid;
    String chatId = getChatId(currentUserId, userId);
    DocumentReference chatDoc = _firebaseFirestore.collection('chats').doc(chatId);
    DocumentSnapshot docSnapshot = await chatDoc.get();

    if (!docSnapshot.exists) {
      await chatDoc.set({
        'users': [currentUserId, userId],
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }


  Future<void> sendChatMessage({
    required String chatId,
    required String message,
    required String storyReference,
    String? mediaUrl,
    String? imageUrl,
    String? audioUrl,
    String? sharedPostImageUrl,
    String? replyToMessageId,
    String? replyToContent,
    Map<String, dynamic>? sharedPostData,
  }) async {
    try {
      await _firebaseFirestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': _auth.currentUser!.uid,
        'message': message.isNotEmpty ? message : null,
        'storyReference': storyReference,
        'mediaUrl': mediaUrl,
        'image': imageUrl,
        'audio': audioUrl,
        'sharedPostImageUrl': sharedPostImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'delivered': false,
        'replyToMessageId': replyToMessageId,
        'replyToContent': replyToContent,
        'reactions': {},
        'sharedPost': sharedPostData,
      });

      String notificationBody;
      String titleEnglish;
      String titleFrench;
      String lastMessageContent;

      if (sharedPostData != null) {
        notificationBody = "Shared a post";
        titleEnglish = "Shared a post";
        titleFrench = "A partagé une publication";
        lastMessageContent = "Shared a post";
      } else if (imageUrl != null) {
        notificationBody = "You received an image";
        titleEnglish = "You received an image";
        titleFrench = "Vous avez reçu une image";
        lastMessageContent = "Image";
      } else if (audioUrl != null) {
        notificationBody = "You received an audio message";
        titleEnglish = "You received an audio message";
        titleFrench = "Vous avez reçu un message audio";
        lastMessageContent = "Audio";
      } else if (message.isNotEmpty) {
        notificationBody = message;
        titleEnglish = "New message";
        titleFrench = "Nouveau message";
        lastMessageContent = message;
      } else {
        notificationBody = "New message";
        titleEnglish = "New message";
        titleFrench = "Nouveau message";
        lastMessageContent = "";
      }

      await _firebaseFirestore.collection('chats').doc(chatId).update({
        'lastMessage': lastMessageContent,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });

      String recipientId = chatId.replaceAll(_auth.currentUser!.uid, '').replaceAll('', '');
      Usermodel currentUserData = await getUser(UID: _auth.currentUser!.uid);
      await saveNotification(
        recipientId: recipientId,
        titleEnglish: "${currentUserData.username}: $titleEnglish",
        titleFrench: "${currentUserData.username}: $titleFrench",
        body: notificationBody,
      );
    } catch (e) {
      print("Error sending chat message: $e");
    }
  }



  Future<StoryModel> getStory(String storyId) async {
    DocumentSnapshot storyDoc = await _firebaseFirestore.collection('stories').doc(storyId).get();
    if (storyDoc.exists) {
      return StoryModel.fromFirestore(storyDoc);
    } else {
      throw Exception("Story not found");
    }
  }


  // In firestore.dart, add this method
  Future<void> reportPost({
    required String postId,
    required String reason,
    required String reporterId,
    required String collectionType,
  }) async {
    try {
      await _firebaseFirestore.collection('reported_posts').doc(postId).set({
        'postId': postId,
        'reason': reason,
        'reporterId': reporterId,
        'collectionType': collectionType,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
      }, SetOptions(merge: true));

      // Add to reports subcollection for tracking multiple reports
      await _firebaseFirestore
          .collection('reported_posts')
          .doc(postId)
          .collection('reports')
          .add({
        'reason': reason,
        'reporterId': reporterId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw exceptions("Failed to report post: $e");
    }
  }

// ***** **************************** ******
// ***** method to get reported posts ******
// ***** **************************** ******

  Stream<QuerySnapshot> getReportedPosts({String? filterReason}) {
    if (filterReason != null && filterReason.isNotEmpty) {
      return _firebaseFirestore
          .collection('reported_posts')
          .where('reason', isEqualTo: filterReason)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
    return _firebaseFirestore
        .collection('reported_posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getUserReels(String userId) async {
    try {
      // Fetch the user's role to determine the collection
      Usermodel user = await getUser(UID: userId);
      String collectionName = user.role == 'admin' ? 'AdminReels' : 'reels';

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('uid', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching user reels: $e");
      return [];
    }
  }

  // Add this method to your Firebase_Firestor class
  Stream<QuerySnapshot> getReelComments({required String postId}) {
    return _firebaseFirestore
        .collection('reels')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true) // Sort by timestamp, newest first
        .snapshots();
  }

  Future<void> updatePost({
    required String postId,
    required String caption,
    required String location,
    required String postImage,
    required String collectionName,
  }) async {
    await FirebaseFirestore.instance.collection(collectionName).doc(postId).update({
      'caption': caption,
      'location': location,
      'postImage': postImage,
    });
  }

  Future<List<Map<String, dynamic>>> getSpecificReel(String userId, String reelId) async {
    try {
      // Check 'reels' collection (for non-admin users)
      DocumentSnapshot reelDoc = await _firebaseFirestore
          .collection('reels')
          .doc(reelId)
          .get();

      if (reelDoc.exists) {
        return [{
          'id': reelDoc.id,
          ...reelDoc.data() as Map<String, dynamic>,
          'collectionType': 'reels', // Add collection type for reference
        }];
      }

      // Check 'AdminReels' collection (for admin reels without category)
      DocumentSnapshot adminReelDoc = await _firebaseFirestore
          .collection('AdminReels')
          .doc(reelId)
          .get();

      if (adminReelDoc.exists) {
        return [{
          'id': adminReelDoc.id,
          ...adminReelDoc.data() as Map<String, dynamic>,
          'collectionType': 'AdminReels',
        }];
      }

      // Check 'chapters' collection (for admin reels with categories)
      // Since chapters are nested, we need to query all categories
      QuerySnapshot chaptersSnapshot = await _firebaseFirestore
          .collection('chapters')
          .get();

      for (var chapterDoc in chaptersSnapshot.docs) {
        DocumentSnapshot chapterReelDoc = await _firebaseFirestore
            .collection('chapters')
            .doc(chapterDoc.id)
            .collection('reels')
            .doc(reelId)
            .get();

        if (chapterReelDoc.exists) {
          return [{
            'id': chapterReelDoc.id,
            ...chapterReelDoc.data() as Map<String, dynamic>,
            'collectionType': 'chapters',
            'categoryName': chapterDoc.id, // Include category name
          }];
        }
      }

      // If not found in any collection, return empty list
      print('Reel $reelId not found for user $userId in any collection');
      return [];
    } catch (e) {
      print('Error fetching specific reel: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getReelsFromChapter({
    required String categoryName,
    String? subcategoryId,
  }) async {
    try {
      CollectionReference reelsRef = subcategoryId != null
          ? _firebaseFirestore
          .collection('chapters')
          .doc(categoryName)
          .collection('subcategories')
          .doc(subcategoryId)
          .collection('reels')
          : _firebaseFirestore.collection('chapters').doc(categoryName).collection('reels');

      final QuerySnapshot snapshot = await reelsRef.get();
      List<Map<String, dynamic>> reels = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      print("Fetched ${reels.length} reels from ${reelsRef.path}");
      return reels;
    } catch (e) {
      print("Error fetching reels: $e");
      return [];
    }
  }


  // uploadPdf (updated with order)
  Future<void> uploadPdf({
    required String categoryName,
    String? subcategoryId,
    required String title,
    required String pdfUrl,
  }) async {
    try {
      String pdfId = Uuid().v4();
      CollectionReference<Map<String, dynamic>> targetCollection;
      DocumentReference<Map<String, dynamic>> pdfRef;

      if (subcategoryId != null) {
        targetCollection = _firebaseFirestore
            .collection('chapters')
            .doc(categoryName)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('pdfs');
      } else {
        targetCollection = _firebaseFirestore
            .collection('chapters')
            .doc(categoryName)
            .collection('pdfs');
      }

      QuerySnapshot existingPdfs = await targetCollection.get();
      int order = existingPdfs.docs.length; // Order is the next index
      pdfRef = targetCollection.doc(pdfId);

      await pdfRef.set({
        'id': pdfId,
        'title': title,
        'pdfUrl': pdfUrl,
        'uploadedBy': _auth.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'order': order, // Add order field
      });
      print("PDF uploaded to: ${pdfRef.path} with order $order");
    } catch (e) {
      print("Error uploading PDF: $e");
      throw exceptions("Failed to upload PDF: $e");
    }
  }

  Future<void> updatePdf({
    required String categoryName,
    String? subcategoryId,
    required String pdfId,
    required String title,
    required String pdfUrl,
  }) async {
    try {
      DocumentReference ref = subcategoryId != null
          ? _firebaseFirestore
          .collection('chapters')
          .doc(categoryName)
          .collection('subcategories')
          .doc(subcategoryId)
          .collection('pdfs')
          .doc(pdfId)
          : _firebaseFirestore.collection('chapters').doc(categoryName).collection('pdfs').doc(pdfId);

      await ref.update({
        'title': title,
        'pdfUrl': pdfUrl,
      });
    } catch (e) {
      print("Error updating PDF: $e");
      throw exceptions("Failed to update PDF: $e");
    }
  }

  Future<void> deletePdf({
    required String categoryName,
    required String pdfId,
  }) async {
    try {
      await _firebaseFirestore
          .collection('chapters')
          .doc(categoryName)
          .collection('pdfs')
          .doc(pdfId)
          .delete();
      // Optionally delete from Firebase Storage if needed
      // await FirebaseStorage.instance.refFromURL(pdfUrl).delete();
    } catch (e) {
      print("Error deleting PDF: $e");
      throw exceptions("Failed to delete PDF: $e");
    }
  }

// Fetch PDFs for a category
  Future<List<Map<String, dynamic>>> getPdfsFromCategory({
    required String categoryName,
    String? subcategoryId,
  }) async {
    try {
      CollectionReference pdfsRef = subcategoryId != null
          ? _firebaseFirestore
          .collection('chapters')
          .doc(categoryName)
          .collection('subcategories')
          .doc(subcategoryId)
          .collection('pdfs')
          : _firebaseFirestore.collection('chapters').doc(categoryName).collection('pdfs');

      final snapshot = await pdfsRef.orderBy('timestamp', descending: true).get();
      var fetchedPdfs = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
      print("Fetched ${fetchedPdfs.length} PDFs from: ${pdfsRef.path}");
      return fetchedPdfs;
    } catch (e) {
      print("Error fetching PDFs: $e");
      return [];
    }
  }

// addSubcategory (updated with order)
  Future<void> addSubcategory({
    required String categoryName,
    required String subcategoryName,
  }) async {
    try {
      String subcategoryId = Uuid().v4();
      CollectionReference<Map<String, dynamic>> targetCollection = _firebaseFirestore
          .collection('chapters')
          .doc(categoryName)
          .collection('subcategories');

      QuerySnapshot existingSubcategories = await targetCollection.get();
      int order = existingSubcategories.docs.length; // Order is the next index
      DocumentReference<Map<String, dynamic>> subcategoryRef = targetCollection.doc(subcategoryId);

      await subcategoryRef.set({
        'name': subcategoryName,
        'createdBy': _auth.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'order': order, // Add order field
      });
      print("Subcategory added to: ${subcategoryRef.path} with order $order");
    } catch (e) {
      print("Error adding subcategory: $e");
      throw exceptions("Failed to add subcategory: $e");
    }
  }

// Fetch subcategories for a category
  Future<List<Map<String, dynamic>>> getSubcategoriesFromCategory(String categoryName) async {
    try {
      final snapshot = await _firebaseFirestore
          .collection('chapters')
          .doc(categoryName)
          .collection('subcategories')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id, // Include the document ID
        ...doc.data() as Map<String, dynamic>, // Spread the rest of the data
      }).toList();
    } catch (e) {
      print("Error fetching subcategories: $e");
      return [];
    }
  }

// Delete subcategory
  Future<void> deleteSubcategory({
    required String categoryName,
    required String subcategoryId,
  }) async {
    try {
      await _firebaseFirestore
          .collection('chapters')
          .doc(categoryName)
          .collection('subcategories')
          .doc(subcategoryId)
          .delete();
    } catch (e) {
      print("Error deleting subcategory: $e");
      throw exceptions("Failed to delete subcategory: $e");
    }
  }

  Future<void> updateSubcategory({
    required String categoryName,
    required String subcategoryId,
    required String newName,
  }) async {
    try {
      await _firebaseFirestore
          .collection('chapters')
          .doc(categoryName)
          .collection('subcategories')
          .doc(subcategoryId)
          .update({'name': newName});
    } catch (e) {
      print("Error updating subcategory: $e");
      throw exceptions("Failed to update subcategory: $e");
    }
  }



}
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syndicate/screen/Chats/Forward_Message_BottomSheet.dart';
import 'package:syndicate/screen/message_bubble.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:syndicate/generated/l10n.dart';
import 'package:syndicate/screen/profile_screen.dart';
import '../data/model/story_model.dart';
import '../widgets/story_message_bubble.dart';
import 'package:super_clipboard/super_clipboard.dart';

class ChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;
  final String otherUserProfile;
  final String? initialMessageId;

  const ChatPage({
    required this.otherUserId,
    required this.otherUsername,
    required this.otherUserProfile,
    this.initialMessageId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final Firebase_Firestor firestoreService = Firebase_Firestor();
  final TextEditingController _messageController = TextEditingController();
  String? chatId;
  bool _isTyping = false;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  FlutterSoundRecorder? _audioRecorder;
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _audioFilePath;
  bool _isChatOpen = false;
  String? _currentChatId;

  String? _replyToMessageId;
  String? _replyToContent;
  bool _showEmojiPicker = false;

  String? currentUserProfile;

  Set<String> _selectedMessageIds = {};
  bool _isMultiSelectMode = false;
  bool _isSelecting = false;

  List<String> _knownMessageIds = [];
  String? _targetMessageId; // Track the message to highlight
  bool _highlightTargetMessage = false;

  bool _isAtBottom = true; // New variable to track if user is at the bottom

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _focusNode.addListener(() {
      setState(() {});
    });

    _targetMessageId = widget.initialMessageId;
    if (_targetMessageId != null) {
      _highlightTargetMessage = true; // Start with highlight enabled
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeChat();
      if (chatId != null) {
        await markMessagesAsDeliveredAndRead(chatId!);
        if (_targetMessageId != null) {
          await _scrollToTargetMessage(_targetMessageId!);
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
          _scrollToBottom();
        }
      }
    });

    // Debounced scroll listener
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        final threshold = 50.0;
        final atBottom = (maxScroll - currentScroll).abs() <= threshold;
        if (atBottom != _isAtBottom) {
          setState(() {
            _isAtBottom = atBottom;
          });
        }
      }
    });

    _initializeRecorder();
    _initializeNotifications();
    _isChatOpen = true;
    _currentChatId = chatId;
  }

  Future<void> _copySelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    // Check if clipboard is supported on this platform
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(S.of(context).clipboardNotSupported)),
      );
      return;
    }

    List<String> messagesToCopy = [];
    QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where(FieldPath.documentId, whereIn: _selectedMessageIds.toList())
        .get();

    for (var doc in messagesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String? messageContent = data['message'];
      if (messageContent != null && messageContent.isNotEmpty) {
        messagesToCopy.add(messageContent);
      }
    }

    if (messagesToCopy.isNotEmpty) {
      String textToCopy = messagesToCopy.join('\n');

      // Create a DataWriterItem for the clipboard
      final item = DataWriterItem();
      item.add(Formats.plainText(textToCopy)); // Add plain text format

      // Write to clipboard
      await clipboard.write([item]);

      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(S.of(context).messagesCopied)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(S.of(context).noTextMessagesToCopy)),
      );
    }
  }

  Future<void> _showForwardOptions() async {
    if (_selectedMessageIds.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows custom height control
      builder: (context) => ForwardMessagesBottomSheet(
        selectedMessageIds: _selectedMessageIds,
        firestoreService: firestoreService,
        currentChatId: chatId!,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
      ),
    ).then((value) {
      // After the bottom sheet closes, reset multi-select mode if needed
      setState(() {
        _selectedMessageIds.clear();
        _isMultiSelectMode = false;
        _isSelecting = false;
      });
    });
  }

  Future<void> _cancelRecording() async {
    if (!_isRecorderInitialized || !_isRecording) return;
    await _audioRecorder!.stopRecorder();
    if (_audioFilePath != null) {
      File audioFile = File(_audioFilePath!);
      if (await audioFile.exists()) {
        await audioFile.delete(); // Delete the temporary file
      }
    }
    setState(() {
      _isRecording = false;
      _audioFilePath = null;
    });
  }

  Future<void> _scrollToTargetMessage(String messageId) async {
    if (!mounted || !_scrollController.hasClients) {
      print("ScrollController not ready yet, retrying after delay"); // Debug
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || !_scrollController.hasClients) return;
    }

    // Fetch messages and ensure the target message is included
    final messagesSnapshot = await firestoreService.getMessages(chatId!).first;
    final messages = messagesSnapshot.docs.where((msg) {
      var data = msg.data() as Map<String, dynamic>;
      List<dynamic> deletedFor = data['deletedFor'] ?? [];
      return !deletedFor.contains(firestoreService.currentUserId);
    }).toList();

    int targetIndex = messages.indexWhere((msg) => msg.id == messageId);
    if (targetIndex == -1) {
      print("Message $messageId not found in initial load"); // Debug
      return;
    }

    print("Found message $messageId at index $targetIndex"); // Debug

    // Wait for the ListView to be fully built
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_scrollController.hasClients) return;

    // Calculate screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top; // AppBar + status bar
    final inputFieldHeight = 800.0; // Approximate height of _buildMessageInput (adjust if needed)
    final availableHeight = screenHeight - appBarHeight - inputFieldHeight; // Visible chat area

    // Estimate message height (adjust based on your MessageBubble height)
    const double estimatedMessageHeight = 200.0;
    double estimatedPosition = targetIndex * estimatedMessageHeight;

    // Center the message in the visible area
    double centeredPosition = estimatedPosition - (availableHeight / 2) + (estimatedMessageHeight / 2);
    double maxScroll = _scrollController.position.maxScrollExtent;

    // Clamp the position to ensure it’s within bounds
    double finalPosition = centeredPosition.clamp(0.0, maxScroll);

    // If it’s the last message, ensure it’s not hidden under the input field
    if (targetIndex == messages.length - 1) {
      finalPosition = maxScroll; // Scroll to the bottom for the last message
    }

    print("Screen height: $screenHeight, Available height: $availableHeight, Final position: $finalPosition"); // Debug

    await _scrollController.animateTo(
      finalPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    // Highlight the message for 1.5 seconds
    setState(() {
      _highlightTargetMessage = true;
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _highlightTargetMessage = false;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    await _firebaseMessaging.requestPermission();
  }

  Future<void> _sendPushNotification(String message) async {
    try {
      DocumentSnapshot recipientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      String? recipientToken = recipientDoc['fcmToken'];
      if (recipientToken != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'to': recipientToken,
          'notification': {
            'title': widget.otherUsername,
            'body': message,
          },
          'data': {'chatId': chatId},
        });
      }
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }

  Future<void> _initializeRecorder() async {
    if (_isRecorderInitialized) return; // Prevent reinitialization
    print("Requesting microphone permission...");
    final status = await Permission.microphone.request();
    print("Microphone permission status: $status");
    if (status == PermissionStatus.granted) {
      try {
        _audioRecorder ??= FlutterSoundRecorder(); // Initialize only if null
        await _audioRecorder!.openRecorder();
        _isRecorderInitialized = true;
        setState(() {});
      } catch (e) {
        print("Error initializing recorder: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing audio recorder: $e")),
        );
      }
    } else if (status == PermissionStatus.permanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("microphonePermissionPermanentlyDenied"),
          action: SnackBarAction(
            label: "openSettings",
            onPressed: () async {
              await openAppSettings();
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).microphonePermissionDenied)),
      );
    }
  }

  Future<void> _startRecording() async {
    await _initializeRecorder(); // Initialize recorder here
    if (!_isRecorderInitialized) return;
    Directory tempDir = await getTemporaryDirectory();
    String path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    await _audioRecorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
    setState(() {
      _isRecording = true;
      _audioFilePath = path;
    });
  }

  void _setReply(String messageId, String messageContent) {
    setState(() {
      _replyToMessageId = messageId;
      _replyToContent = messageContent;
    });
  }

  void _clearReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToContent = null;
    });
  }

  Future<void> _initializeChat() async {
    String id = await firestoreService.createChat(widget.otherUserId);
    setState(() {
      chatId = id;
    });
    firestoreService.markChatAsRead(chatId!);
    try {
      var currentUser = await firestoreService.getUser();
      setState(() {
        currentUserProfile = currentUser.profile;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user profile: $e")),
      );
    }
  }


  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_isRecorderInitialized) {
      _audioRecorder?.closeRecorder();
    }
    _audioRecorder = null;
    _focusNode.dispose();
    _isChatOpen = false;
    _currentChatId = null;
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null && chatId != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
          const Center(child: CircularProgressIndicator()),
        );
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images/$chatId/$fileName');
        UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        await firestoreService.sendMessage(
          chatId!,
          '',
          imageUrl: downloadUrl,
          replyToMessageId: _replyToMessageId,
          replyToContent: _replyToContent,
        );
        Navigator.pop(context);
        _clearReply();
        _scrollToBottom();
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending image: $e")),
      );
    }
  }

  void _sendMessage() {
    String msg = _messageController.text.trim();
    if (msg.isNotEmpty && chatId != null) {
      _messageController.clear();
      setState(() {
        _isTyping = false;
      });
      firestoreService
          .sendMessage(
        chatId!,
        msg,
        replyToMessageId: _replyToMessageId,
        replyToContent: _replyToContent,
      )
          .then((_) {
        _clearReply();
        _scrollToBottom();
        _sendPushNotification(msg);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending message: $error")),
        );
      });
    }
  }

  Future<void> _showDeleteOptions() async {
    if (_selectedMessageIds.isEmpty) return;
    bool allOwnedByMe = await _checkIfAllSelectedAreMine();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              S.of(context).deleteMessages,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14
              ),
            ),
          ],
        ),

        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          // Delete for Me Button
          TextButton.icon(
            onPressed: () async {
              try {
                for (String messageId in _selectedMessageIds) {
                  await firestoreService.deleteMessageForMe(chatId!, messageId);
                }
                setState(() {
                  _selectedMessageIds.clear();
                  _isMultiSelectMode = false;
                  _isSelecting = false;
                });
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error deleting messages: $e"),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            icon: Icon(
              Icons.person_off_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              S.of(context).deleteForMe,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Delete for Everyone Button (Conditional)
          if (allOwnedByMe)
            TextButton.icon(
              onPressed: () async {
                try {
                  for (String messageId in _selectedMessageIds) {
                    await firestoreService.deleteMessageForEveryone(chatId!, messageId);
                  }
                  setState(() {
                    _selectedMessageIds.clear();
                    _isMultiSelectMode = false;
                    _isSelecting = false;
                  });
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error deleting messages: $e"),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.group_off_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                S.of(context).deleteForEveryone,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          // Cancel Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              S.of(context).cancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      )
    );
  }

  Future<bool> _checkIfAllSelectedAreMine() async {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;
    for (String messageId in _selectedMessageIds) {
      DocumentSnapshot msg = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();
      if (msg['senderId'] != currentUid) return false;
    }
    return true;
  }

  Future<void> markMessagesAsDeliveredAndRead(String chatId) async {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;
    String otherUid = widget.otherUserId;
    QuerySnapshot messagesToMark = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: otherUid)
        .get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in messagesToMark.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (!(data['delivered'] == true) || !(data['read'] == true)) {
        batch.update(doc.reference, {'delivered': true, 'read': true});
      }
    }
    await batch.commit();
  }

  // Future<void> _startRecording() async {
  //   if (!_isRecorderInitialized) return;
  //   Directory tempDir = await getTemporaryDirectory();
  //   String path =
  //       '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
  //   await _audioRecorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
  //   setState(() {
  //     _isRecording = true;
  //     _audioFilePath = path;
  //   });
  // }

  Future<void> _stopRecording() async {
    if (!_isRecorderInitialized) return;
    await _audioRecorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (_audioFilePath != null && chatId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.aac';
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_audio/$chatId/$fileName');
        UploadTask uploadTask = storageRef.putFile(File(_audioFilePath!));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        await firestoreService.sendMessage(
          chatId!,
          '',
          audioUrl: downloadUrl,
          replyToMessageId: _replyToMessageId,
          replyToContent: _replyToContent,
        );
        Navigator.pop(context);
        _clearReply();
        _scrollToBottom();
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending voice message: $e")),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (chatId == null || currentUserProfile == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(widget.otherUsername)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: _isMultiSelectMode
            ? Text("${_selectedMessageIds.length} selected")
            : Row(
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to ProfileScreen with the otherUserId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(Uid: widget.otherUserId),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.otherUserProfile),
                radius: 16,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                GestureDetector(
                    onTap: () {
                      // Navigate to ProfileScreen with the otherUserId
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(Uid: widget.otherUserId),
                        ),
                      );
                    },

                    child:  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.otherUsername,
                              style: const TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          Text(
                            S.of(context).syndicateUser,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color),
                          ),
                        ]
                    )
                )
              ],
            ),
          ],
        ),
        actions: [
          if (_isMultiSelectMode)...[
            IconButton(
              icon: const Icon(Icons.delete_outline_outlined),
              onPressed: _showDeleteOptions,

            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copySelectedMessages,
              tooltip: S.of(context).copySelectedMessages,
            ),
            IconButton(
              icon: const Icon(Icons.forward_outlined),
              onPressed: _showForwardOptions, // New method for forward action
              tooltip: S.of(context).forwardSelectedMessages,
            ),
          ]
        ],
      ),
      body: Stack(
        children: [
          // Existing chat content
          Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'images/icons/pattern3.svg',
                    fit: BoxFit.cover,
                    color: theme.progressIndicatorTheme.color!.withOpacity(0.4),
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: firestoreService.getMessages(chatId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final messages = snapshot.data!.docs.where((msg) {
                          var data = msg.data() as Map<String, dynamic>;
                          List<dynamic> deletedFor = data['deletedFor'] ?? [];
                          return !deletedFor.contains(firestoreService.currentUserId);
                        }).toList();

                        messages.sort((a, b) {
                          Timestamp aTimestamp = a['timestamp'] ?? Timestamp.now();
                          Timestamp bTimestamp = b['timestamp'] ?? Timestamp.now();
                          return aTimestamp.compareTo(bTimestamp);
                        });

                        List<String> currentMessageIds = messages.map((msg) => msg.id).toList();
                        bool newMessageAdded = snapshot.data!.docChanges.any(
                              (change) =>
                          change.type == DocumentChangeType.added &&
                              change.doc['senderId'] != firestoreService.currentUserId &&
                              !_knownMessageIds.contains(change.doc.id),
                        );

                        if (newMessageAdded && !_isSelecting) {
                          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                          for (var change in snapshot.data!.docChanges) {
                            if (change.type == DocumentChangeType.added &&
                                change.doc['senderId'] != firestoreService.currentUserId &&
                                (!(change.doc['delivered'] == true) || !(change.doc['read'] == true))) {
                              change.doc.reference.update({'delivered': true, 'read': true});
                            }
                          }
                        }
                        _knownMessageIds = currentMessageIds;

                        List<Widget> messageWidgets = [];
                        DateTime? previousDate;

                        for (int i = 0; i < messages.length; i++) {
                          var msg = messages[i];
                          var docData = msg.data() as Map<String, dynamic>;
                          Timestamp timestamp = docData['timestamp'] ?? Timestamp.now();
                          DateTime messageDate = timestamp.toDate();
                          DateTime messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);

                          if (previousDate == null || !isSameDay(previousDate, messageDay)) {
                            messageWidgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatDate(messageDay),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                            previousDate = messageDay;
                          }

                          bool isMe = msg['senderId'] == firestoreService.currentUserId;
                          bool shouldHighlight = _highlightTargetMessage && _targetMessageId == msg.id;

                          String? messageContent = msg['message'];
                          String? imageUrl = msg['image'];
                          String? audioUrl = msg['audio'];
                          bool isRead = msg['read'] ?? false;
                          bool isDelivered = msg['delivered'] ?? false;
                          String? storyReference = docData.containsKey('storyReference') ? docData['storyReference'] as String? : null;
                          String? mediaUrl = docData.containsKey('mediaUrl') ? docData['mediaUrl'] as String? : null;
                          Map<String, dynamic>? sharedPostData = docData['sharedPost'];
                          Map<String, dynamic> reactions = {};
                          final data = msg.data() as Map<String, dynamic>?;
                          if (data != null && data.containsKey('reactions')) {
                            reactions = Map<String, dynamic>.from(data['reactions']);
                          }

                          Widget messageWidget;
                          if (storyReference != null) {
                            messageWidget = StoryMessageBubble(
                              isMe: isMe,
                              message: messageContent ?? '',
                              timestamp: timestamp,
                              isRead: isRead,
                              isDelivered: isDelivered,
                              profileImage: isMe ? currentUserProfile! : widget.otherUserProfile,
                              storyReference: storyReference,
                              mediaUrl: mediaUrl,
                            );
                          } else if (sharedPostData != null) {
                            messageWidget = MessageBubble(
                              key: ValueKey(msg.id),
                              isMe: isMe,
                              sharedPost: sharedPostData,
                              message: messageContent,
                              imageUrl: imageUrl,
                              audioUrl: audioUrl,
                              timestamp: timestamp,
                              isRead: isRead,
                              isDelivered: isDelivered,
                              profileImage: isMe ? currentUserProfile! : widget.otherUserProfile,
                              onSwipeReply: _setReply,
                              messageId: msg.id,
                              replyToContent: msg['replyToContent'],
                              reactions: reactions,
                              onReact: (messageId, reaction) {
                                firestoreService.addOrUpdateReaction(
                                  chatId: chatId!,
                                  messageId: messageId,
                                  userId: firestoreService.currentUserId,
                                  reaction: reaction,
                                );
                              },
                              isSelected: _selectedMessageIds.contains(msg.id),
                              onToggleSelection: (messageId) {
                                setState(() {
                                  _isSelecting = true;
                                  if (_selectedMessageIds.contains(messageId)) {
                                    _selectedMessageIds.remove(messageId);
                                    if (_selectedMessageIds.isEmpty) {
                                      _isMultiSelectMode = false;
                                      _isSelecting = false;
                                    }
                                  } else {
                                    _selectedMessageIds.add(messageId);
                                    _isMultiSelectMode = true;
                                  }
                                });
                              },
                              isMultiSelectMode: _isMultiSelectMode,
                              shouldHighlight: shouldHighlight,
                            );
                          } else if (messageContent != null || imageUrl != null || audioUrl != null) {
                            messageWidget = MessageBubble(
                              key: ValueKey(msg.id),
                              isMe: isMe,
                              message: messageContent,
                              imageUrl: imageUrl,
                              audioUrl: audioUrl,
                              timestamp: timestamp,
                              isRead: isRead,
                              isDelivered: isDelivered,
                              profileImage: isMe ? currentUserProfile! : widget.otherUserProfile,
                              onSwipeReply: _setReply,
                              messageId: msg.id,
                              replyToContent: msg['replyToContent'],
                              reactions: reactions,
                              onReact: (messageId, reaction) {
                                firestoreService.addOrUpdateReaction(
                                  chatId: chatId!,
                                  messageId: messageId,
                                  userId: firestoreService.currentUserId,
                                  reaction: reaction,
                                );
                              },
                              isSelected: _selectedMessageIds.contains(msg.id),
                              onToggleSelection: (messageId) {
                                setState(() {
                                  _isSelecting = true;
                                  if (_selectedMessageIds.contains(messageId)) {
                                    _selectedMessageIds.remove(messageId);
                                    if (_selectedMessageIds.isEmpty) {
                                      _isMultiSelectMode = false;
                                      _isSelecting = false;
                                    }
                                  } else {
                                    _selectedMessageIds.add(messageId);
                                    _isMultiSelectMode = true;
                                  }
                                });
                              },
                              isMultiSelectMode: _isMultiSelectMode,
                              shouldHighlight: shouldHighlight,
                            );
                          } else {
                            messageWidget = const SizedBox.shrink();
                          }

                          messageWidgets.add(messageWidget);
                        }

                        return ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(10),
                          children: messageWidgets,
                        );
                      },
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
            ],
          ),
          if (!_isAtBottom)
            Positioned(
              right: 16,
              bottom: 80,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xffe0993d),
                onPressed: _scrollToBottom,
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToContent != null) _buildReplyPreview(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                        if (_showEmojiPicker) {
                          FocusScope.of(context).unfocus();
                        } else {
                          FocusScope.of(context).requestFocus(_focusNode);
                        }
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.emoji_emotions_outlined,
                          color: Color(0xffe0993d), size: 25),
                    ),
                  ),
                  if (!_isTyping && !_isRecording) ...[
                    GestureDetector(
                      onTap: _pickAndSendImage,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.photo_outlined,
                            color: Color(0xffe0993d), size: 25),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickAndSendFromCamera,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.camera_alt_outlined,
                            color: Color(0xffe0993d), size: 25),
                      ),
                    ),
                  ],
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "Message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isTyping = value.isNotEmpty;
                        });
                      },
                      onTap: () {
                        if (_showEmojiPicker) {
                          setState(() {
                            _showEmojiPicker = false;
                          });
                        }
                      },
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                  if (_isRecording) ...[
                    GestureDetector(
                      onTap: _cancelRecording,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.close, color: Colors.grey, size: 25),
                      ),
                    ),
                    GestureDetector(
                      onTap: _stopRecording,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.send, color: Color(0xffe0993d), size: 25),
                      ),
                    ),
                  ] else ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isTyping
                          ? GestureDetector(
                        onTap: _sendMessage,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.send,
                              color: Color(0xffe0993d), size: 23),
                        ),
                      )
                          : GestureDetector(
                        onTap: _toggleRecording,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.mic_outlined,
                              color: Color(0xffe0993d), size: 25),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    _messageController.text += emoji.emoji;
                    _isTyping = _messageController.text.isNotEmpty;
                  });
                },
                onBackspacePressed: () {
                  setState(() {
                    if (_messageController.text.isNotEmpty) {
                      _messageController.text = _messageController.text
                          .substring(0, _messageController.text.length - 1);
                      _isTyping = _messageController.text.isNotEmpty;
                    }
                  });
                },
                config: const Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(),
                  viewOrderConfig: ViewOrderConfig(
                    top: EmojiPickerItem.categoryBar,
                    middle: EmojiPickerItem.emojiView,
                    bottom: EmojiPickerItem.searchBar,
                  ),
                  skinToneConfig: SkinToneConfig(),
                  categoryViewConfig: CategoryViewConfig(),
                  bottomActionBarConfig: BottomActionBarConfig(),
                  searchViewConfig: SearchViewConfig(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendFromCamera() async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (pickedFile != null && chatId != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
          const Center(child: CircularProgressIndicator()),
        );
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images/$chatId/$fileName');
        UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        await firestoreService.sendMessage(
          chatId!,
          '',
          imageUrl: downloadUrl,
          replyToMessageId: _replyToMessageId,
          replyToContent: _replyToContent,
        );
        Navigator.pop(context);
        _clearReply();
        _scrollToBottom();
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending image: $e")),
      );
    }
  }

  Widget _buildReplyPreview() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).replyingTo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _replyToContent!,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: _clearReply,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (isSameDay(messageDate, today)) {
      return "Today";
    } else if (isSameDay(messageDate, yesterday)) {
      return "Yesterday";
    } else {
      return DateFormat('MMMM d, yyyy').format(date); // e.g., "March 5, 2025"
    }
  }
}
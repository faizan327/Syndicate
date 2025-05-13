import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/generated/l10n.dart';

class ForwardMessagesBottomSheet extends StatefulWidget {
  final Set<String> selectedMessageIds;
  final Firebase_Firestor firestoreService;
  final String currentChatId;

  const ForwardMessagesBottomSheet({
    Key? key,
    required this.selectedMessageIds,
    required this.firestoreService,
    required this.currentChatId,
  }) : super(key: key);

  @override
  State<ForwardMessagesBottomSheet> createState() => _ForwardMessagesBottomSheetState();
}

class _ForwardMessagesBottomSheetState extends State<ForwardMessagesBottomSheet> {
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = true;
  final Set<String> _selectedChatIds = {};

  @override
  void initState() {
    super.initState();
    _fetchUserChats();
  }

  Future<void> _fetchUserChats() async {
    setState(() {
      _isLoading = true;
    });

    final currentUid = widget.firestoreService.currentUserId;
    QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUid)
        .get();

    List<Map<String, dynamic>> tempList = [];
    for (var chatDoc in chatSnapshot.docs) {
      if (chatDoc.id == widget.currentChatId) continue;

      List<dynamic> users = chatDoc['users'] ?? [];
      String? otherUserId = users.firstWhere(
            (uid) => uid != currentUid,
        orElse: () => null,
      );

      if (otherUserId == null) continue;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (userDoc.exists) {
        tempList.add({
          'chatId': chatDoc.id,
          'username': userDoc['username'],
          'profile': userDoc['profile'],
        });
      }
    }

    setState(() {
      _chatList = tempList;
      _isLoading = false;
    });
  }

  Future<void> _forwardMessagesToSelectedChats() async {
    if (_selectedChatIds.isEmpty) return;

    // Store the ScaffoldMessengerState before closing the bottom sheet
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    // Close the bottom sheet immediately
    Navigator.pop(context);

    // Show initial SnackBar with progress indicator
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text("sending Messages"),
          ],
        ),
        duration: const Duration(days: 1), // Keep open until updated
      ),
    );

    try {
      QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.currentChatId)
          .collection('messages')
          .where(FieldPath.documentId, whereIn: widget.selectedMessageIds.toList())
          .get();

      for (String chatId in _selectedChatIds) {
        for (var msgDoc in messagesSnapshot.docs) {
          var data = msgDoc.data() as Map<String, dynamic>;
          await widget.firestoreService.sendMessage(
            chatId,
            data['message'] ?? '',
            imageUrl: data['image'],
            audioUrl: data['audio'],
            sharedPostData: data['sharedPost'] != null
                ? Map<String, dynamic>.from(data['sharedPost'])
                : null,
          );
        }
      }

      // Hide the progress SnackBar and show success message
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("messages Forwarded Successfully"),
          backgroundColor: theme.colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Hide the progress SnackBar and show error message
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("{error Forwarding Messages}: $e"),
          backgroundColor: theme.colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Scaffold(
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "forward Messages",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: _isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  )
                      : _chatList.isEmpty
                      ? Center(
                    child: Text(
                      S.of(context).noChatsYet,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _chatList.length,
                    itemBuilder: (context, index) {
                      final chatData = _chatList[index];
                      final chatId = chatData['chatId'];
                      final isSelected = _selectedChatIds.contains(chatId);

                      return _AnimatedProfileAvatar(
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedChatIds.remove(chatId);
                            } else {
                              _selectedChatIds.add(chatId);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipOval(
                                    child: Image.network(
                                      chatData['profile'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.surface,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                  (loadingProgress.expectedTotalBytes ?? 1)
                                                  : null,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  theme.colorScheme.primary),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.surface,
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            color: theme.colorScheme.onSurface,
                                            size: 30,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (isSelected)
                                    ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withOpacity(0.3),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.check_circle,
                                              color: theme.colorScheme.onPrimary,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chatData['username'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(theme.colorScheme.primary),
                      foregroundColor: MaterialStateProperty.all(theme.colorScheme.onPrimary),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    onPressed: _selectedChatIds.isEmpty ? null : _forwardMessagesToSelectedChats,
                    child: Text(S.of(context).send, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedProfileAvatar extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedProfileAvatar({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  State<_AnimatedProfileAvatar> createState() => _AnimatedProfileAvatarState();
}

class _AnimatedProfileAvatarState extends State<_AnimatedProfileAvatar> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.isSelected ? 'Deselect chat' : 'Select chat',
      child: InkWell(
        onTapDown: (_) => setState(() => _scale = 0.95),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        borderRadius: BorderRadius.circular(30),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 200),
          child: widget.child,
        ),
      ),
    );
  }
}
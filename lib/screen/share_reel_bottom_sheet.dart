import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/generated/l10n.dart';

class ShareReelBottomSheet extends StatefulWidget {
  final Map<String, dynamic> reelData;
  const ShareReelBottomSheet({Key? key, required this.reelData})
      : super(key: key);

  @override
  _ShareReelBottomSheetState createState() => _ShareReelBottomSheetState();
}

class _ShareReelBottomSheetState extends State<ShareReelBottomSheet> {
  List<Map<String, dynamic>> followingUsers = [];
  Set<String> selectedUserIds = {};
  bool isLoading = false;

  final Firebase_Firestor _firestoreService = Firebase_Firestor();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchFollowingUsers();
  }

  Future<void> fetchFollowingUsers() async {
    setState(() {
      isLoading = true;
    });
    try {
      String currentUserId = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      List<dynamic> following = userDoc.get('following');
      List<Map<String, dynamic>> users = [];
      for (String uid in following) {
        DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          users.add({
            'uid': uid,
            'username': doc.get('username'),
            'profile': doc.get('profile'),
          });
        }
      }
      setState(() {
        followingUsers = users;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching users: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addToStory() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adding to your story...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      String collectionName = 'stories';
      final currentUser = await _firestoreService.getUser();
      if (currentUser.role == 'admin') {
        collectionName = 'AdminStories';
      }

      bool success = await _firestoreService.addStory(
        mediaUrl: widget.reelData['reelsvideo'],
        mediaType: 'video',
        collectionName: collectionName,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        await ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reel added to your story!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: Duration(seconds: 2),
          ),
        ).closed;

        Navigator.of(context).pop();
      } else {
        await ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to story.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: Duration(seconds: 2),
          ),
        ).closed;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      await ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: Duration(seconds: 2),
        ),
      ).closed;
    }
  }

  Future<void> handleShare() async {
    if (selectedUserIds.isEmpty) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sharing reel...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      for (String uid in selectedUserIds) {
        String chatId = await _firestoreService.createChat(uid);

        Map<String, dynamic> sharedReelData = {
          'reelsvideo': widget.reelData['reelsvideo'],
          'thumbnail': widget.reelData['thumbnail'],
          'caption': widget.reelData['caption'],
          'username': widget.reelData['username'],
          'profileImage': widget.reelData['profileImage'],
          'uid': widget.reelData['uid'],
          'postId': widget.reelData['postId'],
        };

        await _firestoreService.sendMessage(chatId, "",
            sharedPostData: sharedReelData);
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      await ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reel shared successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: Duration(seconds: 2),
        ),
      ).closed;

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      await ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing reel: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: Duration(seconds: 2),
        ),
      ).closed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20), // Matched with ShareBottomSheet
          topRight: Radius.circular(20),
        ),
        child: Scaffold(
          body: Container(
            height: 400, // Fixed height to match ShareBottomSheet
            padding: const EdgeInsets.all(16), // Consistent padding
            child: Column(
              children: [
                Text(
                  'Share Reel',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Matched with ShareBottomSheet
                  ),
                ),
                const SizedBox(height: 16),
                _AnimatedButton(
                  onTap: addToStory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(100), // Fully rounded
                      border: Border.all(color: theme.dividerColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle,
                          color: theme.colorScheme.onPrimary,
                          size: 30, // Matched with ShareBottomSheet
                        ),
                        const SizedBox(width: 12),
                        Text(
                          S.of(context).addToStory,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Matched with ShareBottomSheet
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100, // Matched with ShareBottomSheet
                  child: isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary),
                    ),
                  )
                      : followingUsers.isEmpty
                      ? Center(
                    child: Text(
                      'No users to share with.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: followingUsers.length,
                    itemBuilder: (context, index) {
                      final user = followingUsers[index];
                      final isSelected =
                      selectedUserIds.contains(user['uid']);

                      return _AnimatedProfileAvatar(
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedUserIds.remove(user['uid']);
                            } else {
                              selectedUserIds.add(user['uid']);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipOval(
                                    child: Image.network(
                                      user['profile'] ?? '',
                                      width: 60, // Matched with ShareBottomSheet
                                      height: 60,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child,
                                          loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme
                                                .colorScheme.surface,
                                          ),
                                          child: Center(
                                            child:
                                            CircularProgressIndicator(
                                              value: loadingProgress
                                                  .expectedTotalBytes !=
                                                  null
                                                  ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                      .expectedTotalBytes ??
                                                      1)
                                                  : null,
                                              valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(
                                                theme.colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error,
                                          stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme
                                                .colorScheme.surface,
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            color: theme.colorScheme
                                                .onSurface,
                                            size: 30,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (isSelected)
                                    ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 3, sigmaY: 3),
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black
                                                .withOpacity(0.3),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.check_circle,
                                              color: theme.colorScheme
                                                  .onPrimary,
                                              size: 30, // Matched with ShareBottomSheet
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['username'] ?? '',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  color:
                                  theme.textTheme.bodySmall?.color,
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
                const Spacer(), // Added to push the button to the bottom
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          theme.colorScheme.primary),
                      foregroundColor: MaterialStateProperty.all(
                          theme.colorScheme.onPrimary),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    onPressed: selectedUserIds.isNotEmpty ? handleShare : null,
                    child: Text(
                      S.of(context).send,
                      style: TextStyle(color: Colors.white),
                    ),
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

// Custom widget for animated button
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedButton({required this.onTap, required this.child});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add to Story',
      child: InkWell(
        onTapDown: (_) => setState(() => _scale = 0.95),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        borderRadius: BorderRadius.circular(50),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 200),
          child: widget.child,
        ),
      ),
    );
  }
}

// Custom widget for animated profile avatar
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
      label: widget.isSelected ? 'Deselect user' : 'Select user',
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
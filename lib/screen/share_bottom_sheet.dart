import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/generated/l10n.dart';

class ShareBottomSheet extends StatefulWidget {
  final dynamic postSnapshot;
  const ShareBottomSheet({Key? key, required this.postSnapshot})
      : super(key: key);

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final Firebase_Firestor _firestoreService = Firebase_Firestor();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _followingUsers = [];
  bool _isLoading = true; // Track loading state

  /// A set of selected userIds for multi-select
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _fetchFollowingUsers();

  }

  Future<void> _addToStory() async {
    try {
      // Show a loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(S.of(context).addToStory),
            ],
          ),
          duration: Duration(seconds: 10), // Long enough for the operation
        ),
      );

      // Determine the collection based on user role
      String collectionName = 'stories';
      final currentUser = await _firestoreService.getUser();
      if (currentUser.role == 'admin') {
        collectionName = 'AdminStories';
      }

      // Add the story
      bool success = await _firestoreService.addStory(
        mediaUrl: widget.postSnapshot['postImage'],
        mediaType: 'image',
        collectionName: collectionName,
      );

      // Hide the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        // Show success snackbar and delay closing the bottom sheet
        await ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post added to your story!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: Duration(seconds: 2), // Duration the snackbar is visible
          ),
        ).closed; // Wait for the snackbar to close

        // Close the bottom sheet after the snackbar is dismissed
        Navigator.of(context).pop();
      } else {
        // Show failure snackbar and delay closing
        await ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to story.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: Duration(seconds: 2),
          ),
        ).closed;

        // Optionally, keep the bottom sheet open for retry
      }
    } catch (e) {
      // Hide the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error snackbar and delay closing
      await ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: Duration(seconds: 2),
        ),
      ).closed;

      // Optionally, keep the bottom sheet open for retry
    }
  }

  Future<void> _fetchFollowingUsers() async {
    setState(() {
      _isLoading = true;
    });
    final currentUid = _auth.currentUser!.uid;
    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .get();

    List following = currentUserDoc['following']; // List of user IDs

    List<Map<String, dynamic>> tempList = [];
    for (String userId in following) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        tempList.add({
          'uid': userId,
          'username': userDoc['username'],
          'profile': userDoc['profile'],
        });
      }
    }
    setState(() {
      _followingUsers = tempList;
      _isLoading = false;
    });
  }

  /// Called once user taps "Send" button
  /// Shares the post with all selected users
  Future<void> _sharePostToAllSelected() async {
    // Build the sharedPostData once
    final sharedPostData = {
      'postId': widget.postSnapshot['postId'],
      'postImage': widget.postSnapshot['postImage'],
      'postOwnerUid': widget.postSnapshot['uid'],
      'postOwnerUsername': widget.postSnapshot['username'],
      'postOwnerProfileImage': widget.postSnapshot['profileImage'],
      'caption': widget.postSnapshot['caption'],
      'location': widget.postSnapshot['location'],
    };

    // For each selected user ID, create chat and send message
    for (String otherUserId in _selectedUserIds) {
      final chatId = await _firestoreService.createChat(otherUserId);
      await _firestoreService.sendMessage(
        chatId,
        '',
        sharedPostData: sharedPostData,
      );
    }

    // Close bottom sheet
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      // Removed explicit color to use theme background
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Scaffold(
          // Removed explicit backgroundColor to use theme background
          body: Container(
            height: 400, // Some fixed height for the bottom sheet
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Share Post',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                  ), // Use theme headline style
                ),
                const SizedBox(height: 16),
                // Redesigned "Add to Story" button with scale animation
                _AnimatedButton(
                  onTap: _addToStory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary, // Use theme primary color
                      borderRadius: BorderRadius.circular(100), // Fully rounded corners
                      border: Border.all(color: theme.dividerColor, width: 2), // Use theme divider color
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
                          color: theme.colorScheme.onPrimary, // Use theme onPrimary color
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          S.of(context).addToStory,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Use theme onPrimary color
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Added spacing between button and profiles
                Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.5), // Subtle divider
                ),
                const SizedBox(height: 16), // Added spacing after divider
                // Horizontal scrolling user list
                SizedBox(
                  height: 100, // Height for the horizontal list
                  child: _isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  )
                      : _followingUsers.isEmpty
                      ? Center(
                    child: Text(
                      'No users to share with.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal, // Horizontal scrolling
                    itemCount: _followingUsers.length,
                    itemBuilder: (context, index) {
                      final userData = _followingUsers[index];
                      final userId = userData['uid'];

                      // Check if user is selected
                      final isSelected = _selectedUserIds.contains(userId);

                      return _AnimatedProfileAvatar(
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(userId);
                            } else {
                              _selectedUserIds.add(userId);
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
                                  // Profile image
                                  ClipOval(
                                    child: Image.network(
                                      userData['profile'],
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
                                  // Blur effect and tick mark only for selected user
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
                                              color: theme.colorScheme.onPrimary, // Use theme onPrimary color
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
                                userData['username'],
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
                  width: double.infinity, // Occupies all available horizontal space
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(theme.colorScheme.primary), // Use theme primary color
                      foregroundColor: MaterialStateProperty.all(theme.colorScheme.onPrimary), // Use theme onPrimary color
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    onPressed: _selectedUserIds.isNotEmpty ? _sharePostToAllSelected : null,
                    child: Text(S.of(context).send, style: TextStyle(
                        color: Colors.white
                    ),),
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
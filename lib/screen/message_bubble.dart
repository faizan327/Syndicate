import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syndicate/screen/post_screen.dart';
import 'package:syndicate/screen/reactions_widget.dart';
import 'package:syndicate/widgets/reactions_popup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Chapters/SingleReelPage.dart';



class MessageBubble extends StatefulWidget {
  final bool isMe;
  final String? message;
  final String? imageUrl;
  final String? audioUrl;
  final Timestamp timestamp;
  final bool isRead;
  final bool isDelivered;
  final String profileImage;
  final Function(String messageId, String messageContent) onSwipeReply;
  final String messageId;
  final String? replyToContent;
  final Map<String, dynamic>? sharedPost;
  final Map<String, dynamic> reactions;
  final Function(String messageId, String reaction) onReact;
  final bool isSelected;
  final Function(String messageId) onToggleSelection;
  final bool isMultiSelectMode;
  final bool shouldHighlight; // New parameter

  const MessageBubble({
    Key? key,
    required this.isMe,
    this.message,
    this.imageUrl,
    this.audioUrl,
    required this.timestamp,
    required this.isRead,
    required this.isDelivered,
    required this.profileImage,
    required this.onSwipeReply,
    required this.messageId,
    this.replyToContent,
    required this.reactions,
    required this.onReact,
    this.sharedPost,
    required this.isSelected,
    required this.onToggleSelection,
    required this.isMultiSelectMode,

    this.shouldHighlight = false, // Default to false
  }) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _currentSpeed = 1.0;
  OverlayEntry? _overlayEntry;
  final GlobalKey _messageKey = GlobalKey();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Stream subscriptions
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();

    // Fade-in animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // Initialize audio
    _audioPlayer = AudioPlayer();
    _initializeAudio();
  }

  @override
  void dispose() {
    // Cancel stream subscriptions to prevent setState calls after disposal
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _initializeAudio() async {
    if (widget.audioUrl == null) return;
    try {
      await _audioPlayer.setUrl(widget.audioUrl!);
      _duration = _audioPlayer.duration ?? Duration.zero;

      // Listen to position updates
      _positionSubscription = _audioPlayer.positionStream.listen((pos) {
        if (mounted) {
          setState(() {
            _position = pos;
          });
        }
      });

      // Listen to playback state changes
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        final isPlaying = state.playing;
        final processingState = state.processingState;

        if (processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });
          }
        } else if (mounted) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing audio: $e")),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    print('Original URL: $url');
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    print('Modified URL: $url');

    try {
      final Uri uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        throw 'Invalid URL: $url (Missing scheme or authority)';
      }
      print('Parsed URI: $uri');

      bool canLaunch = await canLaunchUrl(uri);
      print('Can launch URL: $canLaunch');
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('URL launched successfully: $uri');
      } else {
        print('Falling back to browser intent for: $uri');
        // Fallback: Explicitly try to open in a browser
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
        );
        print('Fallback launch attempted: $uri');
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error launching $url: $e")),
        );
      }
    }
  }

  void _toggleSpeed() {
    if (mounted) {
      setState(() {
        if (_currentSpeed == 1.0) {
          _currentSpeed = 1.5;
        } else if (_currentSpeed == 1.5) {
          _currentSpeed = 2.0;
        } else {
          _currentSpeed = 1.0;
        }
        _audioPlayer.setSpeed(_currentSpeed);
      });
    }
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    if (details.primaryVelocity! < 0 && widget.isMe) {
      widget.onSwipeReply(widget.messageId, _getReplyPreviewText());
    } else if (details.primaryVelocity! > 0 && !widget.isMe) {
      widget.onSwipeReply(widget.messageId, _getReplyPreviewText());
    }
  }

  String _getReplyPreviewText() {
    if (widget.message != null && widget.message!.isNotEmpty) {
      return widget.message!;
    } else if (widget.imageUrl != null) {
      return 'Image';
    } else if (widget.audioUrl != null) {
      return 'Audio';
    }
    return '';
  }

  void _showReactionOptions() {
    if (widget.isMultiSelectMode) return; // Disable reactions in multi-select mode
    if (_overlayEntry != null) return;

    RenderBox renderBox = _messageKey.currentContext?.findRenderObject() as RenderBox;
    Offset position = renderBox.localToGlobal(Offset.zero);
    Size size = renderBox.size;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double popupWidth = 300;
    double popupHeight = 60;
    double margin = 10;

    double top = position.dy - popupHeight - margin;
    double minTop = MediaQuery.of(context).padding.top + margin;
    if (top < minTop) {
      top = position.dy + size.height + margin;
    }

    double maxTop = screenHeight - popupHeight - margin;
    if (top > maxTop) {
      top = maxTop;
    }

    double left = position.dx + size.width / 2 - popupWidth / 2;
    left = left.clamp(10.0, screenWidth - popupWidth - 10.0);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: popupWidth,
              height: popupHeight,
              child: Material(
                color: Colors.transparent,
                child: ReactionsPopup(
                  onReactionSelected: (reaction) {
                    _setReaction(reaction);
                    _removeOverlay();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _setReaction(String reaction) {
    widget.onReact(widget.messageId, reaction);
  }

  Future<void> _playPauseAudio() async {
    if (widget.audioUrl == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.black,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[400],
                  child: const Icon(Icons.broken_image, size: 100, color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime time = widget.timestamp.toDate();
    String formattedTime = DateFormat('hh:mm a').format(time);

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        key: _messageKey,
        onHorizontalDragEnd: _handleSwipe,
        onDoubleTap: widget.isMultiSelectMode ? null : _showReactionOptions,
        onLongPress: () {
          widget.onToggleSelection(widget.messageId);
        },
        onTap: () {
          if (widget.isMultiSelectMode) {
            widget.onToggleSelection(widget.messageId);
          }
        },
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Colors.blue.withOpacity(0.3)
                  : (widget.shouldHighlight ? Colors.yellow.withOpacity(0.3) : null), // Highlight if needed
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: _buildMessageContent(formattedTime),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(String formattedTime) {
    return Column(
      crossAxisAlignment:
      widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (widget.replyToContent != null && widget.replyToContent!.isNotEmpty)
          _buildReplyPreview(),
        if (widget.imageUrl != null) _buildImageMessage(),
        if (widget.sharedPost != null)
          widget.sharedPost!.containsKey('reelsvideo')
              ? _buildSharedReelBubble(widget.sharedPost!, formattedTime)
              : _buildSharedPostBubble(widget.sharedPost!, formattedTime),
        if (widget.audioUrl != null) _buildAudioMessage(),
        if (widget.message != null && widget.message!.isNotEmpty)
          _buildTextMessage(),
        if (widget.reactions.isNotEmpty) _buildReactions(),
        const SizedBox(height: 2),
        _buildTimestampRow(formattedTime),
      ],
    );
  }

  Widget _buildSharedReelBubble(Map<String, dynamic> reelData, String formattedTime) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
      widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.isMultiSelectMode ? null : () {
            // Navigate to the Reel video screen when tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReelsVideoScreen(snapshot: reelData),
              ),
            );
          },
          onLongPress: () {
            if (!widget.isMultiSelectMode) {
              _showReactionOptions();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.orange.withOpacity(0.4)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(reelData['profileImage']),
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reelData['username'] ?? 'Unknown',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.textTheme.bodyLarge?.color),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: reelData['thumbnail'] != null
                          ? Image.network(
                        reelData['thumbnail'],
                        height: 300,
                        width: 200,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        height: 200,
                        width: 200,
                        color: Colors.black26,
                        child: const Icon(Icons.videocam, size: 50),
                      ),
                    ),
                    Icon(
                      Icons.play_arrow,
                      size: 50,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (reelData['caption'] != null &&
                    reelData['caption'].toString().isNotEmpty)
                  Text(
                    reelData['caption'],
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    maxLines: 2,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildSharedPostBubble(Map<String, dynamic> postData, String formattedTime) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
      widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            String collectionType = 'posts';
            try {
              DocumentSnapshot userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(postData['postOwnerUid'])
                  .get();
              String role = userDoc['role'] ?? 'user';
              if (role == 'admin') {
                collectionType = 'AdminPosts';
              }
            } catch (e) {
              print('Error fetching post owner role: $e');
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostScreen(
                  collectionType: collectionType,
                  postId: postData['postId'] ?? '', // Pass only postId
                ),
              ),
            );
          },
          onLongPress: () {
            _showReactionOptions();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Color(0xffe0993d).withOpacity(0.4)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                      NetworkImage(postData['postOwnerProfileImage']),
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postData['postOwnerUsername'] ?? 'Unknown',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black),
                        ),
                        if (postData['location'] != null &&
                            postData['location'].toString().isNotEmpty)
                          Text(
                            postData['location'],
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    postData['postImage'],
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                if (postData['caption'] != null &&
                    postData['caption'].toString().isNotEmpty)
                  Text(
                    postData['caption'],
                    style: TextStyle(color: Colors.black),
                    maxLines: 2,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildReplyPreview() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: Color(0xffe0993d),
            margin: const EdgeInsets.only(right: 8),
          ),
          Expanded(
            child: Text(
              widget.replyToContent!,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage() {
    final bubbleColor = widget.isMe ? Color(0xffe0993d) : Colors.grey[300];
    return GestureDetector(
      onTap: () => widget.isMultiSelectMode
          ? null // Disable image zoom in multi-select mode
          : () => _showFullScreenImage(widget.imageUrl!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.imageUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[400],
              child: const Icon(Icons.broken_image, size: 50),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAudioMessage() {
    final theme = Theme.of(context);
    final bubbleColor = widget.isMe ? Color(0xffe0993d) : Colors.grey[300];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: widget.isMe ? Colors.white : Colors.black,
              size: 32,
            ),
            onPressed: widget.isMultiSelectMode ? null : _playPauseAudio, // Disable in multi-select mode
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 20,
                  child: Slider(
                    min: 0.0,
                    max: _duration.inMilliseconds.toDouble(),
                    value: _position.inMilliseconds.toDouble() >
                        _duration.inMilliseconds.toDouble()
                        ? _duration.inMilliseconds.toDouble()
                        : _position.inMilliseconds.toDouble(),
                    onChanged: widget.isMultiSelectMode
                        ? null // Disable slider in multi-select mode
                        : (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    },
                    activeColor: widget.isMe ? Colors.white : Colors.blue,
                    inactiveColor: widget.isMe ? Colors.white70 : Colors.grey,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isMe ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                    Text(
                      "${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isMe ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: widget.isMultiSelectMode ? null : _toggleSpeed,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              "${_currentSpeed}x",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage() {
    final bubbleColor = widget.isMe ? Color(0xffe0993d).withOpacity(1.0) : Colors.grey[300];
    final textColor = widget.isMe ? Colors.white : Colors.black;

    // If message is null or empty, return an empty SizedBox
    if (widget.message == null || widget.message!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Regular expression to detect URLs
    final urlPattern = RegExp(
      r'(https?:\/\/[^\s]+)|([a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+[^\s]*)',
      caseSensitive: false,
    );
    final text = widget.message!;
    final matches = urlPattern.allMatches(text);

    // If no URLs are found, return a simple Text widget
    if (matches.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(widget.isMe ? 12 : 0),
            bottomRight: Radius.circular(widget.isMe ? 0 : 12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        ),
      );
    }
    // Split the text into parts with clickable links
    List<TextSpan> textSpans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before the URL (if any)
      if (match.start > lastMatchEnd) {
        textSpans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(color: textColor, fontSize: 16),
          ),
        );
      }

      // Add the clickable URL
      final url = match.group(0)!;
      textSpans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: widget.isMe ? Colors.white70 : Colors.blue,
            fontSize: 16,
            decoration: TextDecoration.underline,
          ),
          recognizer: widget.isMultiSelectMode
              ? null // Disable link tap in multi-select mode
              : (TapGestureRecognizer()
            ..onTap = () async {
              await _launchURL(url);
            }),
        ),
      );

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last URL (if any)
    if (lastMatchEnd < text.length) {
      textSpans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(widget.isMe ? 12 : 0),
          bottomRight: Radius.circular(widget.isMe ? 0 : 12),
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: textSpans,
        ),
      ),
    );
  }

  Widget _buildReactions() {
    if (widget.reactions.isEmpty) return const SizedBox.shrink();

    Map<String, int> reactionCounts = {};
    widget.reactions.forEach((userId, emoji) {
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    });

    return ReactionsWidget(reactionCounts: reactionCounts);
  }

  Widget _buildTimestampRow(String formattedTime) {
    if (widget.isMe) {
      Widget statusIcon;
      if (!widget.isDelivered) {
        statusIcon = Icon(Icons.done, size: 16, color: Colors.grey);
      } else if (widget.isDelivered && !widget.isRead) {
        statusIcon = Icon(Icons.done_all, size: 16, color: Colors.grey);
      } else {
        statusIcon = Icon(Icons.done_all, size: 16, color: Colors.blue);
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedTime,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 4),
          statusIcon,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTime,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryMessageBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  final Timestamp timestamp;
  final bool isRead;
  final bool isDelivered; // Track if the message is delivered
  final String profileImage;
  final String storyReference;
  final String? mediaUrl;

  const StoryMessageBubble({
    Key? key,
    required this.isMe,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.profileImage,
    required this.storyReference,
    required this.isDelivered, // Pass isDelivered from the parent widget
    this.mediaUrl,
  }) : super(key: key);

  // Helper method to build the timestamp row
  Widget _buildTimestampRow(String formattedTime) {
    if (isMe) {
      Widget statusIcon;
      if (!isDelivered) {
        statusIcon = Icon(Icons.done, size: 16, color: Colors.grey); // Sent
      } else if (isDelivered && !isRead) {
        statusIcon = Icon(Icons.done_all, size: 16, color: Colors.grey); // Delivered
      } else {
        statusIcon = Icon(Icons.done_all, size: 16, color: Colors.blue); // Read
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    DateTime time = timestamp.toDate();
    String formattedTime = DateFormat('hh:mm a').format(time);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.2),
              Colors.orange.withOpacity(0.4)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [Colors.grey[200]!, Colors.grey[300]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Replied to message label with improved style
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Replied to a story',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: isMe
                      ? theme.textTheme.bodyLarge?.color?.withOpacity(0.6)
                      : Colors.black.withOpacity(0.6),
                ),
              ),
            ),

            // Message text with slightly larger font size and better readability
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isMe ? theme.textTheme.bodyLarge?.color : Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            // Use the _buildTimestampRow method here
            _buildTimestampRow(formattedTime),
          ],
        ),
      ),
    );
  }
}
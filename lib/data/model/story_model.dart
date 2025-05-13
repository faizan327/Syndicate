// lib/data/model/story_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String storyId;
  final String userId;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime uploadTime;
  final DateTime expiryTime;
  final List<String> viewedBy;

  StoryModel({
    required this.storyId,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.uploadTime,
    required this.expiryTime,
    required this.viewedBy,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      storyId: doc.id,
      userId: data['userId'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      uploadTime: (data['uploadTime'] as Timestamp).toDate(),
      expiryTime: (data['expiryTime'] as Timestamp).toDate(),
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
    );
  }
}
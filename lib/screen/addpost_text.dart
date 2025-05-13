import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/firebase_service/storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/generated/l10n.dart';

class AddPostTextScreen extends StatefulWidget {
  final File? file;
  final String? postId;
  final String? caption;
  final String? location;
  final String? postImageUrl;
  final String? collectionName;

  const AddPostTextScreen({
    this.file,
    this.postId,
    this.caption,
    this.location,
    this.postImageUrl,
    this.collectionName,
    super.key,
  });

  @override
  State<AddPostTextScreen> createState() => _AddPostTextScreenState();
}

class _AddPostTextScreenState extends State<AddPostTextScreen> {
  late TextEditingController captionController;
  late TextEditingController locationController;
  bool isLoading = false;
  File? newImageFile;

  @override
  void initState() {
    super.initState();
    captionController = TextEditingController(text: widget.caption ?? '');
    locationController = TextEditingController(text: widget.location ?? '');
    newImageFile = widget.file;
  }

  Future<void> _handleSubmit() async {
    if (captionController.text.trim().isEmpty &&
        newImageFile == null &&
        widget.postImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a caption or image')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String? postImageUrl = widget.postImageUrl;
      if (newImageFile != null) {
        postImageUrl =
        await StorageMethod().uploadImageToStorage('post', newImageFile!);
      }

      if (widget.postId == null) {
        String userRole = await Firebase_Firestor().getUserRole();
        String collectionName = (userRole == 'admin') ? 'AdminPosts' : 'posts';
        await Firebase_Firestor().CreatePost(
          postImage: postImageUrl ?? '',
          caption: captionController.text.trim(),
          location: locationController.text.trim(),
          collectionName: collectionName,
        );
      } else {
        await Firebase_Firestor().updatePost(
          postId: widget.postId!,
          caption: captionController.text.trim(),
          location: locationController.text.trim(),
          postImage: postImageUrl ?? '',
          collectionName: widget.collectionName!,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.postId != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          isEditing ? S.of(context).edit : S.of(context).newPost,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp, // Responsive font size
          ),
        ),
        toolbarHeight: 56.h, // Responsive AppBar height
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextButton(
              onPressed: isLoading ? null : _handleSubmit,
              child: Text(
                isEditing ? S.of(context).share : S.of(context).share, // Fixed ternary expression
                style: TextStyle(
                  color: isLoading ? Colors.grey : Colors.blue,
                  fontSize: 16.sp, // Responsive font size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          width: 90.w, // Responsive width
                          height: 90.h, // Responsive height
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                          ),
                          child: newImageFile != null
                              ? Image.file(newImageFile!, fit: BoxFit.cover)
                              : widget.postImageUrl != null
                              ? Image.network(widget.postImageUrl!,
                              fit: BoxFit.cover)
                              : Icon(Icons.image,
                              color: Colors.grey, size: 40.sp),
                        ),
                      ),
                      SizedBox(width: 12.w), // Responsive spacing
                      Expanded(
                        child: TextField(
                          controller: captionController,
                          maxLines: 3,
                          maxLength: 250,
                          decoration: InputDecoration(
                            hintText: S.of(context).writeACaption,
                            hintStyle: TextStyle(fontSize: 14.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                            contentPadding: EdgeInsets.all(12.w),
                          ),
                          style: TextStyle(fontSize: 16.sp), // Responsive text
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h), // Responsive spacing
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      hintText: S.of(context).addLocation,
                      hintStyle: TextStyle(fontSize: 14.sp),
                      prefixIcon: Icon(Icons.location_on,
                          color: Colors.grey, size: 20.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                    ),
                    style: TextStyle(fontSize: 16.sp), // Responsive text
                  ),
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 4.w, // Responsive stroke width
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    captionController.dispose();
    locationController.dispose();
    super.dispose();
  }
}

extension on Firebase_Firestor {
  Future<String> getUserRole() async {
    var user = await getUser();
    return user.role;
  }
}
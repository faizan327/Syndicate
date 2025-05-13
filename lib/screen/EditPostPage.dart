// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:syndicate/data/firebase_service/firestor.dart';
// import 'package:syndicate/generated/l10n.dart';
//
// class EditPostPage extends StatefulWidget {
//   final String postId;
//   final String collectionType;
//   final String initialCaption;
//   final String initialLocation;
//
//   EditPostPage({
//     required this.postId,
//     required this.collectionType,
//     required this.initialCaption,
//     required this.initialLocation,
//     super.key,
//   });
//
//   @override
//   State<EditPostPage> createState() => _EditPostPageState();
// }
//
// class _EditPostPageState extends State<EditPostPage> {
//   late TextEditingController _captionController;
//   late TextEditingController _locationController;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _captionController = TextEditingController(text: widget.initialCaption);
//     _locationController = TextEditingController(text: widget.initialLocation);
//   }
//
//   @override
//   void dispose() {
//     _captionController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _saveChanges() async {
//     if (_captionController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Caption cannot be empty')),
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       await Firebase_Firestor().updatePost(
//         postId: widget.postId,
//         collectionType: widget.collectionType,
//         caption: _captionController.text.trim(),
//         location: _locationController.text.trim(),
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Post updated successfully')),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating post: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Edit Post', style: TextStyle(fontSize: 18.sp)),
//         actions: [
//           TextButton(
//             onPressed: _isLoading ? null : _saveChanges,
//             child: _isLoading
//                 ? SizedBox(
//               width: 20.w,
//               height: 20.h,
//               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//             )
//                 : Text(
//               'Save',
//               style: TextStyle(fontSize: 16.sp, color: Colors.blue),
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Caption',
//               style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
//             ),
//             SizedBox(height: 8.h),
//             TextField(
//               controller: _captionController,
//               maxLines: 3,
//               decoration: InputDecoration(
//                 hintText: 'Write a caption...',
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
//                 filled: true,
//                 fillColor: theme.inputDecorationTheme.fillColor,
//               ),
//             ),
//             SizedBox(height: 16.h),
//             Text(
//               'Location',
//               style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
//             ),
//             SizedBox(height: 8.h),
//             TextField(
//               controller: _locationController,
//               decoration: InputDecoration(
//                 hintText: 'Add a location...',
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
//                 filled: true,
//                 fillColor: theme.inputDecorationTheme.fillColor,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
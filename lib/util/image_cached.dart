import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CachedImage extends StatelessWidget {
  final String? imageURL;

  const CachedImage(this.imageURL, {super.key});

  @override
  Widget build(BuildContext context) {
    // If imageURL is null or empty, show a placeholder
    if (imageURL == null || imageURL!.isEmpty) {
      print('CachedImage: imageURL is null or empty');
      return Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 50,
        ),
      );
    }

    return CachedNetworkImage(
      fit: BoxFit.cover,
      imageUrl: imageURL!,
      progressIndicatorBuilder: (context, url, progress) {
        return Container(
          padding: EdgeInsets.all(130.h),

        );
      },
      errorWidget: (context, url, error) {
        // Log the error for debugging
        // print('CachedImage Error - URL: $url, Error: $error');
        return Container(
          color: Colors.grey[300], // Changed from amber for better UX
          child: const Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 50,
            ),
          ),
        );
      },
    );
  }
}
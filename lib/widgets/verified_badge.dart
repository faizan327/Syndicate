// widgets/verified_badge.dart
import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size; // Size of the badge
  final Color color; // Color of the badge

  const VerifiedBadge({
    super.key,
    this.size = 20.0, // Default size
    this.color = Colors.orange, // Default color
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      color: color,
      size: size,
    );
  }
}
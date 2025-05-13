import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedBorder extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final bool isGreyBorder;

  const AnimatedBorder({
    Key? key,
    required this.child,
    required this.isActive,
    this.isGreyBorder = false,
  }) : super(key: key);

  @override
  _AnimatedBorderState createState() => _AnimatedBorderState();
}

class _AnimatedBorderState extends State<AnimatedBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isActive
        ? AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(1.3.w), // Already scaled
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.transparent, width: 2.w), // Already scaled
            gradient: SweepGradient(
              colors: widget.isGreyBorder
                  ? [Colors.grey[600]!, Colors.grey[400]!, Colors.grey[200]!, Colors.grey[600]!]
                  : [Colors.deepOrange, Colors.amber, Colors.orangeAccent, Colors.deepOrange],
              stops: const [0.0, 0.5, 0.75, 1.0],
              transform: GradientRotation(_animation.value * 6.28),
            ),
          ),
          child: widget.child,
        );
      },
    )
        : Container(
      padding: EdgeInsets.all(4.w), // Already scaled
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isGreyBorder ? Colors.grey : Colors.grey,
          width: 1.w, // Already scaled
        ),
      ),
      child: widget.child,
    );
  }
}
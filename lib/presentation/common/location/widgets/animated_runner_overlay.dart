import 'package:flutter/material.dart';

/// Animated running person indicator overlay for the map (shown during run).
class AnimatedRunnerOverlay extends StatefulWidget {
  const AnimatedRunnerOverlay({super.key});

  @override
  State<AnimatedRunnerOverlay> createState() => _AnimatedRunnerOverlayState();
}

class _AnimatedRunnerOverlayState extends State<AnimatedRunnerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 4 * _controller.value),
          child: Icon(
            Icons.directions_walk,
            size: 40,
            color: const Color(0xFFFC4C02),
          ),
        );
      },
    );
  }
}

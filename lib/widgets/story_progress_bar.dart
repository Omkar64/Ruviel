import 'package:flutter/material.dart';

class StoryProgressBar extends StatelessWidget {
  final AnimationController animationController;
  final Color color;
  final double height;

  const StoryProgressBar({
    super.key,
    required this.animationController,
    required this.color,
    this.height = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * animationController.value,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

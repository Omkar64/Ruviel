import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../screens/story_viewer_screen.dart';
import '../screens/profile.dart';
import '../services/auth_service.dart';

class StoryAvatar extends StatefulWidget {
  final String userId;
  final String username;
  final String? profileImageUrl;
  final List<StoryModel> stories;
  final double radius;
  final VoidCallback? onTap;
  final bool showAnimation;

  const StoryAvatar({
    super.key,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    this.stories = const [],
    this.radius = 32.0,
    this.onTap,
    this.showAnimation = true,
  });

  @override
  State<StoryAvatar> createState() => _StoryAvatarState();
}

class _StoryAvatarState extends State<StoryAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _gradientAnimation;
  bool _hasShownAnimation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Trigger animation when stories are first available
    if (hasActiveStory && widget.showAnimation) {
      _triggerAnimation();
    }
  }

  @override
  void didUpdateWidget(StoryAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger animation when stories become available for the first time
    if (hasActiveStory && 
        !oldWidget.stories.any((story) => !story.isExpired) && 
        widget.showAnimation && 
        !_hasShownAnimation) {
      _triggerAnimation();
    }
  }

  void _triggerAnimation() {
    if (!_hasShownAnimation) {
      _hasShownAnimation = true;
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get hasActiveStory {
    return widget.stories.any((story) => !story.isExpired);
  }

  // Helper method to check if any user has active stories
  static bool hasActiveStories(List<StoryModel> stories) {
    return stories.any((story) => !story.isExpired);
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (hasActiveStory) {
      // Default behavior: open story viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryViewerScreen(
            stories: widget.stories.where((s) => !s.isExpired).toList(),
            userId: widget.userId,
          ),
        ),
      );
    } else {
      // No stories - navigate to profile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: widget.userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasActiveStory) {
      // No active stories - show normal avatar
      return GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            // Navigate to profile when no stories
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: widget.userId),
              ),
            );
          }
        },
        child: CircleAvatar(
          radius: widget.radius,
          backgroundImage: widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
              ? NetworkImage(widget.profileImageUrl!)
              : null,
          child: (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty)
              ? Text(
                  widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.radius * 0.6,
                  ),
                )
              : null,
        ),
      );
    }

    // Has active stories - show avatar with animated story ring
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _handleTap,
          child: Transform.scale(
            scale: widget.showAnimation ? _scaleAnimation.value : 1.0,
            child: Container(
              width: (widget.radius + 4) * 2,
              height: (widget.radius + 4) * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE1306C), // Instagram Pink
                    const Color(0xFF833AB4), // Instagram Purple  
                    const Color(0xFFFD1D1D), // Instagram Red
                    const Color(0xFFF77737), // Instagram Orange
                    const Color(0xFFC13584), // Instagram Pink/Purple
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  width: widget.radius * 2,
                  height: widget.radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: widget.radius,
                    backgroundImage: widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
                        ? NetworkImage(widget.profileImageUrl!)
                        : null,
                    child: (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty)
                        ? Text(
                            widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: widget.radius * 0.6,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Convenience widget for user model
class UserStoryAvatar extends StatelessWidget {
  final UserModel user;
  final List<StoryModel> stories;
  final double radius;
  final VoidCallback? onTap;
  final bool showAnimation;

  const UserStoryAvatar({
    super.key,
    required this.user,
    this.stories = const [],
    this.radius = 32.0,
    this.onTap,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return StoryAvatar(
      userId: user.id,
      username: user.username,
      profileImageUrl: user.profileImageUrl,
      stories: stories,
      radius: radius,
      onTap: onTap,
      showAnimation: showAnimation,
    );
  }
}
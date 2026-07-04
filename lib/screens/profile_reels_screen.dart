import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:vibration/vibration.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';

class ProfileReelsScreen extends StatefulWidget {
  final String userId;

  const ProfileReelsScreen({super.key, required this.userId});

  @override
  State<ProfileReelsScreen> createState() => _ProfileReelsScreenState();
}

class _ProfileReelsScreenState extends State<ProfileReelsScreen> {
  List<ReelModel> reels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserReels();
  }

  Future<void> _loadUserReels() async {
    try {
      final userReels = await ReelService.getUserReels(widget.userId);
      if (mounted) {
        setState(() {
          reels = userReels;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _openReelFeed(int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileReelsFeedScreen(
          reels: reels,
          startIndex: startIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (reels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No reels yet",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Grid layout like posts
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: reels.length,
      itemBuilder: (context, index) {
        final reel = reels[index];
        return GestureDetector(
          onTap: () => _openReelFeed(index),
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video thumbnail placeholder
                Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                
                // Play icon overlay
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProfileReelsFeedScreen extends StatefulWidget {
  final List<ReelModel> reels;
  final int startIndex;

  const ProfileReelsFeedScreen({
    super.key,
    required this.reels,
    required this.startIndex,
  });

  @override
  State<ProfileReelsFeedScreen> createState() => _ProfileReelsFeedScreenState();
}

class _ProfileReelsFeedScreenState extends State<ProfileReelsFeedScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.startIndex;
    
    // Jump to the starting index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(widget.startIndex);
      }
    });
    
    _pageController.addListener(() {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentPageIndex) {
        setState(() {
          _currentPageIndex = newIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.reels.length,
        itemBuilder: (context, index) {
          return ProfileReelPlayer(
            reel: widget.reels[index],
            isVisible: index == _currentPageIndex,
          );
        },
      ),
    );
  }
}

class ProfileReelPlayer extends StatefulWidget {
  final ReelModel reel;
  final bool isVisible;

  const ProfileReelPlayer({
    super.key,
    required this.reel,
    required this.isVisible,
  });

  @override
  State<ProfileReelPlayer> createState() => _ProfileReelPlayerState();
}

class _ProfileReelPlayerState extends State<ProfileReelPlayer> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _showControls = false;
  bool _isInitialized = false;
  late AnimationController _iconAnimationController;
  late Animation<double> _iconOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.easeInOut,
    ));
    _initializeVideo();
  }

  @override
  void didUpdateWidget(ProfileReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle visibility changes for autoplay/pause
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible && _isInitialized) {
        _controller.play();
      } else if (!widget.isVisible && _isInitialized) {
        _controller.pause();
      }
    }
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl));
    
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        _controller.setLooping(true);
        
        // Only play if visible
        if (widget.isVisible) {
          _controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    // Haptic feedback
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android) {
      try {
        await Vibration.hasVibrator();
        await Vibration.vibrate(duration: 50, amplitude: 100);
      } catch (e) {
        // Fallback to system haptic
        HapticFeedback.lightImpact();
      }
    }

    setState(() {
      _showControls = !_showControls;
    });
    
    if (_controller.value.isPlaying) {
      _controller.pause();
      // Show pause icon animation
      _iconAnimationController.forward().then((_) {
        _iconAnimationController.reverse();
      });
    } else {
      _controller.play();
      // Show play icon animation
      _iconAnimationController.forward().then((_) {
        _iconAnimationController.reverse();
      });
    }
    
    // Auto-hide controls after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        children: [
          // Video background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: _isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),

          // Play/Pause indicator
          if (_isInitialized)
            Positioned.fill(
              child: Center(
                child: AnimatedBuilder(
                  animation: _iconOpacityAnimation,
                  builder: (context, child) {
                    return AnimatedOpacity(
                      opacity: _showControls ? 1.0 : _iconOpacityAnimation.value,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white.withOpacity(0.7),
                        size: 80,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Reel info and actions
          if (_isInitialized)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Reel info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '@${widget.reel.username}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (widget.reel.caption != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.reel.caption!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                if (widget.reel.music != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.reel.music!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Actions
                          const SizedBox(width: 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Like button
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    if (widget.reel.isLiked) {
                                      await ReelService.unlike(widget.reel.id);
                                      widget.reel.isLiked = false;
                                      widget.reel.likesCount--;
                                    } else {
                                      await ReelService.like(widget.reel.id);
                                      widget.reel.isLiked = true;
                                      widget.reel.likesCount++;
                                    }
                                    setState(() {});
                                  } catch (e) {
                                    // Handle error silently
                                  }
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      widget.reel.isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.reel.likesCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Comment button
                              Column(
                                children: [
                                  const Icon(
                                    Icons.comment_outlined,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.reel.commentsCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
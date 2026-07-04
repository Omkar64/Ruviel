import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import '../services/auth_service.dart';
import '../widgets/story_progress_bar.dart';
import 'profile.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final String userId;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.userId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isLoading = true;
  String? _currentUserId;

@override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener(_onAnimationEnd);

    _loadUserId();
    _loadStory(story: widget.stories[_currentIndex]);
  }

  Future<void> _loadUserId() async {
    _currentUserId = await AuthService.currentUserId;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta != null && details.primaryDelta! > 12) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _videoController?.dispose();
    _videoController = null;
    super.dispose();
  }

  void _loadStory({required StoryModel story}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _animationController.stop();
    _animationController.reset();

    // Dispose previous video controller if any
    _videoController?.dispose();
    _videoController = null;
    if (!mounted) return;

    if (story.mediaUrl.endsWith('.mp4')) {
      _videoController = VideoPlayerController.network(story.mediaUrl)
        ..initialize().then((_) {
          setState(() => _isLoading = false);
          _videoController?.play();
          _animationController.duration = _videoController?.value.duration;
          _animationController.forward();
        });
    } else {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  void _onAnimationEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _animationController.stop();
      _animationController.reset();
      
      if (_currentIndex < widget.stories.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

void _onPageChanged(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _loadStory(story: widget.stories[_currentIndex]);
    }
  }

  Future<void> _showStoryOptions(BuildContext context, StoryModel story) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
// Show delete option only for story owner
            if (story.userId == _currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete story', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(story);
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(StoryModel story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete story?'),
        content: const Text('This action cannot be undone. Your story will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StoryService.deleteStory(story.id, imageUrl: story.imageUrl, videoUrl: story.videoUrl);
        
        if (mounted) {
          Navigator.of(context).pop(); // Close story viewer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete story: $e')),
          );
        }
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tapPosition = details.globalPosition.dx;
    
    if (tapPosition < screenWidth / 3) {
      // Tap on left side - go to previous story
      if (_currentIndex > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.of(context).pop();
      }
    } else if (tapPosition > screenWidth * 2 / 3) {
      // Tap on right side - go to next story
      if (_currentIndex < widget.stories.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.of(context).pop();
      }
    } else {
      // Tap in the middle - toggle pause/play
      setState(() {
        _isPaused = !_isPaused;
        if (_isPaused) {
          _animationController.stop();
          _videoController?.pause();
        } else {
          _animationController.forward();
          _videoController?.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final username = story.username;
    final profileUrl = story.profileImageUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Content
          GestureDetector(
            onTapDown: _onTapDown,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (story.mediaUrl.endsWith('.mp4'))
                      _videoController != null &&
                              _videoController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                          : const Center(child: CircularProgressIndicator())
                    else
                      Image.network(
                        story.mediaUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    
                    // Story caption
                    if (story.caption != null && story.caption!.isNotEmpty)
                      Positioned(
                        bottom: 24.0,
                        left: 16.0,
                        right: 16.0,
                        child: Text(
                          story.caption!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 3.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          
          // Progress bars
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.0,
            left: 8.0,
            right: 8.0,
            child: Row(
              children: List.generate(
                widget.stories.length,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: i == _currentIndex
                        ? StoryProgressBar(
                            animationController: _animationController,
                            color: Colors.white,
                          )
                        : Container(
                            height: 2.0,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1.0),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: i < _currentIndex ? 1.0 : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(1.0),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 18.0,
            left: 16.0,
            right: 64.0,
            child: Row(
              children: [
GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        profileUrl != null && profileUrl.isNotEmpty
                            ? NetworkImage(profileUrl)
                            : null,
                    child: (profileUrl == null || profileUrl.isEmpty)
                        ? Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
// Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16.0,
            right: 16.0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32.0),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
// More options button (only for story owner)
          if (story.userId == _currentUserId)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16.0,
              left: 16.0,
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 32.0),
                onPressed: () => _showStoryOptions(context, story),
              ),
            ),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ),
        ],
      ),
    );
  }
}

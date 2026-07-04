import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';
import '../services/auth_service.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final FocusNode _focusNode = FocusNode();
  List<ReelModel> reels = [];
  bool loading = true;
  int _currentPage = 0;
  final List<GlobalKey<_ReelPlayerState>> _reelKeys = [];

  @override
  void initState() {
    super.initState();
    loadReels();
    _focusNode.requestFocus();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (_pageController.page != null) {
      final newPage = _pageController.page!.round();
      if (newPage != _currentPage) {
        // Pause the previous reel
        if (_currentPage < _reelKeys.length) {
          _reelKeys[_currentPage].currentState?.setVisible(false);
        }
        // Play the new reel
        if (newPage < _reelKeys.length) {
          _reelKeys[newPage].currentState?.setVisible(true);
        }
        _currentPage = newPage;
      }
    }
  }

  Future<void> loadReels() async {
    reels = await ReelService.getReels();
    // Initialize keys for each reel
    _reelKeys.clear();
    for (int i = 0; i < reels.length; i++) {
      _reelKeys.add(GlobalKey<_ReelPlayerState>());
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (_pageController.page != null && _pageController.page! < reels.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (_pageController.page != null && _pageController.page! > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          }
        },
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: reels.length,
          itemBuilder: (_, i) {
            // Set visibility for the first page
            if (i == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _reelKeys[0].currentState?.setVisible(true);
              });
            }
            return ReelPlayer(
              key: _reelKeys[i],
              reel: reels[i],
            );
          },
        ),
      ),
    );
  }
}

class ReelPlayer extends StatefulWidget {
  final ReelModel reel;
  const ReelPlayer({super.key, required this.reel});

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _showControls = false;
  bool _isVisible = false;
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
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        if (_isVisible) {
          _controller.play();
        }
        _controller.setLooping(true);
      });
  }

  void play() {
    if (_isVisible && _controller.value.isInitialized && !_controller.value.isPlaying) {
      _controller.play();
    }
  }

  void pause() {
    if (_controller.value.isInitialized && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  void setVisible(bool visible) {
    if (_isVisible != visible) {
      _isVisible = visible;
      if (visible) {
        play();
      } else {
        pause();
      }
    }
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CommentsBottomSheet(reelId: widget.reel.id),
    );
  }

Future<void> _showReelOptions(BuildContext context) async {
    final currentUserId = await AuthService.currentUserId;
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
            // Show delete option only for reel owner
            if (widget.reel.userId == currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete reel', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            if (widget.reel.userId != currentUserId)
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Report reel'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement report functionality
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

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reel?'),
        content: const Text('This action cannot be undone. Your reel will be permanently deleted.'),
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
        await ReelService.deleteReel(widget.reel.id, videoUrl: widget.reel.videoUrl);
        
        if (mounted) {
          Navigator.of(context).pop(); // Close reel screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reel deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete reel: $e')),
          );
        }
      }
    }
  }

  Future<void> _togglePlayPause() async {
    // Haptic feedback
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android) {
      try {
        // Using vibration package for haptic feedback
        // Note: You might need to handle permissions for this
        HapticFeedback.lightImpact();
      } catch (e) {
        // Fallback to platform-specific haptic
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
      child: Stack(children: [
        _controller.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),

        // Play/Pause indicator
        if (_controller.value.isInitialized)
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _iconOpacityAnimation,
                builder: (context, child) {
                  return AnimatedOpacity(
                    opacity: _showControls ? 1.0 : _iconOpacityAnimation.value,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 80,
                    ),
                  );
                },
              ),
            ),
          ),

        Positioned(
          bottom: 20,
          left: 16,
          right: 80,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('@${widget.reel.username}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (widget.reel.caption != null)
              Text(widget.reel.caption!, style: const TextStyle(color: Colors.white)),
            if (widget.reel.music != null)
              Text(widget.reel.music!, style: const TextStyle(color: Colors.white70)),
          ]),
        ),

Positioned(
          right: 12,
          bottom: 100,
          child: Column(children: [
            IconButton(
              icon: Icon(widget.reel.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 32),
              onPressed: () async {
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
              },
            ),
            Text('${widget.reel.likesCount}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.comment_outlined, color: Colors.white, size: 32),
              onPressed: () => _showCommentsBottomSheet(context),
            ),
            Text('${widget.reel.commentsCount}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 32),
              onPressed: () => _showReelOptions(context),
            ),
          ])
        )
      ]),
    );
  }
}

class CommentsBottomSheet extends StatefulWidget {
  final String reelId;
  
  const CommentsBottomSheet({super.key, required this.reelId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> comments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final fetchedComments = await ReelService.getComments(widget.reelId);
      setState(() {
        comments = fetchedComments;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    try {
      await ReelService.addComment(widget.reelId, _commentController.text.trim());
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Comments header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Comments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Comments list
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile image
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[600],
                                  child: comment['profiles'] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            comment['profiles']['profile_image_url'] ?? '',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 40,
                                                height: 40,
                                                color: Colors.grey[600],
                                                child: const Icon(Icons.person, color: Colors.white),
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                
                                // Comment content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment['profiles']?['username'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment['comment'] ?? '',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(top: BorderSide(color: Colors.grey[700]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _postComment,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
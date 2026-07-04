import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/follow_service.dart';
import '../services/auth_service.dart';
import '../services/bookmark_service.dart';
import 'comment_section.dart';
import 'purple_story_ring.dart';
import 'instagram_share_sheet.dart';
import '../screens/profile.dart';

class PostModal extends StatefulWidget {
  final PostModel post;

  const PostModal({super.key, required this.post});

  @override
  State<PostModal> createState() => _PostModalState();
}

class _PostModalState extends State<PostModal> {
  late PostModel _post;
  bool isFollowing = false;
  bool isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    if (_post.userId == AuthService.currentUserId) return;
    
    try {
      final following = await FollowService.isFollowing(_post.userId);
      if (mounted) {
        setState(() => isFollowing = following);
      }
    } catch (e) {
      // Ignore errors for follow status
    }
  }

  Future<void> _toggleLike() async {
    try {
      final wasLiked = _post.isLiked;
      setState(() {
        _post = _post.copyWith(
          isLiked: !wasLiked,
          likesCount: wasLiked
              ? _post.likesCount - 1
              : _post.likesCount + 1,
        );
      });
      await PostService.toggleLike(_post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => isFollowLoading = true);
    
    try {
      if (isFollowing) {
        await FollowService.unfollowUser(_post.userId);
        setState(() => isFollowing = false);
      } else {
        await FollowService.followUser(_post.userId);
        setState(() => isFollowing = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => isFollowLoading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final wasBookmarked = _post.isBookmarked;
      setState(() {
        _post = _post.copyWith(
          isBookmarked: !wasBookmarked,
        );
      });
      await BookmarkService.toggleBookmark(_post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showPostOptions(BuildContext context) async {
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
            // Show delete option only for post owner
            if (_post.userId == AuthService.currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            if (_post.userId != AuthService.currentUserId)
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Report post'),
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
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone. Your post will be permanently deleted.'),
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
        await PostService.deletePost(_post.id, imageUrl: _post.imageUrl, videoUrl: _post.videoUrl);
        
        if (mounted) {
          Navigator.of(context).pop(); // Close post modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minWidth: 300,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;
            final isVeryNarrow = constraints.maxWidth < 400;

            final content = Container(
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: isMobile
                  ? SizedBox(
                      height: constraints.maxHeight,
                      child: _buildMobilePostWithOverlay(context),
                    )
                  : Row(
                      children: [
                        Expanded(flex: 3, child: _buildMedia(context)),
                        const VerticalDivider(width: 1),
                        Expanded(flex: 2, child: _buildRightPanel(context)),
                      ],
                    ),
            );

            return content;
          },
        ),
      ),
    );
  }

   Widget _buildMobilePostWithOverlay(BuildContext context) {
    return Stack(
      children: [
        // Media layer (full screen)
        _buildMedia(context),
        
        // Top overlay: Profile info
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: _buildProfileOverlay(context),
        ),
        
        // Bottom overlay: Actions and likes
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: _buildActionsOverlay(context),
        ),
      ],
    );
  }

  Widget _buildMedia(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        height: double.infinity,
        child: _post.imageUrl != null && _post.imageUrl!.isNotEmpty
            ? GestureDetector(
                onTap: () => Navigator.pop(context),
                onDoubleTap: () => _toggleLike(),
                child: Image.network(
                  _post.imageUrl!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  ),
                ),
              )
            : Container(
                color: Colors.grey[900],
                child: const Icon(Icons.image, color: Colors.grey, size: 64),
              ),
      ),
    );
  }

  Widget _buildProfileOverlay(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: _post.userId),
              ),
            );
          },
          child: PurpleStoryRing(
            imageUrl: _post.profileImageUrl ?? 'placeholder',
            username: _post.username,
            size: 32,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: _post.userId),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _post.username,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_post.userId != AuthService.currentUserId)
          isFollowing 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Following",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Follow",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () => _showPostOptions(context),
        ),
      ],
    );
  }

  Widget _buildActionsOverlay(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action buttons
        Row(
          children: [
            IconButton(
              icon: Icon(
                _post.isLiked
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _post.isLiked ? Colors.red : Colors.white,
                size: 28,
              ),
              onPressed: _toggleLike,
            ),
            
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.of(context).pop();
                  _showCommentsBottomSheet(context);
                },
              ),
              
              IconButton(
                icon: const Icon(Icons.send_outlined, color: Colors.white, size: 28),
                onPressed: () {
                showInstagramShareSheet(context, _post);
              },
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _toggleBookmark,
            ),
          ],
        ),
        
        // Likes count
        if (_post.likesCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              '${_post.likesCount} likes',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        
        // Caption (first line)
        if (_post.caption != null && _post.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black54,
                    ),
                  ],
                ),
                children: [
                  TextSpan(
                    text: '${_post.username} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: _post.caption!.length > 50 
                        ? '${_post.caption!.substring(0, 50)}...' 
                        : _post.caption!,
                  ),
                  if (_post.caption!.length > 50)
                    const TextSpan(
                      text: ' more',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  

  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: CommentSection(postId: _post.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(userId: _post.userId),
                    ),
                  );
                },
                child: PurpleStoryRing(
                  imageUrl: _post.profileImageUrl ?? 'placeholder',
                  username: _post.username,
                  size: 36,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: _post.userId),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _post.username,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
if (_post.userId != AuthService.currentUserId)
                isFollowing 
                    ? PurpleButton(
                        text: "Following",
                        onPressed: _toggleFollow,
                        isLoading: isFollowLoading,
                        isOutlined: true,
                        width: 80,
                        height: 32,
                      )
                    : PurpleButton(
                        text: "Follow",
                        onPressed: _toggleFollow,
                        isLoading: isFollowLoading,
                        width: 80,
                        height: 32,
                      ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Caption & comments scroll area
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_post.caption != null && _post.caption!.isNotEmpty) ...[
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: '${_post.username} ',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: _post.caption!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
CommentSection(postId: _post.id),
                ],
              ),
            ),
          ),
        ),

        // Actions & input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _post.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _post.isLiked ? Colors.red : null,
                    ),
                    onPressed: () async {
                      try {
                        final wasLiked = _post.isLiked;
                        setState(() {
                          _post = _post.copyWith(
                            isLiked: !wasLiked,
                            likesCount: wasLiked
                                ? _post.likesCount - 1
                                : _post.likesCount + 1,
                          );
                        });
                        await PostService.toggleLike(_post.id);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                  

                  
IconButton(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: () {},
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: _toggleBookmark,
                  ),
                  // Three dots for desktop view
                  if (_post.userId == AuthService.currentUserId)
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => _showPostOptions(context),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_post.likesCount} likes',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

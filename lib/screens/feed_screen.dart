import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/story_service.dart';
import '../services/bookmark_service.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../widgets/comment_section.dart';
import '../widgets/post_modal.dart';
import '../widgets/instagram_share_sheet.dart';
import '../widgets/story_avatar.dart';
import '../models/story_model.dart';
import 'select_post_type_screen.dart';
import 'create_story_screen.dart';
import 'story_viewer_screen.dart';
import 'profile.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<PostModel> posts = [];
  List<UserModel> suggestedUsers = [];
  UserModel? currentUserProfile;
  Map<String, List<StoryModel>> _followingStories = {};
  Map<String, List<StoryModel>> _userStories = {}; // Stories for post authors
  bool isLoading = true;
  bool isRefreshing = false;
  Set<String> followingInProgress = {};
  Set<String> followedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => isLoading = true);
    try {
      // Only fetch Instagram posts for the feed
      final fetchedPosts = await PostService.fetchPosts(postType: 'instagram');
      final suggestions = await FollowService.getSuggestedUsers(limit: 5);
      final profile = await AuthService.getCurrentUserProfile();
      final stories = await StoryService.fetchFollowingStories();

      // Fetch stories for each unique post author
      final userStories = <String, List<StoryModel>>{};
      final uniqueUserIds = fetchedPosts.map((post) => post.userId).toSet();
      
      for (final userId in uniqueUserIds) {
        final userStoryList = await StoryService.fetchUserStories(userId);
        if (userStoryList.isNotEmpty) {
          userStories[userId] = userStoryList;
        }
      }

      if (mounted) {
      setState(() {
          posts = fetchedPosts;
          suggestedUsers = suggestions;
          currentUserProfile = profile;
          _followingStories = stories;
          _userStories = userStories;
          isLoading = false;
          // Reset follow state when loading fresh data
          followingInProgress.clear();
          followedUserIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading feed: $e')),
        );
      }
    }
  }

  Future<void> _refreshFeed() async {
    setState(() => isRefreshing = true);
    await _loadFeed();
    setState(() => isRefreshing = false);
  }

  Future<void> _createPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectPostTypeScreen()),
    );
    
    // Refresh feed when returning from create post
    if (result == true) {
      _refreshFeed();
    }
  }

  Future<void> _openStoryViewer({
    required List<StoryModel> stories,
    required String userId,
    int initialIndex = 0,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (!isDesktop) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryViewerScreen(
            stories: stories,
            userId: userId,
            initialIndex: initialIndex,
          ),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 760),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: StoryViewerScreen(
                stories: stories,
                userId: userId,
                initialIndex: initialIndex,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 7) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _formatLikes(int likes) {
    if (likes >= 1000000) {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    } else if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    }
    return likes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Widget feed = RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView(
      children: [
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: () {
              final ids = _followingStories.keys.toList();
              final me = currentUserProfile?.id;
              if (me != null && !ids.contains(me)) {
                ids.insert(0, me);
              }
              return ids.length;
            }(),
            itemBuilder: (context, index) {
              final ids = _followingStories.keys.toList();
              final me = currentUserProfile?.id;
              if (me != null && !ids.contains(me)) {
                ids.insert(0, me);
              }

              final userId = ids[index];
              final stories = _followingStories[userId] ?? const <StoryModel>[];
              final isMe = me != null && userId == me;
              final String label = isMe
                  ? 'Your Story'
                  : (stories.isNotEmpty ? stories.first.username : 'Story');
              final String initials = (label.isNotEmpty) ? label[0].toUpperCase() : '?';

              final String? avatarUrl = isMe
                  ? currentUserProfile?.profileImageUrl
                  : (stories.isNotEmpty ? stories.first.profileImageUrl : null);
              final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        StoryAvatar(
                          userId: userId,
                          username: label,
                          profileImageUrl: avatarUrl,
                          stories: stories,
                          radius: 32,
                          onTap: () async {
                            if (isMe && stories.isEmpty) {
                              final created = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateStoryScreen(),
                                ),
                              );
                              if (created == true) {
                                await _loadFeed();
                              }
                              return;
                            }

                            if (stories.isEmpty) return;
                            await _openStoryViewer(stories: stories, userId: userId);
                          },
                        ),
                        if (isMe)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                              child: const Icon(Icons.add,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 65,
                      child: Text(
                        label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
          
          // Posts
          if (posts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your first post!',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            for (var post in posts) _buildPostCard(post),
      ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        title: Row(
          children: [
            Image.asset("assets/images/logo.png", height: 35),
            const SizedBox(width: 5),
            Text(
              "Ruviel",
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                    fontStyle: FontStyle.italic,
                  ) ??
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 22,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: theme.iconTheme.color),
            onPressed: _createPost,
            tooltip: 'Create Post',
          ),
        ],
      ),
      body: screenWidth > 1000
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: feed,
                  ),
                ),
                // Right sidebar for large screens
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current user profile
                        if (currentUserProfile != null)
                          Row(
                            children: [
                              StoryAvatar(
                                userId: currentUserProfile!.id,
                                username: currentUserProfile!.username,
                                profileImageUrl: currentUserProfile!.profileImageUrl,
                                stories: _followingStories[currentUserProfile!.id] ?? [],
                                radius: 28,
                                showAnimation: true,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                    Text(
                                      currentUserProfile!.username,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      currentUserProfile!.fullName ?? '',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                              ],
                            ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        const Text(
                          "Suggested for you",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: suggestedUsers.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No suggestions',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: suggestedUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = suggestedUsers[index];
                                    final hasAvatar = user.profileImageUrl != null &&
                                        user.profileImageUrl!.isNotEmpty;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ProfileScreen(userId: user.id),
                                                ),
                                              );
                                            },
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundImage:
                                                  hasAvatar ? NetworkImage(user.profileImageUrl!) : null,
                                              child: !hasAvatar
                                                  ? Text(
                                                      user.username.isNotEmpty
                                                          ? user.username[0].toUpperCase()
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
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.username,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  '${user.followersCount} followers',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              if (followingInProgress.contains(user.id) || followedUserIds.contains(user.id)) {
                                                return; // Already being followed or in progress
                                              }

                                              // Optimistic UI update - remove user immediately
                                              setState(() {
                                                followingInProgress.add(user.id);
                                                suggestedUsers.removeWhere((u) => u.id == user.id);
                                              });

                                              try {
                                                await FollowService.followUser(user.id);
                                                
                                                if (mounted) {
                                                  setState(() {
                                                    followedUserIds.add(user.id);
                                                    followingInProgress.remove(user.id);
                                                  });
                                                  
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Followed!')),
                                                  );
                                                  
                                                  // Optional: Refresh suggestions after a delay to get fresh ones
                                                  Future.delayed(const Duration(seconds: 2), () async {
                                                    if (mounted && followingInProgress.isEmpty) {
                                                      final newSuggestions = await FollowService.getSuggestedUsers(limit: 5);
                                                      setState(() {
                                                        // Filter out already followed users
                                                        suggestedUsers = newSuggestions.where((u) => !followedUserIds.contains(u.id)).toList();
                                                      });
                                                    }
                                                  });
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  setState(() {
                                                    followingInProgress.remove(user.id);
                                                    // Revert optimistic update - add user back
                                                    if (!followedUserIds.contains(user.id)) {
                                                      suggestedUsers.insert(0, user);
                                                    }
                                                  });
                                                  
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error: $e')),
                                                  );
                                                }
                                              }
                                            },
                                            child: followingInProgress.contains(user.id)
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                    ),
                                                  )
                                                : Text(
                                                    followedUserIds.contains(user.id) ? "Following" : "Follow",
                                                    style: TextStyle(
                                                      color: followedUserIds.contains(user.id) ? Colors.grey : Colors.blue,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : feed, // Mobile: just the feed without any padding or row layout
    );
  }

Widget _buildPostCard(PostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        ListTile(
          leading: StoryAvatar(
            userId: post.userId,
            username: post.username,
            profileImageUrl: post.profileImageUrl,
            stories: _userStories[post.userId] ?? [],
            radius: 20,
            showAnimation: false,
          ),
          title: Text(
            post.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.more_vert),
        ),

        // Post media (no overlay UI)
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
          GestureDetector(
            onTap: () => _openPost(post),
            onDoubleTap: () => _toggleLike(post),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),

        // Action buttons below image (Instagram-style)
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 28,
                  ),
                  onPressed: () => _toggleLike(post),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 28),
                  onPressed: () => _openPost(post),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.send_outlined, size: 28),
                  onPressed: () {
                    showInstagramShareSheet(context, post);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 28,
                    color: post.isBookmarked ? null : null,
                  ),
                  onPressed: () => _toggleBookmark(post),
                ),
              ],
            ),
          ),

        // Post info below media
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "${_formatLikes(post.likesCount)} likes",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),

        const SizedBox(height: 4),

        if (post.caption != null && post.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: "${post.username} ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: post.caption!),
                ],
              ),
            ),
          ),

        if (post.commentsCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: GestureDetector(
              onTap: () => _openPost(post),
              child: Text(
                "View all ${post.commentsCount} comments",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _formatTimeAgo(post.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),

        const SizedBox(height: 10),
        const Divider(),
      ],
    );
}

  Future<void> _toggleLike(PostModel post) async {
    try {
      final wasLiked = post.isLiked;
      
      // Optimistic update
      setState(() {
        final index = posts.indexOf(post);
        if (index != -1) {
          posts[index] = PostModel(
            id: post.id,
            userId: post.userId,
            username: post.username,
            profileImageUrl: post.profileImageUrl,
            caption: post.caption,
            imageUrl: post.imageUrl,
            videoUrl: post.videoUrl,
            likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
            commentsCount: post.commentsCount,
            isLiked: !wasLiked,
            isBookmarked: post.isBookmarked,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
          );
    }
      });

      await PostService.toggleLike(post.id);
    } catch (e) {
      // Revert on error
      _refreshFeed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking post: $e')),
        );
      }
    }
  }

  Future<void> _toggleBookmark(PostModel post) async {
    try {
      final wasBookmarked = post.isBookmarked;
      
      // Optimistic update
      setState(() {
        final index = posts.indexOf(post);
        if (index != -1) {
          posts[index] = PostModel(
            id: post.id,
            userId: post.userId,
            username: post.username,
            profileImageUrl: post.profileImageUrl,
            caption: post.caption,
            imageUrl: post.imageUrl,
            videoUrl: post.videoUrl,
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
            isLiked: post.isLiked,
            isBookmarked: !wasBookmarked,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
          );
        }
      });

      await BookmarkService.toggleBookmark(post.id);
    } catch (e) {
      // Revert on error
      _refreshFeed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error bookmarking post: $e')),
        );
      }
    }
  }

  void _openPost(PostModel post) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: PostModal(post: post),
        );
      },
    );
  }

  void _showComments(PostModel post) {
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
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: CommentSection(postId: post.id),
              ),
            );
          },
        );
      },
    );
  }
}

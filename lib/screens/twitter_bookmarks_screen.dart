import 'package:flutter/material.dart';

import '../services/bookmark_service.dart';
import '../models/post_model.dart';
import '../widgets/tweet_card.dart';

class TwitterBookmarksScreen extends StatefulWidget {
  const TwitterBookmarksScreen({super.key});

  @override
  State<TwitterBookmarksScreen> createState() => _TwitterBookmarksScreenState();
}

class _TwitterBookmarksScreenState extends State<TwitterBookmarksScreen> {
  List<PostModel> _bookmarkedPosts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBookmarkedPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadBookmarkedPosts({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _currentOffset = 0;
      });
    }

    try {
      final posts = await BookmarkService.fetchTwitterBookmarks(
        limit: _limit,
        offset: _currentOffset,
      );

      if (!mounted) return;

      setState(() {
        if (loadMore) {
          _bookmarkedPosts.addAll(posts);
        } else {
          _bookmarkedPosts = posts;
        }
        _currentOffset += posts.length;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookmarked tweets: $e')),
      );
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;
    await _loadBookmarkedPosts(loadMore: true);
  }

  void _onPostUpdate(Map<String, dynamic> updatedPost) {
    // Find and update the post in the list
    setState(() {
      final index = _bookmarkedPosts.indexWhere(
        (post) => post.id == updatedPost['id'],
      );
      if (index != -1) {
        // Convert the updated post back to PostModel if needed
        // For now, just update the like status
        final isLiked = updatedPost['liked'] as bool? ?? false;
        final likesCount = updatedPost['likes'] as int? ?? 0;
        
        _bookmarkedPosts[index] = _bookmarkedPosts[index].copyWith(
          isLiked: isLiked,
          likesCount: likesCount,
        );
      }
    });
  }

  void _onCreateQuote(Map<String, dynamic> quoteData) {
    // Handle quote creation if needed
    // For now, we can show a snackbar or navigate to create post
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote functionality coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookmarks',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@you',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          
          // Bookmarked posts list
          if (!_isLoading && _bookmarkedPosts.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(64.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: theme.iconTheme.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bookmarked tweets yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save tweets to see them here',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          if (!_isLoading && _bookmarkedPosts.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _bookmarkedPosts.length && _isLoadingMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (index >= _bookmarkedPosts.length) return null;

                  final post = _bookmarkedPosts[index];
                  
                  // Convert PostModel to the format expected by TweetCard
                  final postData = {
                    'id': post.id,
                    'username': post.username,
                    'handle': '@${post.username.toLowerCase()}',
                    'time': _formatTime(post.createdAt),
                    'text': post.caption ?? '',
                    'image': post.imageUrl ?? '',
                    'liked': post.isLiked,
                    'bookmarked': post.isBookmarked,
                    'likes': post.likesCount,
                    'comments': <Map<String, dynamic>>[], // Empty list instead of integer
                    'commentsCount': post.commentsCount,    // Use separate field for count
                    'reposts': 0, // Twitter-specific, not in our model
                    'user_id': post.userId,
                    'profile_image_url': post.profileImageUrl,
                  };

                  return Column(
                    children: [
                      TweetCard(
                        post: postData,
                        onUpdate: _onPostUpdate,
                        onCreateQuote: _onCreateQuote,
                      ),
                      if (index < _bookmarkedPosts.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                },
                childCount: _bookmarkedPosts.length + (_isLoadingMore ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '· now';
    } else if (difference.inMinutes < 60) {
      return '· ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '· ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '· ${difference.inDays}d';
    } else {
      // For older posts, show the date
      return '· ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../utils/image_picker_stub.dart'
    if (dart.library.html) '../utils/image_picker_web.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/activity_service.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../widgets/tweet_card.dart';
import '../widgets/twitter/right_sidebar.dart';
import 'chat_screen.dart';
import 'twitter_bookmarks_screen.dart';

class TwitterShellScreen extends StatefulWidget {
  const TwitterShellScreen({super.key});

  @override
  State<TwitterShellScreen> createState() => _TwitterShellScreenState();
}

class _TwitterShellScreenState extends State<TwitterShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    final pages = <Widget>[
      const _TwitterHomePage(),
      const _TwitterExplorePage(),
      const _TwitterNotificationsPage(),
      const ChatScreen(),
      const TwitterBookmarksScreen(),
      const _TwitterProfilePage(),
      const _TwitterMorePage(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          if (isLargeScreen) _buildSidebar(theme, isLargeScreen),
          Expanded(
            child: Column(
              children: [
                if (!isLargeScreen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to Instagram',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ruviel',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Center(

                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: pages[_selectedIndex],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right Sidebar - only visible on large screens
          if (isLargeScreen)
            SizedBox(
              width: 350,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const IntrinsicHeight(
                        child: RightSidebar(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: isLargeScreen
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex.clamp(0, pages.length - 1),
              onTap: (index) {
                if (index == pages.length - 1) {
                  final overlay = Overlay.of(context)?.context
                      .findRenderObject() as RenderBox?;
                  final size = overlay?.size ?? const Size(0, 0);
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      16,
                      size.height - kToolbarHeight - 80,
                      size.width - 16,
                      0,
                    ),
                    items: const [
                      PopupMenuItem(
                        value: 'settings',
                        child: Text('Settings'),
                      ),
                      PopupMenuItem(
                        value: 'analytics',
                        child: Text('Analytics'),
                      ),
                      PopupMenuItem(
                        value: 'help',
                        child: Text('Help Center'),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ],
                  );
                  return;
                }

                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: theme.iconTheme.color,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Explore',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_none_outlined),
                  label: 'Notifications',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mail_outline),
                  label: 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_border),
                  label: 'Bookmarks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
    );
  }

  Widget _buildSidebar(ThemeData theme, bool isLargeScreen) {
    final items = [
      _NavItemData(icon: Icons.home_outlined, label: 'Home'),
      _NavItemData(icon: Icons.search, label: 'Explore'),
      _NavItemData(icon: Icons.notifications_none_outlined, label: 'Notifications'),
      _NavItemData(icon: Icons.mail_outline, label: 'Messages'),
      _NavItemData(icon: Icons.bookmark_border, label: 'Bookmarks'),
      _NavItemData(icon: Icons.person_outline, label: 'Profile'),
      _NavItemData(icon: Icons.more_horiz, label: 'More'),
    ];

    return Container(
      width: isLargeScreen ? 260 : 72,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isLargeScreen ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Back to Instagram',
                onPressed: () => Navigator.pop(context),
              ),
              if (isLargeScreen)
                const Text(
                  'Ruviel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == _selectedIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      if (index == items.length - 1) {
                        final overlay = Overlay.of(context)?.context
                            .findRenderObject() as RenderBox?;
                        final size = overlay?.size ?? const Size(0, 0);
                        showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            (isLargeScreen ? 180.0 : 72.0),
                            kToolbarHeight + 80,
                            size.width - 16,
                            0,
                          ),
                          items: const [
                            PopupMenuItem(
                              value: 'settings',
                              child: Text('Settings'),
                            ),
                            PopupMenuItem(
                              value: 'analytics',
                              child: Text('Analytics'),
                            ),
                            PopupMenuItem(
                              value: 'help',
                              child: Text('Help Center'),
                            ),
                            PopupMenuItem(
                              value: 'logout',
                              child: Text('Logout'),
                            ),
                          ],
                        );
                      } else {
                        setState(() {
                          _selectedIndex = index;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: selected
                          ? BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                            )
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 26,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.iconTheme.color,
                          ),
                          if (isLargeScreen) ...[
                            const SizedBox(width: 16),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? theme.colorScheme.onSurface
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}

class _TwitterHomePage extends StatelessWidget {
  const _TwitterHomePage();

  @override
  Widget build(BuildContext context) {
    return const _TwitterHomeFeed();
  }
}

class _TwitterHomeFeed extends StatefulWidget {
  const _TwitterHomeFeed();

  @override
  State<_TwitterHomeFeed> createState() => _TwitterHomeFeedState();
}

class _TwitterHomeFeedState extends State<_TwitterHomeFeed> {
  final TextEditingController _tweetController = TextEditingController();
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  final List<Map<String, dynamic>> _tweets = [];

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

  @override
  void initState() {
    super.initState();
    _loadTweets();
  }

  Future<void> _loadTweets() async {
    final posts = await PostService.fetchPosts(postType: 'twitter');
    if (!mounted) return;
    setState(() {
      _tweets
        ..clear()
        ..addAll(posts.map((post) => {
              'id': post.id,
              'userId': post.userId,
              'username': post.username,
              'handle': '@${post.username.toLowerCase()}',
              'time': '· ${_formatTimeAgo(post.createdAt)}',
              'text': post.caption ?? '',
              'image': post.imageUrl,
              'likes': post.likesCount,
              'liked': post.isLiked,
              'likedByUser': post.isLiked,
              'comments': <Map<String, dynamic>>[],
              'commentsCount': post.commentsCount,
              'reposts': 0,
              'repostedByUser': false,
            }));
    });
  }

  void _openUserProfile(Map<String, dynamic> tweet) {
    final userId = tweet['userId']?.toString();
    if (userId == null || userId.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TwitterUserProfilePage(userId: userId),
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await ImagePickerHelper.pickImage();
    if (result == null) return;

    setState(() {
      if (result['isWeb']) {
        _selectedImageBytes = result['bytes'];
        _selectedImageFile = null;
      } else {
        _selectedImageFile = result['file'];
        _selectedImageBytes = null;
      }
    });
  }

  Future<void> _addTweet() async {
    if (_tweetController.text.trim().isEmpty &&
        _selectedImageFile == null &&
        _selectedImageBytes == null) {
      return;
    }

    await PostService.createPost(
      caption: _tweetController.text.trim(),
      imageBytes: _selectedImageBytes,
      imageFile: _selectedImageFile,
      postType: 'twitter',
    );

    await _loadTweets();

    if (!mounted) return;
    setState(() {
      _tweetController.clear();
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _toggleLike(int index) async {
    final tweet = _tweets[index];
    final wasLiked = tweet['liked'] == true || tweet['likedByUser'] == true;
    final postId = tweet['id']?.toString();

    setState(() {
      final currentLikes = (tweet['likes'] ?? 0) as int;
      tweet['liked'] = !wasLiked;
      tweet['likedByUser'] = !wasLiked;
      tweet['likes'] = currentLikes + (wasLiked ? -1 : 1);
    });

    try {
      if (postId != null && postId.isNotEmpty) {
        await PostService.toggleLike(postId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final currentLikes = (tweet['likes'] ?? 0) as int;
        tweet['liked'] = wasLiked;
        tweet['likedByUser'] = wasLiked;
        tweet['likes'] = currentLikes + (wasLiked ? 1 : -1);
      });
    }
  }

  Widget _buildComposer(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    const AssetImage('assets/images/story1.jpg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tweetController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: "What's happening?",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedImageFile != null || _selectedImageBytes != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb && _selectedImageBytes != null
                      ? Image.memory(
                          _selectedImageBytes!,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                      : _selectedImageFile != null
                          ? Image.file(
                              _selectedImageFile!,
                              height: 180,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox.shrink(),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    setState(() {
                      _selectedImageFile = null;
                      _selectedImageBytes = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                onPressed: _pickImage,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _addTweet,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Home',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),
        _buildComposer(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTweets,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _tweets.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tweet = _tweets[index];
                return TweetCard(
                  key: ValueKey(tweet['id'] ?? index),
                  post: tweet,
                  onUpdate: (updated) {
                    setState(() {
                      _tweets[index] = updated;
                    });
                  },
                  onUserTap: () => _openUserProfile(tweet),
                  onCreateQuote: (quote) {
                    setState(() {
                      _tweets.insert(0, quote);
                    });
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TwitterExplorePage extends StatefulWidget {
  const _TwitterExplorePage();

  @override
  State<_TwitterExplorePage> createState() => _TwitterExplorePageState();
}

class _TwitterExplorePageState extends State<_TwitterExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _allTweets = [];
  List<Map<String, dynamic>> _filteredTweets = [];
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _loadExploreTweets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExploreTweets() async {
    setState(() => _isLoading = true);
    try {
      final posts = await PostService.fetchPosts(limit: 50, postType: 'twitter');
      final mapped = posts
          .map((post) => {
                'id': post.id,
                'userId': post.userId,
                'username': post.username,
                'handle': '@${post.username.toLowerCase()}',
                'time': '· ${_formatTimeAgo(post.createdAt)}',
                'text': post.caption ?? '',
                'image': post.imageUrl,
                'likes': post.likesCount,
                'liked': post.isLiked,
                'likedByUser': post.isLiked,
                'comments': <Map<String, dynamic>>[],
                'commentsCount': post.commentsCount,
                'reposts': 0,
                'repostedByUser': false,
              })
          .toList();

      if (!mounted) return;
      setState(() {
        _allTweets
          ..clear()
          ..addAll(mapped);
        _filteredTweets = List<Map<String, dynamic>>.from(_allTweets);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading explore: $e')),
      );
    }
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredTweets = List<Map<String, dynamic>>.from(_allTweets);
        return;
      }
      _filteredTweets = _allTweets.where((t) {
        final username = (t['username'] ?? '').toString().toLowerCase();
        final text = (t['text'] ?? '').toString().toLowerCase();
        return username.contains(q) || text.contains(q);
      }).toList();
    });
  }

  void _openUserProfile(Map<String, dynamic> tweet) {
    final userId = tweet['userId']?.toString();
    if (userId == null || userId.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TwitterUserProfilePage(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ??
                    theme.colorScheme.surfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'For you'),
              Tab(text: 'News'),
              Tab(text: 'Sports'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _TwitterExploreFeed(
                  isLoading: _isLoading,
                  tweets: _filteredTweets,
                  onRefresh: _loadExploreTweets,
                  onUserTap: _openUserProfile,
                ),
                _TwitterExploreFeed(
                  isLoading: _isLoading,
                  tweets: _filteredTweets,
                  onRefresh: _loadExploreTweets,
                  onUserTap: _openUserProfile,
                ),
                _TwitterExploreFeed(
                  isLoading: _isLoading,
                  tweets: _filteredTweets,
                  onRefresh: _loadExploreTweets,
                  onUserTap: _openUserProfile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TwitterExploreFeed extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> tweets;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic> tweet) onUserTap;

  const _TwitterExploreFeed({
    required this.isLoading,
    required this.tweets,
    required this.onRefresh,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tweets.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No posts found')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tweets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final t = tweets[index];
          return TweetCard(
            key: ValueKey(t['id'] ?? index),
            post: t,
            onUpdate: (_) {},
            onCreateQuote: null,
            onUserTap: () => onUserTap(t),
          );
        },
      ),
    );
  }
}

class _TwitterNotificationsPage extends StatefulWidget {
  const _TwitterNotificationsPage();

  @override
  State<_TwitterNotificationsPage> createState() =>
      _TwitterNotificationsPageState();
}

class _TwitterNotificationsPageState extends State<_TwitterNotificationsPage> {
  List<ActivityModel> _all = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final activities = await ActivityService.fetchActivity(
        postType: 'twitter',
        includeFollows: false,
      );
      if (!mounted) return;
      setState(() {
        _all = activities;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final all = _all;
    final verified = _all;
    final mentions = _all.where((a) => a.type == ActivityType.mention).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Notifications',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Verified'),
              Tab(text: 'Mentions'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _TwitterNotificationFeed(
                  isLoading: _isLoading,
                  items: all,
                  onRefresh: _load,
                ),
                _TwitterNotificationFeed(
                  isLoading: _isLoading,
                  items: verified,
                  onRefresh: _load,
                ),
                _TwitterNotificationFeed(
                  isLoading: _isLoading,
                  items: mentions,
                  onRefresh: _load,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TwitterNotificationFeed extends StatelessWidget {
  final bool isLoading;
  final List<ActivityModel> items;
  final Future<void> Function() onRefresh;

  const _TwitterNotificationFeed({
    required this.isLoading,
    required this.items,
    required this.onRefresh,
  });

  IconData _iconFor(ActivityType type) {
    switch (type) {
      case ActivityType.follow:
        return Icons.person_add_alt_1;
      case ActivityType.comment:
        return Icons.mode_comment_outlined;
      case ActivityType.like:
        return Icons.favorite_border;
      case ActivityType.mention:
        return Icons.alternate_email;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No notifications yet')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final a = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconFor(a.type),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/images/story1.jpg'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${a.username} ${a.actionText}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



class _TwitterProfilePage extends StatelessWidget {
  const _TwitterProfilePage();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.currentUserId,
      builder: (context, snapshot) {
        final userId = snapshot.data;
        if (userId == null) {
          return const Center(child: Text('Not signed in'));
        }
        return TwitterUserProfilePage(userId: userId);
      },
    );
  }
}

class TwitterUserProfilePage extends StatefulWidget {
  final String userId;

  const TwitterUserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<TwitterUserProfilePage> createState() => _TwitterUserProfilePageState();
}

class _TwitterUserProfilePageState extends State<TwitterUserProfilePage> {
  UserModel? _profile;
  List<Map<String, dynamic>> _tweets = [];
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final profile = await AuthService.getUserProfileById(widget.userId);
      final posts = await PostService.fetchUserPosts(
        widget.userId,
        postType: 'twitter',
      );

      final mapped = posts
          .map((post) => {
                'id': post.id,
                'userId': post.userId,
                'username': post.username,
                'handle': '@${post.username.toLowerCase()}',
                'time': '· ${_formatTimeAgo(post.createdAt)}',
                'text': post.caption ?? '',
                'image': post.imageUrl,
                'likes': post.likesCount,
                'liked': post.isLiked,
                'likedByUser': post.isLiked,
                'comments': <Map<String, dynamic>>[],
                'commentsCount': post.commentsCount,
                'reposts': 0,
                'repostedByUser': false,
              })
          .toList();

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _tweets = mapped;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  void _openUserProfileFromTweet(Map<String, dynamic> tweet) {
    final userId = tweet['userId']?.toString();
    if (userId == null || userId.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TwitterUserProfilePage(userId: userId),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<String?>(
      future: AuthService.currentUserId,
      builder: (context, snapshot) {
        final currentUserId = snapshot.data;
        final isSelf = widget.userId == currentUserId;
        return _buildProfileContent(theme, isSelf);
      },
    );
  }

  Widget _buildProfileContent(ThemeData theme, bool isSelf) {

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayName = (_profile?.fullName?.trim().isNotEmpty == true)
        ? _profile!.fullName!.trim()
        : (_profile?.username ?? 'User');
    final handle = '@${(_profile?.username ?? 'user').toLowerCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Stack(
            children: [
              Container(
                height: 100,
                color: Colors.grey[800],
              ),
              if (!isSelf)
                Positioned(
                  left: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              Positioned(
                left: 16,
                bottom: 0,
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/story1.jpg'),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                handle,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              if ((_profile?.bio ?? '').trim().isNotEmpty)
                Text(
                  _profile!.bio!.trim(),
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _profile?.followingCount.toString() ?? '0',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Following',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _profile?.followersCount.toString() ?? '0',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Followers',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: _TwitterProfileFeed(
            tweets: _tweets,
            onUserTap: _openUserProfileFromTweet,
          ),
        ),
      ],
    );
  }
}

class _TwitterProfileFeed extends StatelessWidget {
  final List<Map<String, dynamic>> tweets;
  final void Function(Map<String, dynamic> tweet) onUserTap;

  const _TwitterProfileFeed({
    required this.tweets,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tweets.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No posts yet')),
        ],
      );
    }

    return ListView.separated(
      itemCount: tweets.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = tweets[index];
        return TweetCard(
          key: ValueKey(post['id'] ?? index),
          post: post,
          onUpdate: (_) {},
          onCreateQuote: null,
          onUserTap: () => onUserTap(post),
        );
      },
    );
  }
}

class _TwitterMorePage extends StatelessWidget {
  const _TwitterMorePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'Open the More menu from the sidebar',
        style:
            theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
      ),
    );
  }
}

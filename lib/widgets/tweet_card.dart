import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/bookmark_service.dart';
import '../utils/share_helper_stub.dart'
    if (dart.library.html) '../utils/share_helper_web.dart';
import 'instagram_share_sheet.dart';

class TweetComment {
  final String id;
  final String user;
  final String handle;
  final String text;
  final DateTime time;

  const TweetComment({
    required this.id,
    required this.user,
    required this.handle,
    required this.text,
    required this.time,
  });
}

class TweetCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final ValueChanged<Map<String, dynamic>>? onCreateQuote;
  final VoidCallback? onUserTap;

  const TweetCard({
    super.key,
    required this.post,
    required this.onUpdate,
    this.onCreateQuote,
    this.onUserTap,
  });

  @override
  State<TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends State<TweetCard>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _post;
  late AnimationController _likeController;

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.2,
    );
  }

  @override
  void didUpdateWidget(covariant TweetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.post, widget.post)) {
      _post = Map<String, dynamic>.from(widget.post);
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  String get _id => (_post['id'] ?? '').toString();
  String get _username => (_post['username'] ?? '').toString();
  String get _handle => (_post['handle'] ?? '@user').toString();
  String get _time => (_post['time'] ?? '').toString();
  String get _text => (_post['text'] ?? _post['tweet'] ?? '').toString();
  String? get _imageUrl {
    final value = _post['image'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

List<TweetComment> get _comments {
    final commentsData = _post['comments'];
    List<dynamic> list;
    
    if (commentsData == null) {
      list = [];
    } else if (commentsData is List) {
      list = commentsData;
    } else if (commentsData is int) {
      // Handle case where comments is an integer count instead of a list
      list = [];
    } else {
      // Handle any other type by converting to empty list
      list = [];
    }
    
    return list
        .map((e) => e is TweetComment
            ? e
            : TweetComment(
                id: (e['id'] ?? '').toString(),
                user: (e['user'] ?? e['username'] ?? _username).toString(),
                handle: (e['handle'] ?? _handle).toString(),
                text: (e['text'] ?? e['comment'] ?? '').toString(),
                time: DateTime.tryParse(e['time']?.toString() ?? '') ??
                    DateTime.now(),
              ))
        .toList();
  }

  bool get _likedByUser => _post['liked'] == true || _post['likedByUser'] == true;
  bool get _repostedByUser =>
      _post['reposted'] == true || _post['repostedByUser'] == true;
  bool get _bookmarkedByUser => _post['bookmarked'] == true || _post['isBookmarked'] == true;

  int get _likes => (_post['likes'] as int?) ?? 0;
  int get _reposts => (_post['reposts'] as int?) ?? 0;

  int get _commentsCount {
    final explicit = _post['commentsCount'] ?? _post['comments_count'];
    if (explicit is int) {
      return explicit;
    }
    return _comments.length;
  }

  Map<String, dynamic>? get _quoted =>
      _post['quoted'] as Map<String, dynamic>?;

  void _notifyUpdate() {
    widget.onUpdate(Map<String, dynamic>.from(_post));
  }

  void _handleUserTap() {
    widget.onUserTap?.call();
  }

  Future<void> _toggleLike() async {
    final wasLiked = _likedByUser;
    final newLikes = _likes + (wasLiked ? -1 : 1);

    setState(() {
      _post['liked'] = !wasLiked;
      _post['likedByUser'] = !wasLiked;
      _post['likes'] = newLikes < 0 ? 0 : newLikes;
    });
    _notifyUpdate();

    try {
      await _likeController.forward(from: 0.8);
    } catch (_) {}

    if (_id.isEmpty) {
      return;
    }

    try {
      await PostService.toggleLike(_id);
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    final wasBookmarked = _bookmarkedByUser;

    setState(() {
      _post['bookmarked'] = !wasBookmarked;
      _post['isBookmarked'] = !wasBookmarked;
    });
    _notifyUpdate();

    if (_id.isEmpty) {
      return;
    }

    try {
      await BookmarkService.toggleBookmark(_id);
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _post['bookmarked'] = wasBookmarked;
        _post['isBookmarked'] = wasBookmarked;
      });
      _notifyUpdate();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error bookmarking post: $e')),
        );
      }
    }
  }

  Future<void> _openComments() async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, modalSetState) {
              final comments = _comments;

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                AssetImage('assets/images/story1.jpg'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _username,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$_handle $_time',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Text(_text),
                      ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Replying to $_handle',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                AssetImage('assets/images/story1.jpg'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: 'Post your reply',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              radius: 18,
                              backgroundImage:
                                  AssetImage('assets/images/story1.jpg'),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.user,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  c.handle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '· ${TimeOfDay.fromDateTime(c.time).format(context)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            subtitle: Text(c.text),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Spacer(),
                          FilledButton(
                            onPressed: () async {
                              final value = controller.text.trim();
                              if (value.isEmpty) {
                                return;
                              }

                              TweetComment comment = TweetComment(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                user: 'You',
                                handle: '@you',
                                text: value,
                                time: DateTime.now(),
                              );

                              if (_id.isNotEmpty) {
                                try {
                                  final created = await PostService.addComment(
                                      _id, value);
                                  if (created != null) {
                                    comment = TweetComment(
                                      id: created.id,
                                      user: created.username,
                                      handle:
                                          '@${created.username.toLowerCase()}',
                                      text: created.comment,
                                      time: created.createdAt,
                                    );
                                  }
                                } catch (_) {}
                              }

                              setState(() {
                                final updated = List<TweetComment>.from(
                                  _comments,
                                )
                                  ..add(comment);
                                _post['comments'] = updated;
                                _post['commentsCount'] = _commentsCount + 1;
                              });
                              _notifyUpdate();

                              modalSetState(() {});
                              controller.clear();
                            },
                            child: const Text('Reply'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _toggleRepost() {
    final wasReposted = _repostedByUser;
    final newCount = _reposts + (wasReposted ? -1 : 1);

    setState(() {
      _post['reposted'] = !wasReposted;
      _post['repostedByUser'] = !wasReposted;
      _post['reposts'] = newCount < 0 ? 0 : newCount;
    });
    _notifyUpdate();
  }

void _openRepostOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _repostedByUser ? Icons.repeat_one : Icons.repeat,
                color: Colors.green,
              ),
              title: Text(_repostedByUser ? 'Undo Repost' : 'Repost'),
              onTap: () {
                Navigator.pop(context);
                _toggleRepost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Quote post'),
              onTap: () {
                Navigator.pop(context);
                _openQuoteModal();
              },
            ),
            // Show delete option only for post owner
            if (_post['user_id'] == AuthService.currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _openQuoteModal() async {
    if (widget.onCreateQuote == null) {
      return;
    }

    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            AssetImage('assets/images/story1.jpg'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildQuotedPreview(),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          final text = controller.text.trim();
                          if (text.isEmpty) {
                            return;
                          }
                          final quote = <String, dynamic>{
                            'id': DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            'username': 'You',
                            'handle': '@you',
                            'time': '· now',
                            'text': text,
                            'image': null,
                            'likes': 0,
                            'liked': false,
                            'comments': <Map<String, dynamic>>[],
                            'reposts': 0,
                            'reposted': false,
                            'quoted': Map<String, dynamic>.from(_post),
                          };
                          widget.onCreateQuote!(quote);
                          Navigator.pop(context);
                        },
                        child: const Text('Post'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Future<void> _share() async {
    // Create a PostModel for the share sheet
    final postModel = PostModel(
      id: _id,
      userId: _post['user_id'] ?? '',
      username: _username,
      profileImageUrl: _post['profile_image_url'],
      caption: _text,
      imageUrl: _imageUrl,
      postType: PostType.twitter,
      likesCount: _likes,
      commentsCount: _commentsCount,
      isLiked: _likedByUser,
      createdAt: DateTime.tryParse(_post['created_at'] ?? '') ?? DateTime.now(),
    );
    
showInstagramShareSheet(context, postModel);
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

    if (confirmed == true && _id.isNotEmpty) {
      try {
        // Optimistic UI update - remove post immediately
        final updatedPost = Map<String, dynamic>.from(_post);
        updatedPost['deleted'] = true;
        setState(() => _post = updatedPost);
        _notifyUpdate();

        // Delete post with media cleanup
        await PostService.deletePost(_id, imageUrl: _imageUrl);
        
        // Close dialog if showing
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Revert optimistic update on error
        final updatedPost = Map<String, dynamic>.from(_post);
        updatedPost.remove('deleted');
        setState(() => _post = updatedPost);
        _notifyUpdate();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }

  Widget _buildQuotedPreview() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundImage: AssetImage('assets/images/story1.jpg'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_handle $_time',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                if (_text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_text, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Avatar - NO hover
          InkWell(
            onTap: widget.onUserTap == null ? null : _handleUserTap,
            customBorder: const CircleBorder(),
            child: const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/images/story1.jpg'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - NO hover
                InkWell(
                  onTap: widget.onUserTap == null ? null : _handleUserTap,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _username,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$_handle $_time',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Content - HOVER only here
                MouseRegion(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.transparent,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          hoverColor: Colors.grey[200],
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_text.isNotEmpty)
                                  Text(
                                    _text,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                if (_imageUrl != null) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                                if (_quoted != null) ...[
                                  const SizedBox(height: 8),
                                  _QuotedTweet(quoted: _quoted!),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildAction(
                                      context,
                                      icon: Icons.mode_comment_outlined,
                                      label: _commentsCount == 0
                                          ? ''
                                          : _commentsCount.toString(),
                                      color: Colors.grey[600],
                                      onTap: _openComments,
                                    ),
                                    _buildAction(
                                      context,
                                      icon: Icons.repeat,
                                      label:
                                          _reposts == 0 ? '' : _reposts.toString(),
                                      color: _repostedByUser ? Colors.green : Colors.grey[600],
                                      onTap: _openRepostOptions,
                                    ),
                                    ScaleTransition(
                                      scale: Tween<double>(begin: 1, end: 1.1)
                                          .animate(_likeController),
                                      child: _buildAction(
                                        context,
                                        icon: _likedByUser
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        label:
                                            _likes == 0 ? '' : _likes.toString(),
                                        color:
                                            _likedByUser ? Colors.red : Colors.grey[600],
                                        onTap: _toggleLike,
                                      ),
                                    ),
                                     _buildAction(
                                       context,
                                       icon: _bookmarkedByUser
                                           ? Icons.bookmark
                                           : Icons.bookmark_border,
                                       label: '',
                                       color: _bookmarkedByUser ? Colors.blue : Colors.grey[600],
                                       onTap: _toggleBookmark,
                                     ),
                                     _buildAction(
                                       context,
                                       icon: Icons.share_outlined,
                                       label: '',
                                       color: Colors.grey[600],
                                       onTap: _share,
                                     ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color? color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      hoverColor: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: content,
      ),
    );
  }
}

class _QuotedTweet extends StatelessWidget {
  final Map<String, dynamic> quoted;

  const _QuotedTweet({required this.quoted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = (quoted['username'] ?? '').toString();
    final handle = (quoted['handle'] ?? '@user').toString();
    final time = (quoted['time'] ?? '').toString();
    final text = (quoted['text'] ?? quoted['tweet'] ?? '').toString();
    final image = quoted['image'] as String?;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundImage: AssetImage('assets/images/story1.jpg'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$handle $time',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (image != null && image.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

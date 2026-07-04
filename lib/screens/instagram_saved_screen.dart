import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../services/bookmark_service.dart';
import '../models/post_model.dart';
import '../widgets/post_modal.dart';

class InstagramSavedScreen extends StatefulWidget {
  const InstagramSavedScreen({super.key});

  @override
  State<InstagramSavedScreen> createState() => _InstagramSavedScreenState();
}

class _InstagramSavedScreenState extends State<InstagramSavedScreen> {
  List<SavedItem> _savedItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
  }

  Future<void> _loadSavedItems({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _currentOffset = 0;
      });
    }

    try {
      final posts = await BookmarkService.fetchInstagramBookmarks(
        limit: _limit,
        offset: _currentOffset,
      );

      final savedItems = posts
          .where((post) => post.imageUrl != null && post.imageUrl!.isNotEmpty)
          .map(SavedItem.fromPost)
          .toList();

      if (!mounted) return;

      setState(() {
        if (loadMore) {
          _savedItems.addAll(savedItems);
        } else {
          _savedItems = savedItems;
        }
        _currentOffset += savedItems.length;
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
        SnackBar(content: Text('Error loading saved posts: $e')),
      );
    }
  }

  void _openItem(SavedItem item) async {
    if (item.post == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: PostModal(post: item.post!),
        );
      },
    );
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore) return;
    await _loadSavedItems(loadMore: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Saved Posts'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _savedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: theme.iconTheme.color?.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved posts yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save posts to see them here',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadSavedItems(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            notification.metrics.extentAfter < 200 &&
                            !_isLoadingMore) {
                          _loadMoreItems();
                        }
                        return false;
                      },
                      child: MasonryGridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        itemCount: _savedItems.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _savedItems.length && _isLoadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final item = _savedItems[index];
                          return GestureDetector(
                            onTap: () => _openItem(item),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imageWidget,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}

class SavedItem {
  final String id;
  final String username;
  final String caption;
  final String? imageUrl;
  final PostModel? post;

  SavedItem({
    required this.id,
    required this.username,
    required this.caption,
    this.imageUrl,
    this.post,
  });

  factory SavedItem.fromPost(PostModel post) {
    return SavedItem(
      id: post.id,
      username: post.username,
      caption: post.caption ?? '',
      imageUrl: post.imageUrl,
      post: post,
    );
  }

  ImageProvider get avatarImageProvider {
    if (post?.profileImageUrl != null && post!.profileImageUrl!.isNotEmpty) {
      return NetworkImage(post!.profileImageUrl!);
    }
    // Fallback avatar
    return const AssetImage('assets/images/story1.jpg');
  }

  Widget get imageWidget {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported),
    );
  }
}
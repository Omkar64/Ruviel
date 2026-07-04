import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../services/post_service.dart';
import '../models/post_model.dart';
import '../widgets/post_modal.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<ExploreItem> _allItems = [];
  List<ExploreItem> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExploreItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExploreItems() async {
    setState(() => _isLoading = true);
    try {
      // Only fetch Instagram posts for explore page
      final posts = await PostService.fetchPosts(
        limit: 60,
        postType: 'instagram',
      );

      final backendItems = posts
          .where((post) => post.imageUrl != null && post.imageUrl!.isNotEmpty)
          .map(ExploreItem.fromPost)
          .toList();

      if (!mounted) return;
      setState(() {
        _allItems = backendItems;
        _filteredItems = backendItems;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading explore posts: $e')),
      );
    }
  }

  void _filterItems(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((item) {
        return item.username.toLowerCase().contains(lower) ||
            item.caption.toLowerCase().contains(lower);
      }).toList();
    });
  }

  void _openItem(ExploreItem item) async {
    // We only have real posts now
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterItems,
              ),
            ),

            // Body
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadExploreItems,
                  child: MasonryGridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
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
          ],
        ),
      ),
    );
  }
}

class ExploreItem {
  final String id;
  final String username;
  final String caption;
  final String? imageUrl;
  final PostModel? post;

  ExploreItem({
    required this.id,
    required this.username,
    required this.caption,
    this.imageUrl,
    this.post,
  });

  factory ExploreItem.fromPost(PostModel post) {
    return ExploreItem(
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
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported),
    );
  }
}
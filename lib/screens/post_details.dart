import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  final List<PostModel> relatedPosts;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.relatedPosts = const [],
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late PostModel currentPost;
  late List<PostModel> relatedPosts;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentPost = widget.post;
    relatedPosts = widget.relatedPosts;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w';
    }
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  String _formatLikes(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Future<void> _toggleLike() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final wasLiked = currentPost.isLiked;

      setState(() {
        currentPost = currentPost.copyWith(
          isLiked: !wasLiked,
          likesCount:
              wasLiked ? currentPost.likesCount - 1 : currentPost.likesCount + 1,
        );
      });

      await PostService.toggleLike(currentPost.id);
    } catch (e) {
      setState(() => currentPost = widget.post);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: currentPost.profileImageUrl != null &&
                      currentPost.profileImageUrl!.isNotEmpty
                  ? NetworkImage(currentPost.profileImageUrl!)
                  : const AssetImage("assets/images/story1.jpg")
                      as ImageProvider,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentPost.username,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.more_vert, color: Colors.black),
          SizedBox(width: 10),
        ],
      ),

      // ✅ Entire page scrolls smoothly without overflow
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainPost(),

            if (relatedPosts.isNotEmpty) ...[
              const Divider(thickness: 0.5),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "More posts you might like",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              for (var post in relatedPosts)
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(
                          post: post,
                          relatedPosts: relatedPosts
                              .where((p) => p.id != post.id)
                              .toList(),
                        ),
                      ),
                    );
                  },
                  child: _buildPostCard(post),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainPost() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentPost.imageUrl != null)
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              currentPost.imageUrl!,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 10),

        _buildPostInfo(currentPost),
      ],
    );
  }

  Widget _buildPostInfo(PostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                post.isLiked ? Icons.favorite : Icons.favorite_border,
                color: post.isLiked ? Colors.red : Colors.black,
                size: 28,
              ),
              onPressed: _toggleLike,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chat_bubble_outline, size: 28),
            const Spacer(),
            const Icon(Icons.bookmark_border, size: 28),
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "${_formatLikes(post.likesCount)} likes",
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),

        if (post.caption != null && post.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                      text: "${post.username} ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: post.caption!),
                ],
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            _formatTimeAgo(post.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: post.profileImageUrl != null &&
                    post.profileImageUrl!.isNotEmpty
                ? NetworkImage(post.profileImageUrl!)
                : const AssetImage("assets/images/story1.jpg")
                    as ImageProvider,
          ),
          title: Text(
            post.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.more_vert, size: 20),
        ),

        if (post.imageUrl != null)
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              post.imageUrl!,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }
}

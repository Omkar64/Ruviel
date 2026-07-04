import 'package:flutter/material.dart';
import 'package:ruviel/widgets/twitter/news_card.dart';
import 'package:ruviel/widgets/twitter/trending_topic_card.dart';
import '../../themes/purple_theme.dart';

class RightSidebar extends StatelessWidget {
  final double width;
  final EdgeInsets? padding;

  const RightSidebar({
    super.key,
    this.width = 350,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      padding: padding ?? const EdgeInsets.only(left: 20, right: 16, top: 4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, top: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Premium Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF15202B) : const Color(0xFFF7F9F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscribe to Premium',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subscribe to unlock new features and if eligible, receive a share of ads revenue.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Subscribe'),
                  ),
                ],
              ),
            ),

            // Today's News Section
            _buildSectionTitle('Trending News'),
            const SizedBox(height: 8),
            _buildNewsSection(context),
            const SizedBox(height: 16),

            // What's Happening Section
            _buildSectionTitle('What\'s happening'),
            const SizedBox(height: 8),
            _buildTrendingSection(context),
            const SizedBox(height: 16),

            // Who to follow section
            Builder(
              builder: (context) => _buildWhoToFollowSection(),
            ),
            const SizedBox(height: 16),

            // Footer links
            _buildFooterLinks(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNewsSection(BuildContext context) {
    final theme = Theme.of(context);
    final newsItems = [
      {
        'title': 'Flutter 3.0 released with improved performance',
        'timeAgo': '2h',
        'category': 'Technology',
        'postCount': 1245,
        'avatars': [
          'https://picsum.photos/200/300?random=1',
          'https://picsum.photos/200/300?random=2',
          'https://picsum.photos/200/300?random=3',
        ],
        'icon': Icons.phone_android,
      },
      {
        'title': 'New AI model breaks performance records',
        'timeAgo': '4h',
        'category': 'AI',
        'postCount': 872,
        'avatars': [
          'https://picsum.photos/200/300?random=4',
          'https://picsum.photos/200/300?random=5',
        ],
        'icon': Icons.smart_toy,
      },
      {
        'title': 'Web3 and the future of the internet',
        'timeAgo': '6h',
        'category': 'Blockchain',
        'postCount': 1532,
        'avatars': [
          'https://picsum.photos/200/300?random=6',
          'https://picsum.photos/200/300?random=7',
          'https://picsum.photos/200/300?random=8',
        ],
        'icon': Icons.public,
      },
    ];

    return Column(
      children: newsItems
          .map((item) => NewsCard(
                title: item['title'] as String,
                timeAgo: '${item['timeAgo']} ago',
                category: item['category'] as String,
                postCount: item['postCount'] as int,
                avatars: (item['avatars'] as List).cast<String>(),
                categoryIcon: item['icon'] as IconData?,
              ))
          .toList(),
    );
  }

  Widget _buildTrendingSection(BuildContext context) {
    final theme = Theme.of(context);
    final trendingItems = [
      {
        'category': 'Technology · Trending',
        'title': '#Flutter',
        'postCount': '52.4K posts',
      },
      {
        'category': 'Business & finance · Trending',
        'title': '#Web3',
        'postCount': '28.1K posts',
      },
      {
        'category': 'Gaming · Trending',
        'title': 'GTA VI',
        'postCount': '124.5K posts',
      },
      {
        'category': 'Entertainment · Music',
        'title': 'Taylor Swift',
        'postCount': '1.2M posts',
      },
      {
        'category': 'Sports · Trending',
        'title': 'UEFA Champions League',
        'postCount': '89.7K posts',
      },
    ];

    return Column(
      children: trendingItems
          .map((item) => TrendingTopicCard(
                category: item['category'] as String,
                title: item['title'] as String,
                postCount: item['postCount'] as String,
              ))
          .toList(),
    );
  }

  Widget _buildWhoToFollowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Who to follow'),
        const SizedBox(height: 12),
        _buildFollowUser(
          name: 'Flutter',
          handle: '@FlutterDev',
          avatar: 'https://picsum.photos/200/300?random=10',
          isVerified: true,
        ),
        _buildFollowUser(
          name: 'Dart',
          handle: '@dart_lang',
          avatar: 'https://picsum.photos/200/300?random=11',
          isVerified: true,
        ),
        _buildFollowUser(
          name: 'Firebase',
          handle: '@Firebase',
          avatar: 'https://picsum.photos/200/300?random=12',
          isVerified: true,
        ),
TextButton(
          onPressed: () {},
          child: Text(
            'Show more',
            style: TextStyle(
              color: PurpleTheme.primaryPurple,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUser({
    required String name,
    required String handle,
    required String avatar,
    bool isVerified = false,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: PurpleTheme.primaryPurple, size: 16),
                        ],
                      ],
                    ),
                    Text(
                      handle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterLinks() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildFooterLink('Terms of Service'),
        _buildFooterLink('Privacy Policy'),
        _buildFooterLink('Cookie Policy'),
        _buildFooterLink('Accessibility'),
        _buildFooterLink('Ads info'),
        _buildFooterLink('More'),
        const Text(
          '© 2025 X Corp.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return InkWell(
      onTap: () {},
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }
}

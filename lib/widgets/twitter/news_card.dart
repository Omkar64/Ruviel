import 'package:flutter/material.dart';
import '../../themes/purple_theme.dart';

class NewsCard extends StatelessWidget {
  final String title;
  final String timeAgo;
  final String category;
  final int postCount;
  final List<String>? avatars;
  final IconData? categoryIcon;

  const NewsCard({
    super.key,
    required this.title,
    required this.timeAgo,
    required this.category,
    required this.postCount,
    this.avatars,
    this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
if (categoryIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(categoryIcon, size: 16, color: PurpleTheme.primaryPurple),
                    ),
                  Text(
                    category,
                    style: textTheme.bodySmall?.copyWith(
                      color: PurpleTheme.primaryPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (avatars != null && avatars!.isNotEmpty)
                Row(
                  children: [
                    ...avatars!.take(3).map((avatar) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(avatar),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )),
                    if (avatars!.length > 3)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '+${avatars!.length - 3}',
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '$postCount posts',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

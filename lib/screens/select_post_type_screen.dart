import 'package:flutter/material.dart';
import '../themes/purple_theme.dart';
import 'create_post_screen.dart';
import 'create_story_screen.dart';

class SelectPostTypeScreen extends StatelessWidget {
  const SelectPostTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F12) : null,
      appBar: AppBar(
        title: Text(
          'Create',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1F) : null,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _option(
              context,
              title: 'Instagram Post',
              icon: Icons.photo_camera,
              onTap: () => _open(
                context,
                const CreatePostScreen(postType: 'instagram'),
              ),
            ),
            _option(
              context,
              title: 'Twitter / Threads',
              icon: Icons.chat_bubble_outline,
              onTap: () => _open(
                context,
                const CreatePostScreen(postType: 'twitter'),
              ),
            ),
            _option(
              context,
              title: 'Reel',
              icon: Icons.movie,
              onTap: () => _open(
                context,
                const CreateStoryScreen(isReel: true),
              ),
            ),
            _option(
              context,
              title: 'Story',
              icon: Icons.auto_awesome,
              onTap: () => _open(
                context,
                const CreateStoryScreen(isReel: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      color: isDark ? const Color(0xFF1A1A1F) : null,
      child: ListTile(
        leading: Icon(icon, color: PurpleTheme.primaryPurple),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }
}
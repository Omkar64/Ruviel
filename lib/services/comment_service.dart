import 'package:flutter/foundation.dart';
import 'api_client.dart';

class CommentService {
  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final decoded = await ApiClient.get('/comments/posts/$postId/comments');
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['comments'];
      if (list is! List) return [];

      // Adapt backend shape -> UI expects { user: { username, profile_image_url } }
      return list.whereType<Map>().map((raw) {
        final map = Map<String, dynamic>.from(raw);
        final username = map['username'];
        final profileImageUrl = map['profile_image_url'];
        map['user'] = {
          'username': username,
          'profile_image_url': profileImageUrl,
        };
        return map;
      }).toList();
    } catch (e) {
      debugPrint('❌ CommentService.getComments error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> addComment(String postId, String content) async {
    try {
      final response = await ApiClient.post('/comments/posts/$postId/comment', body: {
        'comment': content,
      });
      return response['comment'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ CommentService.addComment error: $e');
      return null;
    }
  }

  static Future<void> deleteComment(String commentId) async {
    await ApiClient.delete('/comments/$commentId');
  }
}

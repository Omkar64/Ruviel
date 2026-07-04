import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import 'auth_service.dart';
import 'api_client.dart';

class ActivityService {
  // ActivityScreen handles polling/optimistic updates.

/// Fetch activity feed (likes, comments, follows)
static Future<List<ActivityModel>> fetchActivity({
    int limit = 50,
    String postType = 'instagram',
    bool includeFollows = true,
  }) async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Not authenticated');
      }

      final decoded = await ApiClient.get(
        '/activities/feed',
        queryParameters: {
          'limit': limit.toString(),
          'post_type': postType,
          'includeFollows': includeFollows.toString(),
        },
      );

      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['activities'];
      if (list is! List) return [];

      final activities = list
          .whereType<Map>()
          .map((e) => ActivityModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      debugPrint('ActivityService.fetchActivity: built ${activities.length} items');
      return activities;
    } catch (e) {
      debugPrint('❌ Error fetching activity: $e');
      return [];
    }
  }

  // Note: Realtime subscriptions can be implemented, but to avoid SDK differences
  // and keep behavior predictable across environments we'll rely on polling from
  // `ActivityScreen` and optimistic updates when performing actions.

/// Create activity (called when user likes, comments, or follows)
  static Future<void> createActivity({
    required ActivityType type,
    String? postId,
    String? commentText,
    String? targetUserId,
  }) async {
    try {
      await ApiClient.post('/activities', body: {
        'type': type.toString().split('.').last,
        'targetUserId': targetUserId,
        'postId': postId,
        'commentText': commentText,
      });
    } catch (e) {
      debugPrint('❌ Error creating activity: $e');
    }
  }
}
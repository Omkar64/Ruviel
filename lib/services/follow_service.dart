import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'api_client.dart';

class FollowService {
  /// Follow a user
static Future<void> followUser(String userId) async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      if (currentUserId == userId) {
        throw Exception('Cannot follow yourself');
      }

      await ApiClient.post('/follows/$userId');
    } catch (e) {
      debugPrint('❌ Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
static Future<void> unfollowUser(String userId) async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      await ApiClient.delete('/follows/$userId');
    } catch (e) {
      debugPrint('❌ Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Check if current user is following a user
static Future<bool> isFollowing(String userId) async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) return false;

      final decoded = await ApiClient.get('/follows/$userId/status');
      if (decoded is Map<String, dynamic> && decoded['is_following'] is bool) {
        return decoded['is_following'] as bool;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking follow status: $e');
      return false;
    }
  }

  /// Get followers of a user
  static Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final decoded = await ApiClient.get('/follows/$userId/followers');
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['followers'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching followers: $e');
      return [];
    }
  }

  /// Get users that a user is following
  static Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final decoded = await ApiClient.get('/follows/$userId/following');
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['following'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching following: $e');
      return [];
    }
  }

  /// Get suggested users to follow
static Future<List<UserModel>> getSuggestedUsers({int limit = 10}) async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) return [];

      final decoded = await ApiClient.get('/follows/suggestions',
          queryParameters: {'limit': limit.toString()});
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['users'];
      if (list is! List) return [];

      final result = <UserModel>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);

        final hasRequired = map['id'] != null &&
            map['email'] != null &&
            map['username'] != null &&
            map['created_at'] != null;

        if (!hasRequired) {
          debugPrint('FollowService.getSuggestedUsers: skipping invalid row: $map');
          continue;
        }

        try {
          result.add(UserModel.fromJson(map));
        } catch (e) {
          debugPrint('FollowService.getSuggestedUsers: parse error: $e');
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error fetching suggested users: $e');
      return [];
    }
  }
}

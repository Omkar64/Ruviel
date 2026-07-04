import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import 'auth_service.dart';
import 'api_client.dart';

class BookmarkService {

  /// Toggle bookmark on a post
static Future<bool> toggleBookmark(String postId) async {
    try {
      final userId = await AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final decoded = await ApiClient.post('/bookmarks/$postId');
      if (decoded is Map<String, dynamic> && decoded['is_bookmarked'] is bool) {
        return decoded['is_bookmarked'] as bool;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error toggling bookmark: $e');
      rethrow;
    }
  }

  /// Fetch user's Instagram bookmarks
static Future<List<PostModel>> fetchInstagramBookmarks({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final decoded = await ApiClient.get('/bookmarks/instagram',
          queryParameters: queryParams);
      
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['posts'];
      if (list is! List) return [];
      
      return list
          .whereType<Map>()
          .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e),
              currentUserId: currentUserId))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching Instagram bookmarks: $e');
      return [];
    }
  }

  /// Fetch user's Twitter bookmarks
static Future<List<PostModel>> fetchTwitterBookmarks({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final decoded = await ApiClient.get('/bookmarks/twitter',
          queryParameters: queryParams);
      
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['posts'];
      if (list is! List) return [];
      
      return list
          .whereType<Map>()
          .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e),
              currentUserId: currentUserId))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching Twitter bookmarks: $e');
      return [];
    }
  }

  /// Check if a post is bookmarked by current user
static Future<bool> isBookmarked(String postId) async {
    try {
      final userId = await AuthService.currentUserId;
      if (userId == null) return false;

      // This could be implemented as a separate endpoint or 
      // handled by checking in the post list responses
      // For now, we'll assume this is handled by the frontend
      // when posts are fetched with isBookmarked field
      
      return false;
    } catch (e) {
      debugPrint('❌ Error checking bookmark status: $e');
      return false;
    }
  }
}
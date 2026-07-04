import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';
import 'api_client.dart';
import 'comment_service.dart';
import 'storage_service.dart';

class PostService {

  static String _encodeAsDataUrl({
    required Uint8List bytes,
    required bool isVideo,
  }) {
    final base64Data = base64Encode(bytes);
    final mime = isVideo ? 'video/mp4' : 'image/jpeg';
    return 'data:$mime;base64,$base64Data';
  }



  /// Create a new post
  static Future<PostModel?> createPost({
    required String caption,
    Uint8List? imageBytes,
    File? imageFile,
    String postType = 'instagram', // 'instagram' or 'twitter'
  }) async {
    try {
      final userId = await AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      Uint8List? bytes;
      if (imageBytes != null) {
        bytes = imageBytes;
      } else if (imageFile != null) {
        bytes = await imageFile.readAsBytes();
      }

      final payload = <String, dynamic>{
        'caption': caption,
        'post_type': postType,
      };

      if (bytes != null && bytes.isNotEmpty) {
        payload['imageBase64'] = _encodeAsDataUrl(bytes: bytes, isVideo: false);
      }

      final decoded = await ApiClient.post('/posts', body: payload);
      if (decoded is Map<String, dynamic> && decoded['post'] is Map) {
        return PostModel.fromJson(
          Map<String, dynamic>.from(decoded['post'] as Map),
          currentUserId: userId,
        );
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error creating post: $e');
      return null;
    }
  }

  /// Fetch posts for feed
static Future<List<PostModel>> fetchPosts({
    int limit = 20,
    int offset = 0,
    String? postType, // Filter by 'instagram' or 'twitter'
  }) async {
    try {
      final userId = await AuthService.currentUserId;

      final qp = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (postType != null) {
        qp['post_type'] = postType;
      }

      final decoded = await ApiClient.get('/posts', queryParameters: qp);
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['posts'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e),
              currentUserId: userId))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching posts: $e');
      return [];
    }
  }

  /// Fetch user's posts
static Future<List<PostModel>> fetchUserPosts(
    String userId, {
    String? postType, // Filter by 'instagram' or 'twitter'
  }) async {
    try {
      final currentUserId = await AuthService.currentUserId;

      final qp = <String, String>{};
      if (postType != null) {
        qp['post_type'] = postType;
      }

      final decoded = await ApiClient.get('/posts/user/$userId',
          queryParameters: qp.isEmpty ? null : qp);
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['posts'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e),
              currentUserId: currentUserId))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching user posts: $e');
      return [];
    }
  }

  /// Toggle like on a post
static Future<bool> toggleLike(String postId) async {
    try {
      final userId = await AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final decoded = await ApiClient.post('/likes/posts/$postId/like');
      if (decoded is Map<String, dynamic> && decoded['is_liked'] is bool) {
        return decoded['is_liked'] as bool;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error toggling like: $e');
      rethrow;
    }
  }

  /// Add comment to a post
  static Future<CommentModel?> addComment(String postId, String commentText) async {
    try {
      final response = await CommentService.addComment(postId, commentText);
      if (response != null) {
        return CommentModel.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      return null;
    }
  }

  /// Fetch comments for a post
  static Future<List<CommentModel>> fetchComments(String postId) async {
    try {
      final commentsData = await CommentService.getComments(postId);
      return commentsData.map((comment) => CommentModel.fromJson(comment)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching comments: $e');
      return [];
    }
  }

  /// Delete a post with media cleanup
  static Future<void> deletePost(String postId, {String? imageUrl, String? videoUrl}) async {
    try {
      // First, delete media from storage if URLs exist
      final pathsToDelete = <String>[];
      
      if (imageUrl != null) {
        final path = StorageService.extractPathFromUrl(imageUrl);
        if (path != null) pathsToDelete.add(path);
      }
      
      if (videoUrl != null) {
        final path = StorageService.extractPathFromUrl(videoUrl);
        if (path != null) pathsToDelete.add(path);
      }
      
      // Delete from storage (non-blocking)
      if (pathsToDelete.isNotEmpty) {
        StorageService.deleteFiles(pathsToDelete).catchError((e) {
          debugPrint('❌ Storage cleanup error: $e');
        });
      }
      
      // Delete post from database
      await ApiClient.delete('/posts/$postId');
    } catch (e) {
      debugPrint('❌ Error deleting post: $e');
      rethrow;
    }
  }
}


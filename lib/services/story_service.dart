import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/story_model.dart';
import 'auth_service.dart';
import 'api_client.dart';
import 'storage_service.dart';

class StoryService {
  static const Duration storyExpiry = Duration(hours: 24);

  static String _encodeAsDataUrl({
    required Uint8List bytes,
    required bool isVideo,
  }) {
    final base64Data = base64Encode(bytes);
    final mime = isVideo ? 'video/mp4' : 'image/jpeg';
    return 'data:$mime;base64,$base64Data';
  }

  /// Create a new story
static Future<StoryModel?> createStory({
    Uint8List? imageBytes,
    File? imageFile,
    Uint8List? videoBytes,
    File? videoFile,
    String? caption,
  }) async {
    try {
      final userId = await AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      bool isVideo = false;
      Uint8List? bytes;

      if (videoBytes != null) {
        isVideo = true;
        bytes = videoBytes;
      } else if (videoFile != null) {
        isVideo = true;
        bytes = await videoFile.readAsBytes();
      } else if (imageBytes != null) {
        isVideo = false;
        bytes = imageBytes;
      } else if (imageFile != null) {
        isVideo = false;
        bytes = await imageFile.readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('No media provided');
      }

      final payload = <String, dynamic>{
        'mediaType': isVideo ? 'video' : 'image',
        'mediaBase64': _encodeAsDataUrl(bytes: bytes, isVideo: isVideo),
      };
      if (caption != null && caption.trim().isNotEmpty) {
        payload['caption'] = caption.trim();
      }

      final decoded = await ApiClient.post('/stories', body: payload);
      if (decoded is Map<String, dynamic> && decoded['story'] is Map) {
        return StoryModel.fromJson(
            Map<String, dynamic>.from(decoded['story'] as Map));
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error creating story: $e');
      return null;
    }
  }

  /// Fetch active stories from users you follow
static Future<Map<String, List<StoryModel>>> fetchFollowingStories() async {
    try {
      final userId = await AuthService.currentUserId;
      if (userId == null) return {};

      final decoded = await ApiClient.get('/stories/following');
      if (decoded is! Map<String, dynamic>) return {};

      final raw = decoded['stories_by_user'];
      if (raw is! Map) return {};

      final result = <String, List<StoryModel>>{};
      raw.forEach((key, value) {
        if (key is! String) return;
        if (value is! List) return;
        final stories = value
            .whereType<Map>()
            .map((e) => StoryModel.fromJson(Map<String, dynamic>.from(e)))
            .where((s) => !s.isExpired)
            .toList();
        if (stories.isNotEmpty) {
          stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          result[key] = stories;
        }
      });

      if (!result.containsKey(userId)) {
        result[userId] = const <StoryModel>[];
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error fetching stories: $e');
      return {};
    }
  }

  /// Fetch user's stories
  static Future<List<StoryModel>> fetchUserStories(String userId) async {
    try {
      final decoded = await ApiClient.get('/stories/user/$userId');
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['stories'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => StoryModel.fromJson(Map<String, dynamic>.from(e)))
          .where((story) => !story.isExpired)
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching user stories: $e');
      return [];
    }
  }

  /// Delete a story with media cleanup
  static Future<void> deleteStory(String storyId, {String? imageUrl, String? videoUrl}) async {
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
      
      // Delete story from database
      await ApiClient.delete('/stories/$storyId');
    } catch (e) {
      debugPrint('❌ Error deleting story: $e');
      rethrow;
    }
  }

  /// Delete expired stories (should be run periodically)
  static Future<void> deleteExpiredStories() async {
    try {
      // Managed by backend/database policies; keep this as a no-op for now.
      return;
    } catch (e) {
      debugPrint('❌ Error deleting expired stories: $e');
    }
  }
}


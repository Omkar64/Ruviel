import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/reel_model.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'storage_service.dart';


class ReelService {
static Future<List<ReelModel>> getReels({int limit = 20, int offset = 0}) async {
    final res = await ApiClient.get('/reels', queryParameters: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });

    final currentUserId = await AuthService.currentUserId;
    return (res['reels'] as List)
        .map((e) => ReelModel.fromJson(e, currentUserId: currentUserId))
        .toList();
  }


  static Future<List<ReelModel>> getUserReels(String userId, {int limit = 20, int offset = 0}) async {
    final res = await ApiClient.get('/reels/user/$userId', queryParameters: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });

    final currentUserId = await AuthService.currentUserId;
    return (res['reels'] as List)
        .map((e) => ReelModel.fromJson(e, currentUserId: currentUserId))
        .toList();
  }


  static Future<ReelModel?> createReel({
    required Uint8List videoBytes,
    String? caption,
    String? music,
  }) async {
    final base64Video = base64Encode(videoBytes);

    final res = await ApiClient.post('/reels', body: {
      'videoBase64': base64Video,
      'caption': caption,
      'music': music,
    });

    final currentUserId = await AuthService.currentUserId;
    return ReelModel.fromJson(res['reel'], currentUserId: currentUserId);
  }


  static Future<void> like(String reelId) async {
    await ApiClient.post('/reels/$reelId/like');
  }


  static Future<void> unlike(String reelId) async {
    await ApiClient.delete('/reels/$reelId/like');
  }


  static Future<List<Map<String, dynamic>>> getComments(String reelId) async {
    final res = await ApiClient.get('/reels/$reelId/comments');
    return (res['comments'] as List).cast<Map<String, dynamic>>();
  }


  static Future<Map<String, dynamic>> addComment(String reelId, String comment) async {
    final res = await ApiClient.post('/reels/$reelId/comments', body: {
      'comment': comment,
    });
    return res['comment'];
  }

  /// Delete a reel with media cleanup
  static Future<void> deleteReel(String reelId, {String? videoUrl}) async {
    try {
      // First, delete video from storage if URL exists
      if (videoUrl != null) {
        final path = StorageService.extractPathFromUrl(videoUrl);
        if (path != null) {
          // Delete from storage (non-blocking)
          StorageService.deleteFile(path).catchError((e) {
            debugPrint('❌ Storage cleanup error: $e');
          });
        }
      }
      
      // Delete reel from database
      await ApiClient.delete('/reels/$reelId');
    } catch (e) {
      debugPrint('❌ Error deleting reel: $e');
      rethrow;
    }
  }
}
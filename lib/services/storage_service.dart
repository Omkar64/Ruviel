import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Extract file path from Supabase Storage URL
  static String? extractPathFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Handle data URLs (base64) - these don't need storage cleanup
    if (url.startsWith('data:')) return null;
    
    // Handle Supabase Storage URLs
    // Format: https://[project].supabase.co/storage/v1/object/public/[bucket]/[path]
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    
    final segments = uri.pathSegments;
    if (segments.length < 4) return null;
    
    // Find bucket and path
    final storageIndex = segments.indexOf('storage');
    if (storageIndex == -1 || storageIndex + 3 >= segments.length) return null;
    
    final bucket = segments[storageIndex + 3];
    final pathSegments = segments.sublist(storageIndex + 4);
    
    return '$bucket/${pathSegments.join('/')}';
  }

  /// Delete file from Supabase Storage
  static Future<void> deleteFile(String path) async {
    try {
      final segments = path.split('/');
      if (segments.isEmpty) return;
      
      final bucket = segments.first;
      final filePath = segments.sublist(1).join('/');
      
      await _supabase.storage.from(bucket).remove([filePath]);
      debugPrint('✅ Deleted file: $path');
    } catch (e) {
      debugPrint('❌ Error deleting file $path: $e');
      // Don't rethrow - storage cleanup shouldn't break delete operation
    }
  }

  /// Delete multiple files from storage
  static Future<void> deleteFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    
    // Group by bucket for batch operations
    final Map<String, List<String>> filesByBucket = {};
    
    for (final path in paths) {
      final segments = path.split('/');
      if (segments.isEmpty) continue;
      
      final bucket = segments.first;
      final filePath = segments.sublist(1).join('/');
      
      filesByBucket[bucket] = [...(filesByBucket[bucket] ?? []), filePath];
    }
    
    // Delete files in batches by bucket
    for (final entry in filesByBucket.entries) {
      try {
        await _supabase.storage.from(entry.key).remove(entry.value);
        debugPrint('✅ Deleted ${entry.value.length} files from bucket: ${entry.key}');
      } catch (e) {
        debugPrint('❌ Error deleting files from bucket ${entry.key}: $e');
      }
    }
  }

  /// Upload file to Supabase Storage
  static Future<String?> uploadFile({
    required File file,
    required String bucket,
    required String path,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return uploadBytes(bytes: bytes, bucket: bucket, path: path);
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
      return null;
    }
  }

  /// Upload bytes to Supabase Storage
  static Future<String?> uploadBytes({
    required Uint8List bytes,
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).uploadBinary(path, bytes);
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading bytes: $e');
      return null;
    }
  }

  /// Get public URL for a file
  static String? getPublicUrl(String bucket, String path) {
    try {
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('❌ Error getting public URL: $e');
      return null;
    }
  }
}
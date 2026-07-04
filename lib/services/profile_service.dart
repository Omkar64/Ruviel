import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class ProfileService {
  /// Get current user profile
  static Future<UserModel?> getCurrentProfile() async {
    try {
      final response = await ApiClient.get('/profiles/me');
      final userData = response['user'] as Map<String, dynamic>;
      final profileData = response['profile'] as Map<String, dynamic>;
      
      // Combine user and profile data for UserModel
      final combinedData = <String, dynamic>{
        ...profileData,
        'email': userData['email'],
      };
      
      return UserModel.fromJson(combinedData);
    } catch (e) {
      debugPrint('❌ Get current profile error: $e');
      return null;
    }
  }

  /// Get user profile by ID
  static Future<UserModel?> getUserProfileById(String userId) async {
    try {
      final response = await ApiClient.get('/profiles/$userId');
      
      // For public profiles, email might not be available, use empty string
      final profileData = Map<String, dynamic>.from(response);
      profileData['email'] = profileData['email'] ?? '';
      
      return UserModel.fromJson(profileData);
    } catch (e) {
      debugPrint('❌ Get user profile error: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? username,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (username != null) updates['username'] = username;

      await ApiClient.put('/profiles/me', body: updates);
    } catch (e) {
      debugPrint('❌ Update profile error: $e');
      rethrow;
    }
  }

  /// Upload profile image and update profile
  static Future<String?> uploadProfileImage({
    Uint8List? imageBytes,
    File? imageFile,
  }) async {
    try {
      debugPrint('📸 Starting profile image upload...');
      
      String? base64Image;

      if (kIsWeb && imageBytes != null) {
        base64Image = base64Encode(imageBytes);
        debugPrint('🌐 Web: Encoded ${imageBytes.length} bytes');
      } else if (!kIsWeb && imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        base64Image = base64Encode(bytes);
        debugPrint('💻 Desktop: Encoded ${bytes.length} bytes');
      } else {
        throw Exception('No image data provided');
      }

      if (base64Image.length > 10 * 1024 * 1024) {
        throw Exception('Image too large (max 10MB)');
      }

      debugPrint('⬆️ Sending to backend...');
      final response = await ApiClient.post('/profiles/me/image', body: {
        'imageBase64': base64Image,
      });

      final imageUrl = response['profile_image_url'] as String?;
      debugPrint('✅ Upload successful: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('❌ Upload profile image error: $e');
      return null;
    }
  }

  /// Create profile (used during signup fallback)
  static Future<void> createProfile({
    required String id,
    required String email,
    required String username,
    String? fullName,
  }) async {
    try {
      await ApiClient.post('/profiles/me', body: {
        'id': id,
        'email': email,
        'username': username,
        'full_name': fullName ?? '',
        'followers_count': 0,
        'following_count': 0,
        'posts_count': 0,
      });
    } catch (e) {
      debugPrint('❌ Create profile error: $e');
      rethrow;
    }
  }

  /// Check if profile exists for a user
  static Future<bool> profileExists(String userId) async {
    try {
      await ApiClient.get('/profiles/$userId');
      return true;
    } catch (e) {
      return false;
    }
  }
}
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';


class ChatService {
  /// Send message to a receiver
static Future<MessageModel?> sendMessage(String receiverId, String message) async {
    try {
      final senderId = await AuthService.currentUserId;
      if (senderId == null) throw Exception('User not authenticated');

      if (message.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      final decoded = await ApiClient.post('/messages', body: {
        'receiver_id': receiverId,
        'message': message.trim(),
        'message_type': 'text',
      });

      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        final map = Map<String, dynamic>.from(decoded['data'] as Map);
        return MessageModel.fromJson(map);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      return null;
    }
  }

  /// Fetch all messages between current user and another user
static Future<List<MessageModel>> fetchMessages(String otherUserId) async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) return [];

      final decoded = await ApiClient.get('/messages', queryParameters: {
        'otherUserId': otherUserId,
        'limit': '50',
        'offset': '0',
      });

      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['messages'];
      if (list is! List) return [];

      return list.whereType<Map>().map((raw) {
        final map = Map<String, dynamic>.from(raw);
        return MessageModel.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching messages: $e');
      return [];
    }
  }

  /// Mark messages as read
static Future<void> markMessagesAsRead(String senderId) async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) return;

      // Backend marks read automatically when fetching /messages.
      return;
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
    }
  }

  /// Subscribe to new messages in real-time
  static dynamic subscribeToMessages(
    String otherUserId,
    void Function(MessageModel) onNewMessage,
  ) {
    // Option 1 (backend-first): avoid direct Supabase realtime in Flutter.
    // Chat screen can poll fetchMessages if needed.
    return null;
  }

  /// Get list of conversations (users you've messaged or who messaged you)
static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) return [];

      final decoded = await ApiClient.get('/messages/conversations');
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['conversations'];
      if (list is! List) return [];

      // Adapt backend conversation shape to UI expected keys
      return list.whereType<Map>().map((raw) {
        final map = Map<String, dynamic>.from(raw);
        return {
          'user_id': map['other_user_id']?.toString() ?? '',
          'username': map['other_username']?.toString() ?? 'Unknown',
          'profile_image_url': map['other_profile_image_url'],
          'last_message': (map['last_message'] is Map)
              ? (map['last_message']['message']?.toString() ?? '')
              : '',
          'last_message_time': (map['last_message'] is Map)
              ? map['last_message']['created_at']
              : null,
          'unread_count': map['unread_count'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching conversations: $e');
      return [];
    }
  }

static Future<List<UserModel>> getAllUsers() async {
    try {
      final currentUserId = await AuthService.currentUserId;
      if (currentUserId == null) return [];

      final decoded = await ApiClient.get('/messages/users');
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['users'];
      if (list is! List) return [];

      return list.whereType<Map>().map((raw) {
        final map = Map<String, dynamic>.from(raw);
        return UserModel.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      return [];
    }
  }

  /// Get recent chats for share sheet
  static Future<List<UserModel>> getRecentChats(String currentUserId) async {
    try {
      final decoded = await ApiClient.get('/messages/conversations');
      if (decoded is! Map<String, dynamic>) return [];
      final list = decoded['conversations'];
      if (list is! List) return [];

      return list.whereType<Map>().map((raw) {
        final map = Map<String, dynamic>.from(raw);
        return UserModel.fromJson({
          'id': map['other_user_id']?.toString() ?? '',
          'email': '',
          'username': map['other_username']?.toString() ?? 'Unknown',
          'full_name': map['other_full_name'],
          'profile_image_url': map['other_profile_image_url'],
          'followers_count': 0,
          'following_count': 0,
          'posts_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching recent chats: $e');
      return [];
    }
  }

  /// Send post reference to user
  static Future<void> sendPostReference({
    required String senderId,
    required String recipientId,
    required String postId,
    required String postType,
  }) async {
    try {
      await ApiClient.post('/messages', body: {
        'receiver_id': recipientId,
        'message': 'Shared a ${postType} post',
        'message_type': 'post_reference',
        'post_id': postId,
        'post_type': postType,
      });
    } catch (e) {
      debugPrint('❌ Error sending post reference: $e');
      rethrow;
    }
  }
}

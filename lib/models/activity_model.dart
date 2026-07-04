enum ActivityType {
  like,
  comment,
  follow,
  mention,
}

class ActivityModel {
  final String id;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final ActivityType type;
  final String? postId;
  final String? postImageUrl;
  final String? commentText;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.type,
    this.postId,
    this.postImageUrl,
    this.commentText,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] is Map
        ? json['profiles'] as Map<String, dynamic>?
        : null;
    
    final postData = json['posts'] is Map
        ? json['posts'] as Map<String, dynamic>?
        : null;

    return ActivityModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 
          profileData?['username'] as String? ?? 
          'Unknown',
      profileImageUrl: json['profile_image_url'] as String? ?? 
          profileData?['profile_image_url'] as String?,
      type: _parseActivityType(json['type'] as String),
      postId: json['post_id'] as String?,
      postImageUrl: json['post_image_url'] as String? ?? 
          postData?['image_url'] as String?,
      commentText: json['comment_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  static ActivityType _parseActivityType(String type) {
    switch (type) {
      case 'like':
        return ActivityType.like;
      case 'comment':
        return ActivityType.comment;
      case 'follow':
        return ActivityType.follow;
      case 'mention':
        return ActivityType.mention;
      default:
        return ActivityType.like;
    }
  }

  String get actionText {
    switch (type) {
      case ActivityType.like:
        return 'liked your post';
      case ActivityType.comment:
        return 'commented: ${commentText ?? ""}';
      case ActivityType.follow:
        return 'started following you';
      case ActivityType.mention:
        return 'mentioned you';
    }
  }
}


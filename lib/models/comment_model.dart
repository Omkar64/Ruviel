class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] is Map
        ? json['profiles'] as Map<String, dynamic>?
        : null;

    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 
          profileData?['username'] as String? ?? 
          'Unknown',
      profileImageUrl: json['profile_image_url'] as String? ?? 
          profileData?['profile_image_url'] as String?,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'profile_image_url': profileImageUrl,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}


class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final String? imageUrl;
  final String? videoUrl;
  final String? caption;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime expiresAt;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    this.updatedAt,
    required this.expiresAt,
    this.caption,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] is Map
        ? json['profiles'] as Map<String, dynamic>?
        : null;

    return StoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 
          profileData?['username'] as String? ?? 
          'Unknown',
      profileImageUrl: json['profile_image_url'] as String? ?? 
          profileData?['profile_image_url'] as String?,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'profile_image_url': profileImageUrl,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get hasVideo => (videoUrl ?? '').isNotEmpty;

  String get mediaUrl => hasVideo
      ? videoUrl!
      : (imageUrl ?? '');
}


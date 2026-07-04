enum PostType {
  instagram,
  twitter,
}

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final String? caption;
  final String? imageUrl;
  final String? videoUrl;
  final PostType postType;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    this.caption,
    this.imageUrl,
    this.videoUrl,
    this.postType = PostType.instagram,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.createdAt,
    this.updatedAt,
  });

  // ✅ convenience getters
  bool get isInstagram => postType == PostType.instagram;
  bool get isTwitter => postType == PostType.twitter;

  // ✅ factory parser from backend JSON
  factory PostModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    // joined profile support (optional)
    final profileData = json['profiles'] is Map
        ? json['profiles'] as Map<String, dynamic>?
        : null;

    // likes handling (can be count or list)
    List? likesList;
    final likesData = json['likes'];
    if (likesData is List) {
      likesList = likesData;
    } else if (likesData is Map) {
      likesList = [likesData];
    } else {
      likesList = null;
    }

    final likesCount =
        (json['likes_count'] as num?)?.toInt() ?? likesList?.length ?? 0;

     // detect if current user liked
     final isLiked = currentUserId != null && likesList != null
         ? likesList.any(
             (like) =>
                 (like is Map && like['user_id'] == currentUserId) ||
                 (like is String && like == currentUserId),
           )
         : false;

     // detect if current user bookmarked
     final isBookmarked = json['is_bookmarked'] as bool? ?? false;

     // comments handling - can be count or list
     final commentsData = json['comments'];
     int commentsCount;
     if (json['comments_count'] is num) {
       commentsCount = (json['comments_count'] as num).toInt();
     } else if (commentsData is List) {
       commentsCount = commentsData.length;
     } else if (commentsData is int) {
       commentsCount = commentsData;
     } else {
       commentsCount = 0;
     }

     return PostModel(
       id: json['id']?.toString() ?? '',
       userId: json['user_id']?.toString() ?? '',
       username: json['username'] as String? ??
           profileData?['username'] as String? ??
           'Unknown',
       profileImageUrl: json['profile_image_url'] as String? ??
           profileData?['profile_image_url'] as String?,
       caption: json['caption'] as String?,
       imageUrl: json['image_url'] as String?,
       videoUrl: json['video_url'] as String?,

       // ✅ safely map backend string → enum
       postType: _mapPostType(json['post_type'] as String?),

       likesCount: likesCount,
       commentsCount: commentsCount,
        isLiked: isLiked,
        isBookmarked: isBookmarked,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
       updatedAt: json['updated_at'] != null
           ? DateTime.parse(json['updated_at'] as String).toLocal()
           : null,
     );
  }

  // ✅ enum mapper
  static PostType _mapPostType(String? type) {
    switch (type) {
      case 'twitter':
        return PostType.twitter;
      default:
        return PostType.instagram;
    }
  }

  // ✅ convert enum → backend string
  String get postTypeString =>
      postType == PostType.twitter ? 'twitter' : 'instagram';

  // ✅ toJson for uploads / updates
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'profile_image_url': profileImageUrl,
      'caption': caption,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'post_type': postTypeString,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ✅ required for like toggling & other UI updates
  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? profileImageUrl,
    String? caption,
    String? imageUrl,
    String? videoUrl,
    PostType? postType,
     int? likesCount,
     int? commentsCount,
     bool? isLiked,
     bool? isBookmarked,
     DateTime? createdAt,
     DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      postType: postType ?? this.postType,
       likesCount: likesCount ?? this.likesCount,
       commentsCount: commentsCount ?? this.commentsCount,
       isLiked: isLiked ?? this.isLiked,
       isBookmarked: isBookmarked ?? this.isBookmarked,
       createdAt: createdAt ?? this.createdAt,
       updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

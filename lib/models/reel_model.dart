class ReelModel {
final String id;
final String userId;
final String username;
final String? profileImageUrl;
final String videoUrl;
final String? caption;
final String? music;
int likesCount;
int commentsCount;
bool isLiked;


ReelModel({
required this.id,
required this.userId,
required this.username,
required this.videoUrl,
this.profileImageUrl,
this.caption,
this.music,
this.likesCount = 0,
this.commentsCount = 0,
this.isLiked = false,
});


factory ReelModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
return ReelModel(
id: json['id'],
userId: json['user_id'],
username: json['username'],
profileImageUrl: json['profile_image_url'],
videoUrl: json['video_url'],
caption: json['caption'],
music: json['music'],
likesCount: json['likes_count'] ?? 0,
commentsCount: json['comments_count'] ?? 0,
isLiked: json['is_liked'] ?? false,
);
}
}
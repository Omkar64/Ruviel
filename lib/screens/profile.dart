import 'dart:io' show File;
import 'package:flutter/material.dart';
import '../utils/image_picker_stub.dart'
    if (dart.library.html) '../utils/image_picker_web.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/story_service.dart';
import '../services/follow_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import 'select_post_type_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'create_story_screen.dart';
import 'story_viewer_screen.dart';
import 'profile_reels_screen.dart';
import '../widgets/post_modal.dart';
import '../widgets/purple_story_ring.dart';
import '../themes/purple_theme.dart';
import 'instagram_saved_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  UserModel? userProfile;
  List<PostModel> posts = [];
  bool isLoading = true;
  bool isFollowing = false;
  bool isFollowLoading = false;
  late TabController _tabController;
  String? _currentUserId;

  bool get isCurrentUser => widget.userId == null || widget.userId == _currentUserId;

@override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserId();
    _loadProfile();
  }

  Future<void> _loadUserId() async {
    _currentUserId = await AuthService.currentUserId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _changeProfilePicture() async {
    if (userProfile == null) return;

    try {
      final result = await ImagePickerHelper.pickImage();
      if (result == null) return;

      Uint8List? imageBytes;
      File? imageFile;

      if (result['isWeb'] == true) {
        imageBytes = result['bytes'] as Uint8List?;
      } else {
        imageFile = result['file'] as File?;
      }

      setState(() => isLoading = true);

      final url = await AuthService.uploadProfileImage(
        imageBytes: imageBytes,
        imageFile: imageFile,
      );

      if (!mounted) return;
      if (url != null) {
        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')), 
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile picture')), 
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final profile = isCurrentUser 
          ? await AuthService.getCurrentUserProfile()
          : await AuthService.getUserProfileById(widget.userId!);
          
      if (profile != null) {
        // Only fetch Instagram posts for profile
        final userPosts = await PostService.fetchUserPosts(
          profile.id,
          postType: 'instagram',
        );
        
        // Check follow status for other users
        bool followStatus = false;
        if (!isCurrentUser) {
          followStatus = await FollowService.isFollowing(profile.id);
        }
        
        if (mounted) {
          setState(() {
            userProfile = profile;
            posts = userPosts;
            isFollowing = followStatus;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    if (userProfile == null) return;

    final nameController = TextEditingController(text: userProfile!.fullName ?? '');
    final bioController = TextEditingController(text: userProfile!.bio ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _changeProfilePicture,
              child: const Text("Change profile photo"),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: "Bio"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await AuthService.updateProfile(
          fullName: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
          bio: bioController.text.trim().isEmpty ? null : bioController.text.trim(),
        );
        if (mounted) {
          _loadProfile(); // Reload profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }

  Future<void> _addNewPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectPostTypeScreen()),
    );
    
    if (result == true) {
      _loadProfile(); // Reload posts
    }
  }

  Future<void> _toggleFollow() async {
    if (userProfile == null || isCurrentUser) return;
    
    final wasFollowing = isFollowing;
    final targetUserId = userProfile!.id;
    
    setState(() => isFollowLoading = true);
    
    // Optimistic UI updates - update counts immediately
    setState(() {
      isFollowing = !wasFollowing;
      
      // Update follower count on the profile being viewed
      if (userProfile != null) {
        if (wasFollowing) {
          // Unfollowing: decrement their followers count
          userProfile = UserModel(
            id: userProfile!.id,
            email: userProfile!.email,
            username: userProfile!.username,
            fullName: userProfile!.fullName,
            bio: userProfile!.bio,
            profileImageUrl: userProfile!.profileImageUrl,
            followersCount: userProfile!.followersCount - 1,
            followingCount: userProfile!.followingCount,
            postsCount: userProfile!.postsCount,
            createdAt: userProfile!.createdAt,
            updatedAt: userProfile!.updatedAt,
          );
        } else {
          // Following: increment their followers count
          userProfile = UserModel(
            id: userProfile!.id,
            email: userProfile!.email,
            username: userProfile!.username,
            fullName: userProfile!.fullName,
            bio: userProfile!.bio,
            profileImageUrl: userProfile!.profileImageUrl,
            followersCount: userProfile!.followersCount + 1,
            followingCount: userProfile!.followingCount,
            postsCount: userProfile!.postsCount,
            createdAt: userProfile!.createdAt,
            updatedAt: userProfile!.updatedAt,
          );
        }
      }
    });
    
    try {
      if (wasFollowing) {
        await FollowService.unfollowUser(targetUserId);
      } else {
        await FollowService.followUser(targetUserId);
      }
    } catch (e) {
      // Revert optimistic updates on error
      if (mounted) {
        setState(() {
          isFollowing = wasFollowing;
          
          // Revert the follower count change
          if (userProfile != null) {
            userProfile = UserModel(
              id: userProfile!.id,
              email: userProfile!.email,
              username: userProfile!.username,
              fullName: userProfile!.fullName,
              bio: userProfile!.bio,
              profileImageUrl: userProfile!.profileImageUrl,
              followersCount: wasFollowing 
                  ? userProfile!.followersCount + 1 
                  : userProfile!.followersCount - 1,
              followingCount: userProfile!.followingCount,
              postsCount: userProfile!.postsCount,
              createdAt: userProfile!.createdAt,
              updatedAt: userProfile!.updatedAt,
            );
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => isFollowLoading = false);
    }
  }

  void _openPost(PostModel post) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: PostModal(post: post),
        );
      },
    );
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text("Saved"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await AuthService.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareProfile() {
    if (userProfile == null) return;
    Clipboard.setData(ClipboardData(text: "https://ruviel.app/${userProfile!.username}"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile link copied to clipboard!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (userProfile == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Profile"),
          backgroundColor: theme.appBarTheme.backgroundColor,
        ),
        body: const Center(
          child: Text("Failed to load profile"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          userProfile!.username,
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: false,
        actions: [
          if (isCurrentUser) ...[
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: Colors.black, size: 28),
              onPressed: _addNewPost,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 28),
              onPressed: _openMenu,
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: Column(
        children: [
          // Profile header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    PurpleStoryRing(
                      imageUrl: userProfile!.profileImageUrl ?? 'placeholder',
                      username: userProfile!.username,
                      size: 80,
                      onTap: isCurrentUser ? () async {
                        // Tap on avatar: if user has stories, view; else create
                        final stories = await StoryService.fetchUserStories(userProfile!.id);
                        if (!context.mounted) return;

                        if (stories.isEmpty) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateStoryScreen(),
                            ),
                          );
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoryViewerScreen(
                                stories: stories,
                                userId: userProfile!.id,
                              ),
                            ),
                          );
                        }
                      } : () async {
                        // For other users, just view stories if available
                        final stories = await StoryService.fetchUserStories(userProfile!.id);
                        if (!context.mounted) return;

                        if (stories.isNotEmpty) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoryViewerScreen(
                                stories: stories,
                                userId: userProfile!.id,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          "${userProfile!.postsCount}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text("Posts"),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        Text(
                          "${userProfile!.followersCount}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                        const Text("Followers"),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        Text(
                          "${userProfile!.followingCount}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                        const Text("Following"),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile!.fullName ?? userProfile!.username,
                        style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    ),
                    if (userProfile!.bio != null && userProfile!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                      Text(
                        userProfile!.bio!,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (isCurrentUser) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _editProfile,
                          child: Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: theme.textTheme.labelLarge?.color ?? Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _shareProfile,
                          child: Text(
                            "Share Profile",
                            style: TextStyle(
                              color: theme.textTheme.labelLarge?.color ?? Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: isFollowing 
                            ? PurpleButton(
                                text: "Following",
                                onPressed: _toggleFollow,
                                isLoading: isFollowLoading,
                                isOutlined: true,
                              )
                            : PurpleButton(
                                text: "Follow",
                                onPressed: _toggleFollow,
                                isLoading: isFollowLoading,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _shareProfile,
                          child: Text(
                            "Share Profile",
                            style: TextStyle(
                              color: theme.textTheme.labelLarge?.color ?? Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 0),
              TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.onBackground,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.video_collection_outlined)),
                  Tab(icon: Icon(Icons.bookmark)),
                  Tab(icon: Icon(Icons.person_pin_outlined)),
                ],
              ),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Posts tab
                posts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No posts yet",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return GestureDetector(
                            onTap: () => _openPost(post),
                            child: Container(
                              child: post.imageUrl != null
                                  ? Image.network(
                                      post.imageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    ),
                            ),
                          );
                        },
                      ),
                
                // Reels tab - Instagram style vertical feed
                ProfileReelsScreen(userId: userProfile!.id),
                
                // Saved posts tab - Only for current user
                isCurrentUser 
                    ? const InstagramSavedScreen()
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "Private saved posts",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                
                // Tagged tab
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_pin_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Tagged posts",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

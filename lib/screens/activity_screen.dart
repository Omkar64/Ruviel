import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import 'profile.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  Timer? _pollTimer;
  String? _currentUserId;

@override
  void initState() {
    super.initState();
    _loadUserId();
    _loadActivities();
    // Start a periodic poll so activity list refreshes automatically.
    // Polling avoids realtime SDK compatibility across environments.
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) _loadActivities();
    });
  }

  Future<void> _loadUserId() async {
    _currentUserId = await AuthService.currentUserId;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activities = await ActivityService.fetchActivity(postType: 'instagram');
      if (mounted) {
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load activities')),
          );
        }
      }
    }
  }

void _handleFollowBack(String userId) async {
    try {
      // Optimistically add a follow activity locally so user sees immediate feedback
      final currentUserId = await AuthService.currentUserId;
      final optimistic = ActivityModel(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUserId ?? 'me',
        username: 'You',
        profileImageUrl: null,
        type: ActivityType.follow,
        postId: null,
        postImageUrl: null,
        commentText: null,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _activities.insert(0, optimistic);
        });
      }

      // Perform follow via FollowService
      await FollowService.followUser(userId);

      // Create an activity record for the follow on the server
      await ActivityService.createActivity(
        type: ActivityType.follow,
        targetUserId: userId,
      );

      // Refresh server-side activities to sync IDs/timestamps
      await _loadActivities();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Followed back!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to follow back: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Group activities by time
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));

    final todayActivities = _activities.where((activity) => 
      activity.createdAt.isAfter(today)).toList();
    
    final thisWeekActivities = _activities.where((activity) => 
      activity.createdAt.isAfter(weekAgo) && 
      !activity.createdAt.isAfter(today)).toList();
      
    final earlierActivities = _activities.where((activity) => 
      !activity.createdAt.isAfter(weekAgo)).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "Activity",
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 1000;
                final left = RefreshIndicator(
                  onRefresh: _loadActivities,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
// Debug banner: shows current user id and fetched count
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'User: ${_currentUserId ?? 'not signed in'} — Activities fetched: ${_activities.length}',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (kDebugMode)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: OutlinedButton(
                              onPressed: () async {
                                // Create a small test activity and reload
                                final current = await AuthService.currentUserId;
                                if (current == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
                                  }
                                  return;
                                }

                                await ActivityService.createActivity(
                                  type: ActivityType.like,
                                  targetUserId: current,
                                  commentText: 'debug-test',
                                );

                                await _loadActivities();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inserted test activity')));
                                }
                              },
                              child: const Text('Insert test'),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_activities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No activities yet. If you expect items, check Supabase `activities` table for rows with target_user_id or user_id equal to your user id.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),

                  if (todayActivities.isNotEmpty) ...[
                    const SectionHeader(title: "Today"),
...todayActivities.map((activity) => ActivityTile(
                      activity: activity,
                      onFollowBack: _handleFollowBack,
                      currentUserId: _currentUserId,
                    )).toList(),
                  ],
                  if (thisWeekActivities.isNotEmpty) ...[
                    const SectionHeader(title: "This Week"),
...thisWeekActivities.map((activity) => ActivityTile(
                      activity: activity,
                      onFollowBack: _handleFollowBack,
                      currentUserId: _currentUserId,
                    )).toList(),
                  ],
                  if (earlierActivities.isNotEmpty) ...[
                    const SectionHeader(title: "Earlier"),
...earlierActivities.map((activity) => ActivityTile(
                      activity: activity,
                      onFollowBack: _handleFollowBack,
                      currentUserId: _currentUserId,
                    )).toList(),
                  ],
                    ],
                  ),
                );

                // Keep a single-column layout for ActivityScreen. The
                // trending/news sidebar is intentionally omitted here so it
                // appears only on Twitter-related screens.
                if (!isLargeScreen) {
                  return left;
                }

                // For large screens, add some right padding so content
                // doesn't feel cramped, but do not render the sidebar.
                return Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: left,
                );
              },
            ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final ActivityModel activity;
  final Function(String) onFollowBack;
  final String? currentUserId;

  const ActivityTile({
    super.key,
    required this.activity,
    required this.onFollowBack,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFollow = activity.type == ActivityType.follow;
    final isCurrentUser = activity.userId == currentUserId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: GestureDetector(
        onTap: () {
          if (!isCurrentUser) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: activity.userId),
              ),
            );
          }
        },
        child: CircleAvatar(
          radius: 24,
          backgroundImage: activity.profileImageUrl != null
              ? NetworkImage(activity.profileImageUrl!) as ImageProvider
              : const AssetImage('assets/images/story1.jpg'),
        ),
      ),
      title: RichText(
        text: TextSpan(
          style: TextStyle(
            color: theme.colorScheme.onBackground, 
            fontSize: 15,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: activity.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: " "),
            TextSpan(text: activity.actionText),
          ],
        ),
      ),
      subtitle: Text(
        timeago.format(activity.createdAt, allowFromNow: true),
        style: TextStyle(color: theme.hintColor, fontSize: 12),
      ),
      trailing: isFollow && !isCurrentUser
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => onFollowBack(activity.userId),
              child: const Text(
                "Follow back",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : (activity.postImageUrl != null && activity.type != ActivityType.follow
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    activity.postImageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 20),
                    ),
                  ),
                )
              : null),
    );
  }
}

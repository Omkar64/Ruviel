import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  UserModel? selectedUser;

  @override
  Widget build(BuildContext context) {
    final isLarge = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isLarge
          ? null
          : AppBar(
              elevation: 1,
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Text(
                "Direct Messages",
                style: theme.appBarTheme.titleTextStyle,
              ),
            ),
      body: isLarge
          ? Row(
              children: [
                SizedBox(width: 300, child: _buildConversationList(true)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selectedUser == null
                      ? const Center(
                          child: Text(
                            "Select a conversation",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ChatScreenLive(
                          key: ValueKey(selectedUser!.id),
                          otherUser: selectedUser!,
                          isEmbedded: true,
                        ),
                ),
              ],
            )
          : _buildConversationList(false),
    );
  }

  Widget _buildConversationList(bool isLarge) {
    TextEditingController searchController = TextEditingController();
    String searchQuery = "";

    return StatefulBuilder(
      builder: (context, setStateSB) {
        return Column(
          children: [
            // 🔎 Search Bar
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setStateSB(() {
                    searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search users",
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            Expanded(
              child: FutureBuilder(
                future: _buildCombinedUserList(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final combinedList = snap.data as List<Map<String, dynamic>>;

                  // 🔎 Apply search filter
                  List<Map<String, dynamic>> filteredList = combinedList;
                  if (searchQuery.isNotEmpty) {
                    filteredList = combinedList.where((item) {
                      final name = item["username"]?.toString().toLowerCase() ?? "";
                      return name.contains(searchQuery);
                    }).toList();
                  }

                  if (filteredList.isEmpty) {
                    return const Center(child: Text("No users match your search"));
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, i) {
                      final item = filteredList[i];
                      final isConversation = item["is_conversation"] == true;
                      
                      final user = UserModel(
                        id: item['user_id']?.toString() ?? '',
                        email: '',
                        username: item['username']?.toString() ?? 'Unknown',
                        profileImageUrl: item['profile_image_url']?.toString(),
                        createdAt: DateTime.now(),
                      );

                      return Column(
                        children: [
                          // Section header
                          if (i == 0 && isConversation)
                            _buildSectionHeader("Messages", Icons.message)
                          else if (i > 0 && 
                                   filteredList[i-1]["is_conversation"] != isConversation &&
                                   !isConversation)
                            _buildSectionHeader("Start New Chat", Icons.person_add),
                          
                          // User list item
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : const AssetImage("assets/images/story1.jpg")
                                      as ImageProvider,
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: isConversation 
                                ? Text(item['last_message'] ?? "No messages")
                                : const Text("Start chat"),
                            trailing: isConversation && item['unread_count'] > 0
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${item['unread_count']}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              if (isLarge) {
                                setState(() => selectedUser = user);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreenLive(
                                      key: ValueKey(user.id),
                                      otherUser: user,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _buildCombinedUserList() async {
    try {
      // Fetch both conversations and all users
      final futures = await Future.wait([
        ChatService.getConversations(),
        ChatService.getAllUsers(),
      ]);

      final conversations = futures[0] as List<Map<String, dynamic>>;
      final allUsers = futures[1] as List<UserModel>;

      // Get set of user IDs from conversations
      final conversationUserIds = conversations
          .map((c) => c['user_id']?.toString())
          .where((id) => id != null)
          .toSet();

      // Filter out users who are already in conversations
      final newUsers = allUsers
          .where((user) => !conversationUserIds.contains(user.id))
          .map((user) => {
                'user_id': user.id,
                'username': user.username,
                'profile_image_url': user.profileImageUrl,
                'is_conversation': false,
                'last_message': null,
                'unread_count': 0,
              })
          .toList();

      // Mark conversations and sort by last message time
      final processedConversations = conversations
          .map((c) => {...c, 'is_conversation': true})
          .toList();

      // Sort conversations by last message time (most recent first)
      processedConversations.sort((a, b) {
        final aTime = a['last_message_time'];
        final bTime = b['last_message_time'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return DateTime.parse(bTime).toLocal().compareTo(DateTime.parse(aTime).toLocal());
      });

      // Sort new users alphabetically
      newUsers.sort((a, b) {
        final aName = a['username']?.toString().toLowerCase() ?? '';
        final bName = b['username']?.toString().toLowerCase() ?? '';
        return aName.compareTo(bName);
      });

      // Combine: conversations first, then new users
      return [...processedConversations, ...newUsers];
    } catch (e) {
      debugPrint('❌ Error building combined user list: $e');
      return [];
    }
  }

  }


class ChatScreenLive extends StatefulWidget {
  final UserModel otherUser;
  final bool isEmbedded;

  const ChatScreenLive({
    super.key,
    required this.otherUser,
    this.isEmbedded = false,
  });

  @override
  State<ChatScreenLive> createState() => _ChatScreenLiveState();
}

class _ChatScreenLiveState extends State<ChatScreenLive> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<MessageModel> _messages = [];
  dynamic _channel;
  String? _currentUserId;

@override
  void initState() {
    super.initState();
    debugPrint('ChatScreenLive initState for user: ${widget.otherUser.id}');
    _loadUserId();
    _loadMessages();
    _subscribe();
  }

  Future<void> _loadUserId() async {
    _currentUserId = await AuthService.currentUserId;
  }

  @override
  void didUpdateWidget(ChatScreenLive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.otherUser.id != widget.otherUser.id) {
      debugPrint('ChatScreenLive didUpdateWidget - user changed from ${oldWidget.otherUser.id} to ${widget.otherUser.id}');
      _cleanup();
      _loadMessages();
      _subscribe();
    }
  }

  void _cleanup() {
    _channel?.unsubscribe();
    _messages.clear();
    _controller.clear();
  }

  Future<void> _loadMessages() async {
    _messages =
        await ChatService.fetchMessages(widget.otherUser.id);
    setState(() {});
    _scrollToBottom();
  }

  void _subscribe() {
    _channel = ChatService.subscribeToMessages(
      widget.otherUser.id,
      (msg) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    final msg =
        await ChatService.sendMessage(widget.otherUser.id, text);

    if (msg != null) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _cleanup();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final header = Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: widget.otherUser.profileImageUrl != null
              ? NetworkImage(widget.otherUser.profileImageUrl!)
              : const AssetImage("assets/images/story1.jpg")
                  as ImageProvider,
        ),
        const SizedBox(width: 8),
        Text(widget.otherUser.username,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );

    final input = Container(
      padding: const EdgeInsets.all(8),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Message...",
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: theme.colorScheme.primary),
            onPressed: _send,
          ),
        ],
      ),
    );

    final messages = Expanded(
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length,
itemBuilder: (context, i) {
          final msg = _messages[i];
          final isMe = msg.senderId == _currentUserId;

          return Align(
            alignment:
                isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary.withOpacity(0.25)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                msg.message,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        },
      ),
    );

    if (widget.isEmbedded) {
      return Column(
        children: [
          Container(
              padding: const EdgeInsets.all(12), child: header),
          const Divider(height: 1),
          messages,
          input,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        title: header,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [messages, input],
      ),
    );
  }
}

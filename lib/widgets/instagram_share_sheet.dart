import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruviel/models/post_model.dart';
import 'package:ruviel/models/user_model.dart';
import 'package:ruviel/services/chat_service.dart';
import 'package:ruviel/services/auth_service.dart';
import 'package:ruviel/themes/purple_theme.dart';
import 'package:ruviel/utils/share_helper_stub.dart'
    if (dart.library.html) 'package:ruviel/utils/share_helper_web.dart'
    if (dart.library.io) 'package:ruviel/utils/share_helper_mobile.dart';

class InstagramShareSheet extends StatefulWidget {
  final PostModel post;
  final VoidCallback onClose;

  const InstagramShareSheet({
    super.key,
    required this.post,
    required this.onClose,
  });

  @override
  State<InstagramShareSheet> createState() => _InstagramShareSheetState();
}

class _InstagramShareSheetState extends State<InstagramShareSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _recentUsers = [];
  List<UserModel> _filteredUsers = [];
  List<String> _selectedUserIds = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadRecentUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredUsers = _recentUsers.where((user) =>
        user.username.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        user.displayName.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    });
  }

  Future<void> _loadRecentUsers() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await AuthService.getCurrentUserProfile();
      if (currentUser != null) {
        final recentChats = await ChatService.getRecentChats(currentUser.id);
        setState(() {
          _recentUsers = recentChats;
          _filteredUsers = recentChats;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _sendToSelectedUsers() async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final currentUser = await AuthService.getCurrentUserProfile();
      if (currentUser != null) {
        int successCount = 0;
        List<String> failedUsers = [];
        
        for (final userId in _selectedUserIds) {
          try {
            await ChatService.sendPostReference(
              senderId: currentUser.id,
              recipientId: userId,
              postId: widget.post.id,
              postType: widget.post.isTwitter ? 'twitter' : 'instagram',
            );
            successCount++;
          } catch (userError) {
            failedUsers.add(userId);
            debugPrint('Failed to send to user $userId: $userError');
          }
        }
        
        if (mounted) {
          if (successCount == _selectedUserIds.length) {
            // All successful
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sent to ${successCount} user${successCount == 1 ? '' : 's'}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            widget.onClose();
          } else if (successCount > 0) {
            // Partial success
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sent to $successCount of ${_selectedUserIds.length} users'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
            widget.onClose();
          } else {
            // All failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to send message. Please check your connection and try again.'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _sendToSelectedUsers(),
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to send messages'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _sendToSelectedUsers(),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _copyLink() async {
    try {
      final shareUrl = 'https://instagram.com/p/${widget.post.id}';
      await Clipboard.setData(ClipboardData(text: shareUrl));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareToExternal(String platform) async {
    final shareUrl = 'https://instagram.com/p/${widget.post.id}';
    final shareText = widget.post.caption != null && widget.post.caption!.isNotEmpty 
        ? widget.post.caption! 
        : 'Check out this post!';
    final shareTitle = 'Instagram Post';

    bool success = false;
    String errorMessage = '';
    
    try {
      switch (platform.toLowerCase()) {
        case 'facebook':
          success = await ShareHelper.shareToFacebook(url: shareUrl, quote: shareText);
          errorMessage = 'Could not open Facebook. Please make sure Facebook is installed.';
          break;
        case 'messenger':
          success = await ShareHelper.shareToMessenger(text: shareText, url: shareUrl);
          errorMessage = 'Could not open Messenger. Please make sure Messenger is installed.';
          break;
        case 'whatsapp':
          success = await ShareHelper.shareToWhatsApp(text: shareText, url: shareUrl);
          errorMessage = 'Could not open WhatsApp. Please make sure WhatsApp is installed.';
          break;
        case 'email':
          success = await ShareHelper.shareViaEmail(
            subject: shareTitle,
            body: '$shareText\n\n$shareUrl',
          );
          errorMessage = 'Could not open email app. Please check your email configuration.';
          break;
        case 'x':
        case 'twitter':
          success = await ShareHelper.shareToTwitter(text: shareText, url: shareUrl);
          errorMessage = 'Could not open X/Twitter. Please make sure the app is installed.';
          break;
        case 'threads':
          success = await ShareHelper.shareToThreads(text: shareText, url: shareUrl);
          errorMessage = 'Could not open Threads. Please make sure the app is installed.';
          break;
        case 'more':
          success = await ShareHelper.share(
            title: shareTitle,
            text: shareText,
            url: shareUrl,
          );
          errorMessage = 'Share dialog could not be opened. Please try again.';
          break;
        default:
          success = await ShareHelper.share(
            title: shareTitle,
            text: shareText,
            url: shareUrl,
          );
          errorMessage = 'Sharing failed. Please try again.';
      }
    } catch (e) {
      debugPrint('Error sharing to $platform: $e');
      errorMessage = 'An unexpected error occurred. Please try again.';
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared to $platform'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onClose();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage.isNotEmpty ? errorMessage : 'Failed to share to $platform'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _shareToExternal(platform),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget content = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(isDark),
          
          // DM Share Section
          _buildDMShareSection(isDark),
          
          // External Share Section
          _buildExternalShareSection(isDark),
        ],
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? MediaQuery.of(context).size.width : 500,
          maxHeight: 700,
        ),
        child: content,
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            'Share',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildDMShareSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recipient List
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No users found',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send to',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final isSelected = _selectedUserIds.contains(user.id);
                    
                    return GestureDetector(
                      onTap: () => _toggleUserSelection(user.id),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: user.profileImageUrl != null
                                    ? NetworkImage(user.profileImageUrl!)
                                    : null,
                                child: user.profileImageUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 28,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      )
                                    : null,
                              ),
                              if (isSelected)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: PurpleTheme.primaryPurple,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF1A1A1F) : Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected 
                                ? PurpleTheme.primaryPurple
                                : (isDark ? Colors.white : Colors.black),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          
          // Send Button
          if (_selectedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendToSelectedUsers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PurpleTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Send to ${_selectedUserIds.length}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExternalShareSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share to',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // External Share Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareOption(
                icon: Icons.link,
                label: 'Copy link',
                onTap: _copyLink,
                isDark: isDark,
              ),
              _buildShareOption(
                icon: Icons.facebook,
                label: 'Facebook',
                onTap: () => _shareToExternal('Facebook'),
                isDark: isDark,
              ),
              _buildShareOption(
                icon: Icons.message,
                label: 'Messenger',
                onTap: () => _shareToExternal('Messenger'),
                isDark: isDark,
              ),
              _buildShareOption(
                icon: Icons.message,
                label: 'WhatsApp',
                onTap: () => _shareToExternal('WhatsApp'),
                isDark: isDark,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareOption(
                icon: Icons.email,
                label: 'Email',
                onTap: () => _shareToExternal('Email'),
                isDark: isDark,
              ),
              if (!widget.post.isTwitter)
_buildShareOption(
                icon: Icons.chat,
                label: 'Threads',
                onTap: () => _shareToExternal('Threads'),
                isDark: isDark,
              ),
              if (widget.post.isTwitter)
                _buildShareOption(
                  icon: Icons.flutter_dash,
                  label: 'X',
                  onTap: () => _shareToExternal('X'),
                  isDark: isDark,
                ),
              _buildShareOption(
                icon: Icons.more_horiz,
                label: 'More',
                onTap: () => _shareToExternal('More'),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: PurpleTheme.primaryPurple,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Helper function to show the share sheet
void showInstagramShareSheet(BuildContext context, PostModel post) {
  final isMobile = MediaQuery.of(context).size.width < 600;

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InstagramShareSheet(
        post: post,
        onClose: () => Navigator.pop(context),
      ),
    );
  } else {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => InstagramShareSheet(
        post: post,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
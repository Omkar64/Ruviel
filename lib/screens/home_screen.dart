import 'package:flutter/material.dart';
import 'activity_screen.dart';
import 'feed_screen.dart';
import 'profile.dart';
import 'reels_screen.dart';
import 'search_screen.dart';
import 'chat_screen.dart';
import 'twitter_shell_screen.dart';
import 'login_screen.dart';
import 'select_post_type_screen.dart';
import 'create_story_screen.dart';
import '../services/auth_service.dart';
import '../themes/purple_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    const ReelsScreen(),
    const ActivityScreen(),
    const ProfileScreen(),
    const ChatScreen(),
  ];

  // Helper to convert screen index to navigation index
  // Navigation has: [Home, Search, Create, Reels, Activity, Profile, Chat, Tweet]
  // Screens array has: [Home, Search, Reels, Activity, Profile, Chat, Tweet]
  int _getNavigationIndex(int screenIndex) {
    // After index 1 (Search), add 1 for Create button
    return screenIndex >= 2 ? screenIndex + 1 : screenIndex;
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive breakpoints - MOBILE AGGRESSIVE
    final bool isMobile = screenWidth <= 1024;   // Mobile: hide rail, show bottom nav (more aggressive)
    final bool isTablet = screenWidth > 1024 && screenWidth <= 1200; // Tablet: show rail
    final bool isDesktop = screenWidth > 1200;    // Desktop: show rail, no bottom nav
    
    final bool showNavigationRail = !isMobile; // Show rail on tablet + desktop ONLY
    final bool showBottomNav = isMobile;       // Show bottom nav only on mobile
    
    // Debug output (remove in production)
    debugPrint('Screen width: $screenWidth, isMobile: $isMobile, showNavigationRail: $showNavigationRail');
    
    final theme = Theme.of(context);

    return Scaffold(
      // Show AppBar only on mobile
      appBar: isMobile ? AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        title: const Text(
          "Ruviel",
          style: TextStyle(
            color: PurpleTheme.primaryPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.iconTheme.color),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
        ],
      ) : null,
      
      body: Row(
        children: [
          // NavigationRail only for desktop/tablet (>1024px)
          if (showNavigationRail)
            NavigationRail(
              selectedIndex: _getNavigationIndex(_selectedIndex),
              onDestinationSelected: (index) {
                // Special handling for Create button (index 2)
                if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SelectPostTypeScreen()),
                  );
                  return;
                }

                // Tweet button (index 7) opens Twitter/X mode screen
                if (index == 7) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TwitterShellScreen()),
                  );
                  return;
                }

                // Adjust index: after Create (index 2), subtract 1
                setState(() {
                  _selectedIndex = index > 2 ? index - 1 : index;
                });
              },
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(
                color: PurpleTheme.primaryPurple,
                size: 28,
              ),
              unselectedIconTheme: IconThemeData(
                color: theme.disabledColor,
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search_rounded), label: Text('Search')),
                NavigationRailDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: Text('Create')),
                NavigationRailDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: Text('Reels')),
                NavigationRailDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: Text('Activity')),
                NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
                NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat), label: Text('Chat')),
                NavigationRailDestination(icon: Icon(Icons.edit), selectedIcon: Icon(Icons.edit_note), label: Text('Ruviel')),
              ],
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: "Logout",
                  onPressed: () => _logout(context),
                ),
              ),
            ),

          Expanded(
            child: _selectedIndex < _screens.length
                ? _screens[_selectedIndex]
                : _screens[0],
          ),
        ],
      ),

      // Bottom nav for mobile only
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _getNavigationIndex(_selectedIndex),
              selectedItemColor: PurpleTheme.primaryPurple,
              unselectedItemColor: theme.disabledColor,
              onTap: (index) {
                // Special handling for Create button (index 2)
                if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SelectPostTypeScreen()),
                  );
                  return;
                }

                // Tweet button (index 7) opens Twitter/X mode screen
                if (index == 7) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TwitterShellScreen()),
                  );
                  return;
                }

                // Adjust index: after Create (index 2), subtract 1
                setState(() {
                  _selectedIndex = index > 2 ? index - 1 : index;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_box_outlined),
                  activeIcon: Icon(Icons.add_box),
                  label: "Create",
                ),
                BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Reels"),
                BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Activity"),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
                BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
                BottomNavigationBarItem(icon: Icon(Icons.edit), label: "Ruviel"),
              ],
            )
          : null,
    );
  }
}
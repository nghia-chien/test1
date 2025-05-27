import 'package:flutter/material.dart';
import 'home_page.dart';
import 'feed_page.dart';
import 'closet_page.dart';
import 'ai_mix_page.dart';
import 'profile_page.dart';
import 'chat_screen.dart';
import '../utils/responsive_helper.dart';

class MainScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HomePage(),
    const FeedPage(),
    const ClosetPage(),
    const AiMixPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final bool isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tủ Đồ Thông Minh'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.notifications),
            ),
            onPressed: () {
              // TODO: Implement notifications functionality
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => widget.onThemeChanged(!widget.isDarkMode),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop || isTablet)
            NavigationRail(
              extended: isDesktop,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Trang Chủ'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.feed),
                  label: Text('Bảng Tin'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.checkroom),
                  label: Text('Tủ Đồ'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_awesome),
                  label: Text('Mix Đồ AI'),
                ),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
            ),
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.getMaxWidth(context),
                ),
                padding: ResponsiveHelper.getScreenPadding(context),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
          if (isDesktop)
            SizedBox(
              width: 300,
              child: Drawer(
                elevation: 0,
                child: Column(
                  children: [
                    UserAccountsDrawerHeader(
                      currentAccountPicture: const CircleAvatar(
                        backgroundImage: NetworkImage('https://picsum.photos/200'),
                      ),
                      accountName: const Text('Nguyễn Văn A'),
                      accountEmail: const Text('nguyenvana@example.com'),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Hồ Sơ'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.chat_bubble),
                      title: const Text('Trợ Lý AI'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(isDarkMode: widget.isDarkMode),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.favorite),
                      title: const Text('Yêu Thích'),
                      onTap: () {
                        // TODO: Navigate to favorites page
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Lịch Sử'),
                      onTap: () {
                        // TODO: Navigate to history page
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Cài Đặt'),
                      onTap: () {
                        // TODO: Navigate to settings page
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                      title: Text(widget.isDarkMode ? 'Chế Độ Sáng' : 'Chế Độ Tối'),
                      onTap: () {
                        widget.onThemeChanged(!widget.isDarkMode);
                      },
                    ),
                    const Spacer(),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Đăng Xuất'),
                      onTap: () {
                        // TODO: Implement logout
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      drawer: (!isDesktop && !isTablet) ? Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                backgroundImage: NetworkImage('https://picsum.photos/200'),
              ),
              accountName: const Text('Nguyễn Văn A'),
              accountEmail: const Text('nguyenvana@example.com'),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Hồ Sơ'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble),
              title: const Text('Trợ Lý AI'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(isDarkMode: widget.isDarkMode),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Yêu Thích'),
              onTap: () {
                // TODO: Navigate to favorites page
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Lịch Sử'),
              onTap: () {
                // TODO: Navigate to history page
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài Đặt'),
              onTap: () {
                // TODO: Navigate to settings page
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              title: Text(widget.isDarkMode ? 'Chế Độ Sáng' : 'Chế Độ Tối'),
              onTap: () {
                widget.onThemeChanged(!widget.isDarkMode);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng Xuất'),
              onTap: () {
                // TODO: Implement logout
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ) : null,
      bottomNavigationBar: (!isDesktop && !isTablet) ? BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang Chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Bảng Tin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom),
            label: 'Tủ Đồ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Mix Đồ AI',
          ),
        ],
      ) : null,
    );
  }
} 
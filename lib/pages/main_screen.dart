import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import 'home_page.dart';
import 'feed_page.dart';
import 'closet_page.dart';
import 'ai_mix_page.dart';
import 'notification.dart';
import 'profile_page2.dart';
import 'profile_page1.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Placeholder cho SettingsPage nếu chưa có
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Cài đặt', style: TextStyle(fontSize: 24)));
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;
  String? _userName;
  String? email;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userName = doc.data()?['name'] ?? 'Guest';
        email = doc.data()?['email'] ?? user.email!;
        _imageUrl = doc.data()?['imageUrl'];
      });
    } else {
      setState(() {
        _userName = 'Guest';
      });
    }
  }

  final List<SidebarItem> _sidebarItems = [
    SidebarItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Trang chủ',
    ),
    SidebarItem(
      icon: Icons.public_outlined,
      selectedIcon: Icons.public,
      label: 'Mạng xã hội',
    ),
    SidebarItem(
      icon: Icons.checkroom_outlined,
      selectedIcon: Icons.checkroom,
      label: 'Tủ đồ',
    ),
    SidebarItem(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      label: 'AI phối đồ',
    ),
  ];

  final List<Widget> _pages = const [
    HomePage(key: PageStorageKey('home')),
    FeedPage(key: PageStorageKey('feed')),
    ClosetPage(key: PageStorageKey('closet')),
    AiMixPage(key: PageStorageKey('aimix')),
    NotificationPanel(key: PageStorageKey('notify')),
    SettingsPage(key: PageStorageKey('settings')),
    ProfilePage(key: PageStorageKey('profile')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const NotificationPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: isWideScreen ? null : AppBar(
        backgroundColor: const Color(0xFFECF0F1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage1()));
            },
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: isWideScreen
        ? Row(
            children: [
              _buildSidebar(theme),
              Expanded(
                child: Container(
                  color: const Color(0xFFA3C7E6), // ✅ sửa từ BoxDecoration sang color đơn giản
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ),
            ],
          )
          : Column(
        children: [
          Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 125, 125, 123),
                    ),
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color.fromARGB(255, 167, 248, 63),
              unselectedItemColor: const Color.fromARGB(255, 233, 233, 233),
              backgroundColor: const Color.fromARGB(255, 0, 70, 147),
              elevation: 8,
              items: _sidebarItems.take(5).map((item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    activeIcon: Icon(item.selectedIcon),
                    label: item.label,
                  )).toList(),
            ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [

          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainNavigation(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final double logoSize = _isCollapsed ? 40 : 64;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16), // ✅ bo góc
            child: Container(
              color: const Color.fromARGB(189, 255, 0, 0), // ✅ màu nền
              width: logoSize,
              height: logoSize,
              child: Image.asset(
                'images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (!_isCollapsed) ...[
            const SizedBox(height: 12),
            const Text(
              'With honor. Be you',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Thời trang thông minh',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(
                _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                size: 20,
                color: Colors.grey[600],
              ),
              onPressed: _toggleSidebar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: _sidebarItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _selectedIndex == index;

          return _buildNavItem(
            icon: isSelected ? item.selectedIcon : item.icon,
            label: item.label,
            isSelected: isSelected,
            onTap: () => _onItemTapped(index),
            shortcut: item.shortcut,
            hasNotification: item.hasNotification,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? shortcut,
    bool hasNotification = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                    if (hasNotification)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[700],
                      ),
                    ),
                  ),
                  if (shortcut != null)
                    Text(
                      shortcut,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (!_isCollapsed) ...[
            _buildFooterItem(Icons.notifications_outlined, 'Thông báo', () {            
              _onItemTapped(4);
            }),
            const SizedBox(height: 8),
            _buildFooterItem(Icons.settings_outlined, 'Cài đặt', () {
            _onItemTapped(5); // Hoặc index của trang thông báo
          }),
            const SizedBox(height: 16),
          ],
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onItemTapped(6),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _isCollapsed
              ? Center( 
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF6366F1),
                    backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                    child: _imageUrl == null
                        ? const Text(
                            'SM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min, // ✅ tránh tràn
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF6366F1),
                      backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null
                          ? const Text(
                              'SM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Flexible( // ✅ không dùng Expanded
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_userName ?? 'Loading...'}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${email ?? 'Loading...'}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.expand_more,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? shortcut;
  final bool hasNotification;
  final Color? color;

  SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.shortcut,
    this.hasNotification = false,
    this.color,
  });
}

class ProjectItem {
  final String name;
  final Color color;
  final IconData icon;

  ProjectItem({
    required this.name,
    required this.color,
    required this.icon,
  });
}
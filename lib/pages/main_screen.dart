import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import '../constants/constants.dart';
import 'home_page.dart';
import 'feed_page.dart';
import 'closet_page.dart';
import 'ai_mix_page.dart';
import 'notification.dart';
import 'profile_page2.dart';
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

  static const Color primaryBlue = Color(0xFF209CFF);
  static const Color secondaryGrey = Color(0xFF7D7F85);
  static const Color darkgrey = Color(0xFF231f20);
  static const Color white = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color darkBlue = Color(0xFF006cff);
  static const Color black =Color(0xFF000000);

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

  final List<Widget> _pages = [
    const HomePage(key: PageStorageKey('home')),
    const FeedPage(key: PageStorageKey('feed')),
    const ClosetPage(key: PageStorageKey('closet')),
    const AiMixPage(key: PageStorageKey('aimix')),
    const NotificationPanel(key: PageStorageKey('notify')),
    const SettingsPage(key: PageStorageKey('settings')),
    ProfilePage(key: const PageStorageKey('profile')),
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

  // Widget buildCustomBottomBar() {
  //   final List<SidebarItem> items = _sidebarItems.take(4).toList();
  //
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     //rmargin: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Color(0xFF209CFF),
  //         borderRadius: const BorderRadius.only(
  //           topLeft: Radius.circular(30),
  //           topRight: Radius.circular(30),
  //         ),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: items.asMap().entries.map((entry) {
  //         final int index = entry.key;
  //         final item = entry.value;
  //         final bool isSelected = _selectedIndex == index;
  //
  //         return GestureDetector(
  //           onTap: () => _onItemTapped(index),
  //           child: AnimatedContainer(
  //             duration: Duration(milliseconds: 200),
  //             padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 0, vertical: 8),
  //             decoration: BoxDecoration(
  //               color: isSelected ? Colors.white : Colors.transparent,
  //               borderRadius: BorderRadius.circular(32),
  //             ),
  //             child: Row(
  //               children: [
  //                 Container(
  //                   padding: EdgeInsets.all(8),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     shape: BoxShape.circle,
  //                     border: isSelected
  //                         ? Border.all(color: Colors.white, width: 2)
  //                         : Border.all(color: Colors.transparent),
  //                   ),
  //                   child: Icon(
  //                     isSelected ? item.selectedIcon : item.icon,
  //                     color: isSelected ? Color(0xFF209CFF) : Colors.black,
  //                     size: 20,
  //                   ),
  //                 ),
  //                 if (isSelected) ...[
  //                   SizedBox(width: 8),
  //                   Text(
  //                     item.label,
  //                     style: TextStyle(
  //                       color: Color(0xFF209CFF),
  //                       fontWeight: FontWeight.bold,
  //                      
  //                     ),
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }


  @override
Widget build(BuildContext context) {
  final isWideScreen = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isTablet(context);

  return SafeArea( // ✅ Giữ cho toàn app
    child:Scaffold(
    backgroundColor: Constants.pureWhite,

    body: isWideScreen
        ? Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: Container(
                  color: primaryBlue,
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
                  color: Constants.pureWhite,
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ),
            ],
          ),

    bottomNavigationBar: isWideScreen ? null : //buildCustomBottomBar(),

        BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontSize: 10, // 👈 nhỏ lại
              fontWeight: FontWeight.w500,
            ),
            selectedItemColor: black,
            unselectedItemColor: Constants.secondaryGrey,
            selectedIconTheme: const IconThemeData(color: Constants.darkBlueGrey),
            unselectedIconTheme: const IconThemeData(color: Constants.secondaryGrey),
            backgroundColor: Constants.pureWhite,
            elevation: 8,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            items: _sidebarItems.take(5).map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.selectedIcon),
                  label: item.label,
                )).toList(),
          ),
  ),);
}


  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: Constants.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Constants.darkBlueGrey.withAlpha((255 * 0.05).round()),
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
              color: Constants.primaryBlue, // ✅ màu nền
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
                color: Constants.darkBlueGrey,
                fontFamily: 'BeautiqueDisplay',
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Thời trang thông minh',
              style: TextStyle(
                fontSize: 12,
                color: Constants.secondaryGrey,
                fontFamily: 'BeautiqueDisplay',
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(
                _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                size: 20,
                color: Constants.secondaryGrey,
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
              color: isSelected ? Constants.primaryBlue.withAlpha((255 * 0.1).round()) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? Constants.darkBlueGrey : Constants.secondaryGrey,
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
                        color: isSelected ? Constants.darkBlueGrey : Constants.secondaryGrey,
                        fontFamily: 'BeautiqueDisplay',
                      ),
                    ),
                  ),
                  if (shortcut != null)
                    Text(
                      shortcut,
                      style: TextStyle(
                        fontSize: 12,
                        color: Constants.secondaryGrey,
                        fontFamily: 'BeautiqueDisplay',
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
            color: Constants.secondaryGrey.withAlpha((255 * 0.2).round()),
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
                color: Constants.secondaryGrey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Constants.secondaryGrey,
                  fontFamily: 'BeautiqueDisplay',
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
                    backgroundColor: Constants.primaryBlue,
                    backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                    child: _imageUrl == null
                        ? const Text(
                            'SM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'BeautiqueDisplay',
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
                      backgroundColor: Constants.primaryBlue,
                      backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null
                          ? const Text(
                              'SM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'BeautiqueDisplay',
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
                              color: Constants.darkBlueGrey,
                              fontFamily: 'BeautiqueDisplay',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${email ?? 'Loading...'}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Constants.secondaryGrey,
                              fontFamily: 'BeautiqueDisplay',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.expand_more,
                      size: 16,
                      color: Constants.secondaryGrey,
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
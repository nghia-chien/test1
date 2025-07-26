import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/activity_history.dart';
import '../services/activity_history_service.dart';
import '../utils/responsive_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'calendar_page.dart';
import 'profile_page2.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});


  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  Map<String, int> _activityStats = {};
  static const Color primaryBlue = Color(0xFF209CFF);
  static const Color secondaryGrey = Color(0xFF7D7F85);
  static const Color darkgrey = Color(0xFF231f20);
  static const Color white = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color darkBlue = Color(0xFF006cff);
  static const Color black =Color(0xFF000000);
  final List<String> _filters = [
    'all',
    'upload',
    'delete',
    'like',
    'comment',
    'chat',
    'calendar',
    'profile'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActivityStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivityStats() async {
    final stats = await ActivityHistoryService.getActivityStats();
    setState(() {
      _activityStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.pureWhite,
      appBar: AppBar(
        backgroundColor: Constants.pureWhite,
        elevation: 0,
        title: const Text(
          'Lịch sử hoạt động',
          style: TextStyle(
            color: Constants.darkBlueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Constants.darkBlueGrey),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Constants.darkBlueGrey),
            onPressed: _showClearAllDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: Constants.secondaryGrey,
          indicatorColor: primaryBlue,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Thống kê'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityList(),
          _buildStatsView(),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: StreamBuilder<List<ActivityHistory>>(
            stream: _selectedFilter == 'all'
                ? ActivityHistoryService.getUserActivities()
                : ActivityHistoryService.getActivitiesByAction(_selectedFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryBlue));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Constants.secondaryGrey),
                      const SizedBox(height: 16),
                      Text(
                        'Có lỗi xảy ra: ${snapshot.error}',
                        style: const TextStyle(color: Constants.secondaryGrey),
                      ),
                    ],
                  ),
                );
              }

              final activities = snapshot.data ?? [];

              if (activities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 64, color: Constants.secondaryGrey),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có hoạt động nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Constants.secondaryGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Các hoạt động của bạn sẽ xuất hiện ở đây',
                        style: TextStyle(color: Constants.secondaryGrey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _buildActivityCard(activity);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          final count = _activityStats[filter] ?? 0;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getFilterLabel(filter), style: TextStyle(color: isSelected ? primaryBlue : Constants.secondaryGrey)),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue.withOpacity(0.1) : Constants.secondaryGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? primaryBlue : Constants.secondaryGrey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Constants.pureWhite,
              selectedColor: primaryBlue.withOpacity(0.15),
              checkmarkColor: primaryBlue,
            ),
          );
        },
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'Tất cả';
      case 'upload':
        return 'Thêm đồ';
      case 'delete':
        return 'Xóa bài';
      case 'like':
        return 'Thích';
      case 'comment':
        return 'Bình luận';
      case 'chat':
        return 'Chat';
      case 'calendar':
        return 'Lịch';
      case 'profile':
        return 'Hồ sơ';
      default:
        return filter;
    }
  }

  Widget _buildActivityCard(ActivityHistory activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Constants.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          if (activity.action == 'like' || activity.action == 'comment' || activity.action == 'upload') {
            final postId = activity.metadata?['postId'];
            if (postId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PostDetailPage(postId: postId)),
              );
            }
          } else if (activity.action == 'calendar') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarPage()),
            );
          } else if (activity.action == 'profile') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            activity.actionIcon,
            color: primaryBlue,
            size: 24,
          ),
        ),
        title: Text(
          activity.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Constants.darkBlueGrey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              activity.timeAgo,
              style: const TextStyle(
                color: Constants.secondaryGrey,
                fontSize: 12,
              ),
            ),
            if (activity.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: activity.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: Constants.secondaryGrey.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Constants.secondaryGrey.withOpacity(0.1),
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.disabled_by_default, color: Colors.red),
          onPressed: () {
            _showDeleteDialog(activity);
          },
        ),
      ),
    );
  }

  Widget _buildStatsView() {
    return FutureBuilder<Map<String, int>>(
      future: ActivityHistoryService.getActivityStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Constants.primaryBlue));
        }

        final stats = snapshot.data ?? {};
        final totalActivities = stats.values.fold(0, (sum, count) => sum + count);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCard(
                'Tổng hoạt động',
                totalActivities.toString(),
                Icons.analytics,
                primaryBlue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Thống kê theo loại',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...stats.entries.map((entry) => _buildStatItem(entry.key, entry.value)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Constants.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryBlue, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Constants.secondaryGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Constants.darkBlueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String action, int count) {
    final activity = ActivityHistory(
      id: '',
      userId: '',
      action: action,
      description: '',
      timestamp: DateTime.now(),
    );

    return GestureDetector(
      onTap: () {
        // Khi nhấn vào loại action trong thống kê, mở danh sách các bài liên quan
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RelatedPostsPage(action: action),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Constants.pureWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withAlpha((255 * 0.03).round()),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryBlue.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                activity.actionIcon,
                color: primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getFilterLabel(action),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.darkBlueGrey,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryBlue.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(ActivityHistory activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hoạt động'),
        content: Text('Bạn có chắc muốn xóa hoạt động "${activity.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              ActivityHistoryService.deleteActivity(activity.id);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả'),
        content: const Text('Bạn có chắc muốn xóa tất cả hoạt động? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              ActivityHistoryService.clearAllActivities();
              Navigator.pop(context);
            },
            child: const Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Dummy PostDetailPage (bạn nên thay bằng trang chi tiết bài viết thực tế nếu có)
class PostDetailPage extends StatelessWidget {
  final String postId;
  const PostDetailPage({required this.postId, super.key});
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bài viết')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF209CFF)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy bài viết.', style: TextStyle(color: Constants.secondaryGrey)));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['imageBase64'] != null && data['imageBase64'].toString().isNotEmpty)
                  Image.memory(
                    base64Decode(data['imageBase64'].toString().split(',').last),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 16),
                Text(data['content'] ?? '', style: const TextStyle(fontSize: 16, color: Constants.darkBlueGrey)),
                const SizedBox(height: 8),
                Text('Tác giả: ${data['username'] ?? ''}', style: const TextStyle(color: Constants.secondaryGrey)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Trang danh sách các bài liên quan đến action
class RelatedPostsPage extends StatelessWidget {
  final String action;
  const RelatedPostsPage({required this.action, super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('Bài liên quan: ${action.toUpperCase()}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activity_history')
            .where('userId', isEqualTo: user?.uid)
            .where('action', isEqualTo: action)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF209CFF)));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Không có bài nào.', style: TextStyle(color: Constants.secondaryGrey)));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final activity = ActivityHistory.fromFirestore(docs[index]);
              final postId = activity.metadata?['postId'];
              return ListTile(
                leading: Icon(activity.actionIcon, color: Color(0xFF209CFF)),
                title: Text(activity.description),
                subtitle: Text(activity.timeAgo),
                onTap: postId != null
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PostDetailPage(postId: postId)),
                        )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
} 
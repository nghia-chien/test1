import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../utils/responsive_helper.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  bool isDarkMode = false;

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final List<Map<String, dynamic>> notifications = [];

    final postSnapshots = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: currentUser.uid)
        .get();

    for (var post in postSnapshots.docs) {
      final postData = post.data();
      final postContent = postData['content'] ?? '';
      final likes = List<String>.from(postData['likes'] ?? []);

      for (final likerUid in likes) {
        if (likerUid != currentUser.uid) {
          final userDoc =
              await FirebaseFirestore.instance.collection('users').doc(likerUid).get();
          final name = userDoc.data()?['name'] ?? 'Người dùng';

          notifications.add({
            'type': 'like',
            'senderName': name,
            'postContent': postContent,
            'createdAt': postData['createdAt'],
          });
        }
      }

      final commentSnapshots = await post.reference
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      for (var comment in commentSnapshots.docs) {
        final commentData = comment.data();
        if (commentData['uid'] != currentUser.uid) {
          notifications.add({
            'type': 'comment',
            'senderName': commentData['name'] ?? 'Người dùng',
            'commentContent': commentData['content'] ?? '',
            'postContent': postContent,
            'createdAt': commentData['createdAt'],
          });
        }
      }
    }

    notifications.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context);
    final bgColor = isDarkMode ? Constants.darkBlueGrey : const Color(0xFFF0F1F5);
    final cardColor = isDarkMode ? Constants.darkBlueGrey : Constants.pureWhite;
    final textColor = isDarkMode ? Constants.pureWhite : Constants.darkBlueGrey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: isWideScreen
          ? null
          : AppBar(
              backgroundColor: cardColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text('Thông báo', style: TextStyle(color: textColor)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: textColor,
                  ),
                  onPressed: () {
                    setState(() {
                      isDarkMode = !isDarkMode;
                    });
                  },
                ),
              ],
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) => Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Constants.secondaryGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://storage.googleapis.com/a1aa/image/7324999a-736b-4f54-1d00-3416d79d600c.jpg',
                        height: 120,
                        width: 120,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Chưa có thông báo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thông báo sẽ hiển thị khi có người thích hoặc bình luận bài viết của bạn.',
                        style: TextStyle(color: Constants.secondaryGrey.withOpacity(0.6), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Xem lịch sử thông báo',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isLike = notif['type'] == 'like';
                    final sender = notif['senderName'];
                    final content = notif['postContent'];
                    final comment = notif['commentContent'];
                    final createdAt = (notif['createdAt'] as Timestamp?)?.toDate();
                    final formattedDate = createdAt != null
                        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                        : '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Constants.secondaryGrey.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Icon(
                              isLike ? Icons.favorite : Icons.comment,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLike
                                      ? '$sender đã thả tim bài viết'
                                      : '$sender đã bình luận:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (!isLike)
                                  Text(
                                    '"$comment"',
                                    style: TextStyle(fontSize: 13, color: textColor),
                                  ),
                                Text(
                                  '"$content"',
                                  style: TextStyle(fontSize: 13, color: Constants.secondaryGrey.withOpacity(0.6)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(fontSize: 11, color: Constants.secondaryGrey.withOpacity(0.4)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
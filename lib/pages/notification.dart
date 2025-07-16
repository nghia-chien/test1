import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  bool isDarkMode = false;

  Stream<QuerySnapshot> getNotificationStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('ownerId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    if (data['isRead'] == true) return;
    await doc.reference.update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context);
    final bgColor = isDarkMode ? Colors.black : const Color(0xFFF0F1F5);
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

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
            child: StreamBuilder<QuerySnapshot>(
              stream: getNotificationStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) => Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
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

                final notifications = snapshot.data!.docs;

                return ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isLike = data['type'] == 'like';
                    final sender = data['senderName'] ?? 'Người dùng';
                    final content = data['postContent'] ?? '';
                    final comment = data['commentContent'] ?? '';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final isRead = data['isRead'] == true;

                    final formattedDate = createdAt != null
                        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                        : '';

                    return GestureDetector(
                      onTap: () => markAsRead(doc),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
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
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
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
                                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
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

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _notifications = FirebaseFirestore.instance.collection('notifications');

  /// Gửi thông báo khi người dùng khác like bài viết của bạn
  static Future<void> sendLikeNotification({
    required String ownerId,
    required String senderId,
    required String senderName,
    required String postId,
    required String postContent,
  }) async {
    if (ownerId == senderId) return; // Không tự gửi cho chính mình

    await _notifications.add({
      'type': 'like',
      'ownerId': ownerId,
      'senderId': senderId,
      'senderName': senderName,
      'postId': postId,
      'postContent': postContent,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  /// Gửi thông báo khi người dùng khác comment vào bài viết của bạn
  static Future<void> sendCommentNotification({
    required String ownerId,
    required String senderId,
    required String senderName,
    required String postId,
    required String postContent,
    required String commentContent,
  }) async {
    if (ownerId == senderId) return;

    await _notifications.add({
      'type': 'comment',
      'ownerId': ownerId,
      'senderId': senderId,
      'senderName': senderName,
      'postId': postId,
      'postContent': postContent,
      'commentContent': commentContent,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_history.dart';

class ActivityHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Thêm activity mới
  static Future<void> addActivity({
    required String action,
    required String description,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final activity = ActivityHistory(
        id: '',
        userId: user.uid,
        action: action,
        description: description,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _firestore
          .collection('activity_history')
          .add(activity.toFirestore());
    } catch (e) {
      print('Lỗi khi thêm activity: $e');
    }
  }

  // Lấy danh sách activity của user
  static Stream<List<ActivityHistory>> getUserActivities() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('activity_history')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityHistory.fromFirestore(doc))
          .toList();
    });
  }

  // Lấy activity theo action
  static Stream<List<ActivityHistory>> getActivitiesByAction(String action) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('activity_history')
        .where('userId', isEqualTo: user.uid)
        .where('action', isEqualTo: action)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityHistory.fromFirestore(doc))
          .toList();
    });
  }

  // Xóa activity
  static Future<void> deleteActivity(String activityId) async {
    try {
      await _firestore
          .collection('activity_history')
          .doc(activityId)
          .delete();
    } catch (e) {
      print('Lỗi khi xóa activity: $e');
    }
  }

  // Xóa tất cả activity của user
  static Future<void> clearAllActivities() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final activities = await _firestore
          .collection('activity_history')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in activities.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Lỗi khi xóa tất cả activity: $e');
    }
  }

  // Lấy thống kê activity
  static Future<Map<String, int>> getActivityStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final activities = await _firestore
          .collection('activity_history')
          .where('userId', isEqualTo: user.uid)
          .get();

      final stats = <String, int>{};
      for (final doc in activities.docs) {
        final activity = ActivityHistory.fromFirestore(doc);
        stats[activity.action] = (stats[activity.action] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Lỗi khi lấy thống kê activity: $e');
      return {};
    }
  }
} 
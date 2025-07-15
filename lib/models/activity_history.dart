import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActivityHistory {
  final String id;
  final String userId;
  final String action;
  final String description;
  final String? imageUrl;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityHistory({
    required this.id,
    required this.userId,
    required this.action,
    required this.description,
    this.imageUrl,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityHistory(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'action': action,
      'description': description,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  IconData get actionIcon {
    switch (action) {
      case 'upload':
        return Icons.upload_file;
      case 'delete':
        return Icons.delete;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      case 'chat':
        return Icons.chat;
      case 'calendar':
        return Icons.calendar_today;
      case 'profile':
        return Icons.person;
      default:
        return Icons.history;
    }
  }

  Color get actionColor {
    switch (action) {
      case 'upload':
        return Colors.green;
      case 'delete':
        return Colors.red;
      case 'like':
        return Colors.pink;
      case 'comment':
        return Colors.blue;
      case 'share':
        return Colors.orange;
      case 'chat':
        return Colors.purple;
      case 'calendar':
        return Colors.indigo;
      case 'profile':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
} 
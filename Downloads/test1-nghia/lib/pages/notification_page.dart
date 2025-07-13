import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Bạn cần đăng nhập'));

    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(user.uid)
            .collection('items')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Không có thông báo mới'));
          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'];
              final fromName = data['fromName'] ?? 'Ai đó';
              String message = '';
              if (type == 'like') {
                message = '$fromName đã thả tim bài viết của bạn';
              } else if (type == 'comment') {
                message = '$fromName đã bình luận vào bài viết của bạn';
              }
              return ListTile(
                title: Text(message),
                subtitle: data['createdAt'] != null
                    ? Text('${(data['createdAt'] as Timestamp).toDate()}')
                    : null,
              );
            }).toList(),
          );
        },
      ),
    );
  }
} 
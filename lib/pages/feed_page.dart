
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';


class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  bool _isPosting = false;
  String? _base64Image;
  String _searchQuery = '';

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;

    if (input.files != null && input.files!.isNotEmpty) {
      final file = input.files!.first;
      if (file.size > 700 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh quá lớn, vui lòng chọn ảnh < 700KB')),
        );
        return;
      }
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      await reader.onLoad.first;
      setState(() {
        _base64Image = reader.result as String;
      });
    }
  }

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    final content = _postController.text.trim();
    if (user == null || (content.isEmpty && _base64Image == null)) return;
    setState(() => _isPosting = true);

    await FirebaseFirestore.instance.collection('posts').add({
      'uid': user.uid,
      'username': user.email ?? 'Người dùng',
      'content': content,
      'imageBase64': _base64Image,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
    });

    setState(() {
      _postController.clear();
      _base64Image = null;
      _isPosting = false;
    });
  }

  Future<void> _showCommentsDialog(DocumentSnapshot postDoc) async {
    final user = FirebaseAuth.instance.currentUser;
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 400,
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text('Bình luận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: postDoc.reference.collection('comments').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final comments = snapshot.data!.docs;
                      if (comments.isEmpty) return const Center(child: Text('Chưa có bình luận.'));
                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, i) {
                          final c = comments[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text((c['username'] ?? 'U')[0])),
                            title: Text(c['username'] ?? 'User'),
                            subtitle: Text(c['content'] ?? ''),
                            trailing: c['createdAt'] != null ? Text(
                              (c['createdAt'] as Timestamp).toDate().toString().substring(0, 16),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ) : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(hintText: 'Nhập bình luận...'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            final content = commentController.text.trim();
                            if (content.isEmpty) return;
                            await postDoc.reference.collection('comments').add({
                              'uid': user.uid,
                              'username': user.email ?? 'User',
                              'content': content,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            commentController.clear();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostItem(DocumentSnapshot doc) {
    final user = FirebaseAuth.instance.currentUser;
    final data = doc.data() as Map<String, dynamic>;
    final username = data['username'] ?? 'User';
    final content = data['content'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final base64 = data['imageBase64'] as String?;
    final likes = (data['likes'] as List?)?.cast<String>() ?? [];
    final isLiked = user != null && likes.contains(user.uid);
    Uint8List? imageBytes;

    if (base64 != null && base64.isNotEmpty) {
      try {
        imageBytes = base64Decode(base64.split(',').last);
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(username[0])),
                const SizedBox(width: 8),
                Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (createdAt != null)
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  )
              ],
            ),
            const SizedBox(height: 8),
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imageBytes,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheHeight: 300,
                ),
              ),
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(content),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null),
                  onPressed: user == null ? null : () async {
                    final postRef = doc.reference;
                    if (isLiked) {
                      await postRef.update({ 'likes': FieldValue.arrayRemove([user.uid]) });
                    } else {
                      await postRef.update({ 'likes': FieldValue.arrayUnion([user.uid]) });
                    }
                  },
                ),
                Text('${likes.length}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () => _showCommentsDialog(doc),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: doc.reference.collection('comments').snapshots(),
                  builder: (context, commentSnap) {
                    final commentCount = commentSnap.hasData ? commentSnap.data!.docs.length : 0;
                    return Text('$commentCount');
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Feed cộng đồng')), 
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài viết... (theo nội dung hoặc tên)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _postController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Bạn muốn chia sẻ điều gì?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Chọn ảnh'),
                      ),
                      if (_base64Image != null) ...[
                        const SizedBox(width: 12),
                        Text('Đã chọn ảnh', style: TextStyle(color: Colors.green[700]))
                      ],
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isPosting ? null : _submitPost,
                        child: _isPosting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Đăng bài'),
                      )
                    ],
                  ),
                ],
              ),
            ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = _searchQuery.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final content = (data['content'] ?? '').toString().toLowerCase();
                        final username = (data['username'] ?? '').toString().toLowerCase();
                        return content.contains(_searchQuery.toLowerCase()) ||
                               username.contains(_searchQuery.toLowerCase());
                      }).toList();
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildPostItem(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

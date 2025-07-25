import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/activity_history_service.dart';
import '../constants/constants.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  bool _isPosting = false;
  String? _base64Image;
  String _searchQuery = '';
  String? _imageUrl;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _fabAnimationController.forward();
  }

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;

    if (input.files != null && input.files!.isNotEmpty) {
      final file = input.files!.first;
      if (file.size > 700 * 1024) {
        _showSnackBar('Ảnh quá lớn, vui lòng chọn ảnh < 700KB', isError: true);
        return;
      }
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      await reader.onLoad.first;
      setState(() => _base64Image = reader.result as String);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    final content = _postController.text.trim();
    if (user == null || (content.isEmpty && _base64Image == null)) return;

    setState(() => _isPosting = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final name = userDoc.data()?['name'] ?? user.email ?? 'Người dùng';

      final postRef = await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid,
        'username': name,
        'content': content,
        'imageBase64': _base64Image,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
      });

      await ActivityHistoryService.addActivity(
        action: 'upload',
        description: content.isNotEmpty 
          ? 'Đăng bài: ${content.substring(0, content.length > 50 ? 50 : content.length)}...' 
          : 'Đăng ảnh mới',
        imageUrl: _base64Image,
        metadata: {
          'postId': postRef.id,
          'content': content,
          'hasImage': _base64Image != null,
        },
      );

      _showSnackBar('Đăng bài thành công!');
      setState(() {
        _postController.clear();
        _base64Image = null;
        _isPosting = false;
      });
    } catch (e) {
      _showSnackBar('Có lỗi xảy ra, vui lòng thử lại', isError: true);
      setState(() => _isPosting = false);
    }
  }

  Future<void> _submitComment(TextEditingController controller, DocumentSnapshot postDoc, User user) async {
    final content = controller.text.trim();
    if (content.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final name = userDoc.data()?['name'] ?? user.email ?? 'User';
    final postData = postDoc.data() as Map<String, dynamic>;
    final postUsername = postData['username'] ?? 'Người dùng';

    await postDoc.reference.collection('comments').add({
      'uid': user.uid,
      'name': name,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await ActivityHistoryService.addActivity(
      action: 'comment',
      description: 'Bình luận bài viết của $postUsername: ${content.substring(0, content.length > 30 ? 30 : content.length)}...',
      metadata: {
        'postId': postDoc.id,
        'comment': content,
        'postUsername': postUsername,
      },
    );

    controller.clear();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.day}/${time.month}/${time.year}';
  }

  Widget _buildImageTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final base64 = data['imageBase64'] as String?;
    final content = data['content'] ?? '';
    final username = data['username'] ?? 'User';

    return Hero(
      tag: doc.id,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showPostDetailsModal(doc),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: base64 == null 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey[50]!, Colors.grey[100]!],
                  )
                : null,
            ),
            child: base64 == null || base64.isEmpty
              ? _buildTextOnlyTile(content, username)
              : _buildImageTile2(base64, content, username),
          ),
        ),
      ),
    );
  }

  Widget _buildTextOnlyTile(String content, String username) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.blue[100],
                child: Text(
                  username[0].toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  username,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              content.length > 100 ? '${content.substring(0, 100)}...' : content,
              style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile2(String base64, String content, String username) {
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(base64.split(',').last);
    } catch (_) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.memory(imageBytes!, fit: BoxFit.cover, width: double.infinity),
          if (content.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha((255 * 0.7).round()),],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  content.length > 50 ? '${content.substring(0, 50)}...' : content,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPostDetailsModal(DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildPostCard(doc),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Replace your _buildPostCard method with this updated version
  Widget _buildPostCard(DocumentSnapshot doc) {
    final user = FirebaseAuth.instance.currentUser;
    final data = doc.data() as Map<String, dynamic>;
    final username = data['username'] ?? 'User';
    final content = data['content'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final base64 = data['imageBase64'] as String?;
    final commentController = TextEditingController();
    final imageUrl = data['imageUrl'];

    Uint8List? imageBytes;
    if (base64 != null && base64.isNotEmpty) {
      try {
        imageBytes = base64Decode(base64.split(',').last);
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        if (imageBytes != null)
          Hero(
            tag: '${doc.id}_image',
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.memory(imageBytes, fit: BoxFit.cover, width: double.infinity),
            ),
          ),

        // User Info & Actions - WRAP THIS IN STREAMBUILDER
        StreamBuilder<DocumentSnapshot>(
          stream: doc.reference.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
            }
            
            final postData = snapshot.data!.data() as Map<String, dynamic>;
            final likes = (postData['likes'] as List?)?.cast<String>() ?? [];
            final isLiked = user != null && likes.contains(user.uid);
            
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      username[0].toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (createdAt != null)
                          Text(_formatTime(createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: isLiked ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey[600],
                      ),
                      onPressed: () => _toggleLike(snapshot.data!, user, isLiked, username),
                    ),
                  ),
                  Text('${likes.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          },
        ),

        // Content
        if (content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              content,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
          ),

        const SizedBox(height: 16),

        // Comments Section
        _buildCommentsSection(doc, user,username ,imageUrl, commentController),
      ],
    );
  }

  // Also update your _toggleLike method to ensure proper state management
  Future<void> _toggleLike(DocumentSnapshot doc, User? user, bool isLiked, String username) async {
    if (user == null) return;

    try {
      final postRef = doc.reference;
      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([user.uid])
        });
        await ActivityHistoryService.addActivity(
          action: 'like',
          description: 'Bỏ thích bài viết của $username',
          metadata: {'postId': doc.id, 'action': 'unlike', 'username': username},
        );
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([user.uid])
        });
        await ActivityHistoryService.addActivity(
          action: 'like',
          description: 'Thích bài viết của $username',
          metadata: {'postId': doc.id, 'action': 'like', 'username': username},
        );
      }
    } catch (e) {
      // Handle error - show snackbar
      _showSnackBar('Có lỗi khi cập nhật thích bài viết', isError: true);
    }
  }

  Widget _buildCommentsSection(DocumentSnapshot doc, User? user , username, imageUrl, TextEditingController commentController) {
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Comment Input
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                    child: imageUrl == null
                      ? Text((username ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                      : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Thêm bình luận...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _submitComment(commentController, doc, user),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _submitComment(commentController, doc, user),
                    ),
                  ),
                ],
              ),
            ),

          // Comments List
          StreamBuilder<QuerySnapshot>(
            stream: doc.reference.collection('comments').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              
              final comments = snapshot.data!.docs;
              if (comments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: const Column(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Chưa có bình luận nào', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, i) => _buildCommentItem(comments[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(DocumentSnapshot comment) {
    final commentUsername = (comment['name'] ?? comment['username'] ?? 'User').toString();
    final commentContent = comment['content'] ?? '';
    final commentCreatedAt = (comment['createdAt'] as Timestamp?)?.toDate();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue[100],
          child: Text(
            commentUsername[0].toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue[800]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(commentUsername, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (commentCreatedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(_formatTime(commentCreatedAt), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(commentContent, style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaggeredGrid(List<DocumentSnapshot> posts) {
    return MasonryGridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      padding: const EdgeInsets.all(16),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      controller: _scrollController,
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildImageTile(posts[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        
                        hintText: 'Tìm kiếm...',
                        hintStyle: TextStyle(fontSize: 14,),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              }),
                            )
                          : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(width: 12),
                  ScaleTransition(
                    scale: _fabAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [ Color(0xFF209cff),Color(0xFF209cff)]),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: InkWell(
                        customBorder: CircleBorder(side:BorderSide(color: Colors.black)),
                        onTap: _showCreatePostDialog,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Đăng bài',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

              ],
            ),
          ),

          // Posts Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];
                final filtered = _searchQuery.isEmpty ? docs : docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final content = (data['content'] ?? '').toString().toLowerCase();
                  final username = (data['username'] ?? '').toString().toLowerCase();
                  return content.contains(_searchQuery.toLowerCase()) || username.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Chưa có bài viết nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return _buildStaggeredGrid(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height ,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('Tạo bài viết', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: _isPosting ? null : () async {
                        setModalState(() => _isPosting = true);
                        await _submitPost();
                        if (mounted) Navigator.pop(context);
                        setModalState(() => _isPosting = false);
                      },
                      child: _isPosting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Đăng', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _postController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Bạn đang nghĩ gì?',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      if (_base64Image != null)
                        Stack(
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(base64Decode(_base64Image!.split(',').last), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                  onPressed: () => setModalState(() => _base64Image = null),
                                ),
                              ),
                            ),
                          ],
                        ),
                      
                      const Spacer(),
                      
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.photo_camera_outlined, color: Colors.blue[700]),
                              onPressed: () async {
                                await _pickImage();
                                setModalState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _postController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
}
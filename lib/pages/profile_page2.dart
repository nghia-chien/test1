import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import '../utils/responsive_helper.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  String? _imageUrl;
  String? _backgroundUrl;
  bool _isEditing = false;

  int selectedTabIndex = 0;
  final List<String> tabs = ["bài viết", "trang phục"];
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _imageUrl = data['imageUrl'];
        _backgroundUrl = data['backgroundUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files?.isEmpty ?? true) return;

    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    setState(() {
      _imageUrl = reader.result as String;
    });
  }

  Future<void> _pickBackgroundImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files?.isEmpty ?? true) return;

    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    setState(() {
      _backgroundUrl = reader.result as String;
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('users').doc(user!.uid).update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'imageUrl': _imageUrl,
        'backgroundUrl': _backgroundUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
      );
      _toggleEdit();
    }
  }

  Widget _buildPostCard(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Text('Dữ liệu không hợp lệ'),
        );
      }
      
      final content = data['content']?.toString() ?? '';
      final base64 = data['imageBase64']?.toString();
      final likes = (data['likes'] as List?)?.cast<String>() ?? [];
      final isLiked = user != null && likes.contains(user!.uid);

      Uint8List? imageBytes;
      if (base64 != null && base64.isNotEmpty) {
        try {
          final base64Data = base64.contains(',') ? base64.split(',').last : base64;
          imageBytes = base64Decode(base64Data);
        } catch (e) {
          print('Error decoding base64: $e');
        }
      }

      return Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageBytes != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: Image.memory(
                      imageBytes, 
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              if (content.isNotEmpty)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      content, 
                      style: const TextStyle(fontSize: 14, height: 1.4),
                      maxLines: imageBytes != null ? 3 : 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () async {
                        if (user == null) return;
                        final postRef = doc.reference;
                        if (isLiked) {
                          await postRef.update({'likes': FieldValue.arrayRemove([user!.uid])});
                        } else {
                          await postRef.update({'likes': FieldValue.arrayUnion([user!.uid])});
                        }
                      },
                    ),
                    Text('${likes.length}'),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () => _showCommentsDialog(doc),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: doc.reference.collection('comments').snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return Text('$count');
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border),
                      onPressed: () {},
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building post card: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text('Lỗi hiển thị bài viết'),
      );
    }
  }

  Future<void> _showCommentsDialog(DocumentSnapshot postDoc) async {
    final user = FirebaseAuth.instance.currentUser;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Bình luận',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: postDoc.reference
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data!.docs;
                    if (comments.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Chưa có bình luận nào',
                                style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        final username = c['name'] ?? c['username'] ?? 'User';
                        final content = c['content'] ?? '';
                        final createdAt = (c['createdAt'] as Timestamp?)?.toDate();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey[300],
                                child: Text(
                                  username[0].toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (createdAt != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatTime(createdAt),
                                            style: TextStyle(
                                                color: Colors.grey[600], fontSize: 12),
                                          ),
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(content, style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (user != null)
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        child: Text(
                          (user.email ?? 'U')[0].toUpperCase(),
                          style:
                              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Thêm bình luận...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onSubmitted: (_) => _submitComment(
                            commentController,
                            postDoc,
                            user,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: () => _submitComment(
                            commentController,
                            postDoc,
                            user,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitComment(TextEditingController controller, DocumentSnapshot postDoc, User user) async {
    final content = controller.text.trim();
    if (content.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final name = userDoc.data()?['name'] ?? user.email ?? 'User';

    await postDoc.reference.collection('comments').add({
      'uid': user.uid,
      'name': name,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
    @override

    //edit profile
    Widget build(BuildContext context) {
      final primaryColor = const Color(0xFF3A8EDC);
      final isWideScreen = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isTablet(context);


      return Scaffold(
        backgroundColor: const Color(0xFFF2F6FA),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  height: 250,
                  decoration: _backgroundUrl != null
                      ? BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(_backgroundUrl!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.pink.shade300,
                              Colors.orange.shade300,
                              Colors.pink.shade200,
                            ],
                          ),
                        ),
                  child: Stack(
                    children: [ if (!isWideScreen)
                      Positioned(
                        top: 40,
                        left: 20,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          icon: const Icon(Icons.more_horiz, color: Colors.white),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (_) => _SettingsSheet(
                                isEditing: _isEditing,
                                onEdit: _toggleEdit,
                                onSave: _saveChanges,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 47,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                                  child: _imageUrl == null
                                      ? Text(
                                          _nameController.text.isNotEmpty
                                              ? _nameController.text[0].toUpperCase()
                                              : "U",
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                              ),
                              if (_isEditing)
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                    onPressed: _pickImage,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: IconButton(
                            icon: const Icon(Icons.image, color: Colors.white),
                            onPressed: _pickBackgroundImage,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _isEditing
                          ? _buildTextField(
                              controller: _nameController,
                              label: 'Tên',
                              icon: Icons.person,
                              enabled: _isEditing,
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Hãy nhập tên' : null,
                            )
                          : Text(
                              _nameController.text.isNotEmpty ? _nameController.text : 'Tên người dùng',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),                  

                            const SizedBox(height: 8),
                      _isEditing
                          ? Column(
                              children: [
                                const SizedBox(height: 16),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _bioController,
                                  label: 'Bio',
                                  icon: Icons.info_outline,
                                  maxLines: 3,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Text(
                                  _bioController.text.isNotEmpty
                                      ? _bioController.text
                                      : 'Long Lanh / Photographer / Model',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildTabBar(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                _buildContentSection(),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildTabBar() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(tabs.length, (index) {
          final label = tabs[index];
          final isActive = selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedTabIndex = index),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? Color(0xFF5B67CA) : Colors.black54,
                  ),
                ),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 2,
                    width: 24,
                    color: Color(0xFF5B67CA),
                  )
              ],
            ),
          );
        }),
      );
    }

    Widget _buildContentSection() {
      return selectedTabIndex == 0 ? _buildPostGrid('posts') : _buildPostGrid('outfits');
    }

  Widget _buildPostGrid(String collectionName) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(collectionName)
          .where('uid', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải dữ liệu: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        
        // Sort documents by timestamp if available
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['timestamp'] ?? aData['createdAt'] ?? DateTime.now();
          final bTime = bData['timestamp'] ?? bData['createdAt'] ?? DateTime.now();
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? MasonryGridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        return _buildPostCard(docs[index]);
                      },
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPostCard(docs[index]),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onSave;

  const _SettingsSheet({required this.isEditing, required this.onEdit, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _settingTile(Icons.edit, isEditing ? "Save Changes" : "Edit Profile", () {
            Navigator.pop(context);
            isEditing ? onSave() : onEdit();
          }),
          _settingTile(Icons.logout, "Logout", () {
            Navigator.pop(context);
            FirebaseAuth.instance.signOut();
          }),
        ],
      ),
    );
  }

  Widget _settingTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(label),
      onTap: onTap,
    );
  }
}

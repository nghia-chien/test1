import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import '../services/activity_history_service.dart';
import 'clothing_detail_page.dart';
import '../models/clothing_item.dart';
import 'login_page.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  String? _imageUrl;
  String? _backgroundUrl;
  bool _isEditing = false;

  int selectedTabIndex = 0;
  final List<String> tabs = ["Bài viết", "Trang phục"];
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

      // Thêm activity history cho cập nhật profile
      await ActivityHistoryService.addActivity(
        action: 'profile',
        description: 'Cập nhật thông tin hồ sơ',
        metadata: {
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
        },
      );

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
                    // Nút xóa chỉ cho chủ bài đăng
                    if (user != null && data['uid'] == user!.uid)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Xóa bài đăng',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xóa bài đăng'),
                              content: const Text('Bạn có chắc muốn xóa bài này?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await doc.reference.delete();
                            await ActivityHistoryService.addActivity(
                              action: 'delete',
                              description: 'Đã xóa bài đăng:  ${content.substring(0, content.length > 30 ? 30 : content.length)}',
                              metadata: {'postId': doc.id},
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xóa bài đăng')),
                            );
                          }
                        },
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

  void _showCommentsDialog(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comments'),
        content: Text('Comments dialog implementation'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3A8EDC);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                height: 200,
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
                            Color(0xFFD4A373),
                            Color(0xFFfEFAE0),
                            Color(0xFFCCD5AE),
                          ],
                        ),
                      ),
                child: Stack(
                  children: [
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
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
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
                          ): Text(
                              _nameController.text.isNotEmpty ? _nameController.text : 'Tên người dùng',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                    const SizedBox(height: 8),
                    _isEditing
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _bioController,
                                label: 'Tiểu sử',
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
                                    : '',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              if (!_isEditing)
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildTabBar(),

                  ],
                ),
              ),
              if (!_isEditing)_buildContentSection(),
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
    return selectedTabIndex == 0 ? _buildPostGrid('posts') : _buildPostGrid('saved_outfits');
  }

Widget _buildSavedOutfitCard(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>?;

  if (data == null || data['itemIds'] == null) {
    return const Text("Dữ liệu outfit không hợp lệ");
  }

  final List<String> itemIds = List<String>.from(data['itemIds']);
  final prompt = data['prompt'] ?? '';
  final season = data['seasonFilter'] ?? '';
  final occasion = data['occasionFilter'] ?? '';
  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('clothing_items')
        .where(FieldPath.documentId, whereIn: itemIds)
        .get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data!.docs;

      // Convert snapshot to List<ClothingItem>
      final outfit = docs.map((doc) {
        final itemData = doc.data() as Map<String, dynamic>;
        return ClothingItem(
          id: doc.id,
          name: itemData['name'] ?? '',
          category: itemData['category'] ?? '',
          color: itemData['color'] ?? '',
          style: itemData['style'] ?? '',
          season: itemData['season'] ?? '',
          occasions: List<String>.from(itemData['occasions'] ?? []),
          imageUrl: itemData['base64Image'] ?? '',
          matchingColors: List<String>.from(data['matchingColors'] ?? []),
        );
      }).toList();

      return InkWell(
        onTap: () {
          final clothingItemId = itemIds.isNotEmpty ? itemIds.first : null;
          final uid = user?.uid;
          if (clothingItemId != null && uid != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClothingDetailPage(
                  clothingItemId: clothingItemId,
                  uid: uid,
                  filterCategory: null, // hoặc lấy từ data nếu muốn
                  outfitItemIds: itemIds,
                ),
              ),
            );
          }
        },
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề + nút xóa
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${prompt.isNotEmpty ? prompt : 'Random'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Xóa outfit này",
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Xóa Outfit"),
                            content: const Text("Bạn có chắc muốn xóa outfit này?"),
                            actions: [
                              TextButton(
                                child: const Text("Hủy"),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Xóa"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await doc.reference.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Đã xóa outfit")),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Ảnh
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: docs.map((itemDoc) {
                    final itemData = itemDoc.data() as Map<String, dynamic>;
                    final base64Image = itemData['base64Image'];
                    Uint8List? imageBytes;

                    if (base64Image != null) {
                      try {
                        final cleanBase64 = base64Image.split(',').last;
                        imageBytes = base64Decode(cleanBase64);
                      } catch (_) {}
                    }

                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(imageBytes, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.image_not_supported),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text("Mùa: $season | Dịp: ${occasion ?? 'Không rõ'}"),
                if (createdAt != null)
                  Text(
                    "Lưu lúc: ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
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
                        final doc = docs[index];
                        return collectionName == 'saved_outfits'
                          ? _buildSavedOutfitCard(doc)
                          : _buildPostCard(doc);
                      },

                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: collectionName == 'saved_outfits'
                              ? _buildSavedOutfitCard(doc)
                              : _buildPostCard(doc)
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
          _settingTile(Icons.logout, "Logout", () async {
            Navigator.pop(context); // đóng popup

            await FirebaseAuth.instance.signOut();

            // Xoá navigation stack và quay về LoginPage (ví dụ)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()), // thay bằng trang đăng nhập của bạn
              (Route<dynamic> route) => false,
            );
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

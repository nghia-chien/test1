import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../color/color.dart'; // Sửa lại đường dẫn import cho đúng
import 'dart:html' as html;

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
  bool _isEditing = false;

  int selectedTabIndex = 0;
  final List<String> tabs = ["Item", "Outfit", "Lookbook"];

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
        _emailController.text = data['email'] ?? user!.email!;
        _bioController.text = data['bio'] ?? '';
        _imageUrl = data['imageUrl'];
      });
    } else {
      await _firestore.collection('users').doc(user!.uid).set({
        'name': user!.displayName ?? '',
        'email': user!.email ?? '',
        'bio': '',
        'imageUrl': null,
      });
      _nameController.text = user!.displayName ?? '';
      _emailController.text = user!.email ?? '';
    }
  }

  Future<void> _pickImage() async {
    final html.FileUploadInputElement input = html.FileUploadInputElement()
      ..accept = 'image/*';
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

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate() && user != null) {
      await _firestore.collection('users').doc(user!.uid).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'bio': _bioController.text,
        'imageUrl': _imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      _toggleEdit();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 8),
            _buildTabBar(),
            const SizedBox(height: 8),
            _buildCategoryFilter(),
            const SizedBox(height: 12),
            Expanded(child: _buildContentSection()),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Xử lý thêm item/outfit/lookbook mới
        },
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        shape: const CircleBorder(),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFE3D3F9),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: _imageUrl != null
                      ? NetworkImage(_imageUrl!)
                      : null,
                  child: _imageUrl == null
                      ? Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : "N",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
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
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isEditing
              ? Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        enabled: false,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(labelText: 'Bio'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Text(_nameController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(_emailController.text, style: const TextStyle(color: Colors.black54)),
                    if (_bioController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_bioController.text, style: const TextStyle(color: Colors.black87)),
                      ),
                  ],
                ),
          const SizedBox(height: 12),
          if (!_isEditing)
            ElevatedButton(
              onPressed: () {
                // TODO: Xử lý follow/unfollow user
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Follow"),
            ),
        ],
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
          onTap: () {
            setState(() {
              selectedTabIndex = index;
            });
          },
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isActive ? primaryBlue : Colors.black54,
              decoration: isActive ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ["All", "Bags", "Bottom", "Top", "Shoes"];
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _CategoryCircle(label: categories[index]),
      ),
    );
  }

  Widget _buildContentSection() {
    // TODO: Hiển thị danh sách item/outfit/lookbook từ backend
    if (selectedTabIndex == 0) {
      return _buildItemGrid("Item");
    } else if (selectedTabIndex == 1) {
      return _buildItemGrid("Outfit");
    } else {
      return _buildItemGrid("Lookbook");
    }
  }

  Widget _buildItemGrid(String type) {
    // TODO: Hiển thị danh sách động từ backend, không hardcode
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: List.generate(4, (index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "$type  {index + 1}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  final String label;
  const _CategoryCircle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(radius: 18, backgroundColor: Colors.grey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  const _SettingsSheet({this.isEditing = false, required this.onEdit, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _settingTile(Icons.edit, isEditing ? "Save" : "Edit Profile", () {
            Navigator.pop(context);
            if (isEditing) {
              onSave();
            } else {
              onEdit();
            }
          }),
          _settingTile(Icons.share, "Share Profile", () {}),
          _settingTile(Icons.lock, "Privacy & Settings", () {}),
          _settingTile(Icons.help_outline, "Help", () {}),
          _settingTile(Icons.color_lens, "Theme", () {}),
          _settingTile(Icons.favorite_border, "Favorite", () {}),
          _settingTile(Icons.logout, "Log out", () {
            Navigator.pop(context);
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

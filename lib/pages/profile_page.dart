// Add your imports here
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    }
  }

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files?.isEmpty ?? true) return;
    final file = input.files!.first;
    final reader = html.FileReader()..readAsDataUrl(file);
    await reader.onLoad.first;
    setState(() => _imageUrl = reader.result as String);
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  Future<void> _saveChanges() async {
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
          onPressed: () => Navigator.pop(context),
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
        onPressed: () {},
        backgroundColor: Color(0xFF5B67CA),
        child: Icon(
          selectedTabIndex == 0
              ? Icons.checkroom
              : selectedTabIndex == 1
                  ? Icons.style
                  : Icons.collections_bookmark,
          color: Colors.white,
        ),
        shape: const CircleBorder(),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFE3D3F9),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                    child: _imageUrl == null
                        ? Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : "N",
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.camera_alt, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert),
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
              )
            ],
          ),
          const SizedBox(height: 12),
          _isEditing
              ? Form(
                  key: _formKey,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    margin: const EdgeInsets.only(top: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Name'),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Enter your name' : null,
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
                    ),
                  ),
                )
              : Column(
                  children: [
                    Text(_nameController.text,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(_emailController.text, style: const TextStyle(color: Colors.black54)),
                    if (_bioController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_bioController.text,
                            style: const TextStyle(color: Colors.black87)),
                      ),
                  ],
                ),
          const SizedBox(height: 8),
          if (!_isEditing)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5B67CA),
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

  Widget _buildCategoryFilter() {
    final categories = ["All", "Bags", "Bottom", "Top", "Shoes"];
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final label = categories[index];
          final isSelected = index == 0;
          return Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isSelected ? Color(0xFF5B67CA) : Colors.grey.shade300,
                child: Icon(Icons.category, size: 18, color: isSelected ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: List.generate(4, (index) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Center(
              child: Text(
                "${tabs[selectedTabIndex]} ${index + 1}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
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

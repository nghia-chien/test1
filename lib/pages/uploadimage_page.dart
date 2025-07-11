import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadClothingPage extends StatefulWidget {
  const UploadClothingPage({super.key});

  @override
  State<UploadClothingPage> createState() => _UploadClothingPageState();
}

class _UploadClothingPageState extends State<UploadClothingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  final TextEditingController _occasionsController = TextEditingController();

  String? _base64Image;
  bool _isUploading = false;

  // ------------------------------
  Future<void> _pickImage() async {
    final html.FileUploadInputElement input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;

    if (input.files != null && input.files!.isNotEmpty) {
      final file = input.files!.first;
      final reader = html.FileReader();
      reader.readAsDataUrl(file); // data:image/jpeg;base64,...
      await reader.onLoad.first;

      setState(() {
        _base64Image = reader.result as String?;
      });
    }
  }

  Future<void> _uploadToFirestore() async {
    if (_base64Image == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh và nhập tên')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Người dùng chưa đăng nhập';

      await FirebaseFirestore.instance.collection('clothing_items').add({
        'id': user.uid,
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'color': _colorController.text.trim(),
        'style': _styleController.text.trim(),
        'season': _seasonController.text.trim(),
        'occasions': _occasionsController.text.trim().split(',').map((e) => e.trim()).toList(),
        'base64Image': _base64Image,
        'uploaded_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải lên thành công!')),
      );

      setState(() {
        _base64Image = null;
        _nameController.clear();
        _categoryController.clear();
        _colorController.clear();
        _styleController.clear();
        _seasonController.clear();
        _occasionsController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _colorController.dispose();
    _styleController.dispose();
    _seasonController.dispose();
    _occasionsController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tải ảnh & thông tin trang phục')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _base64Image != null
                ? Image.memory(
                    base64Decode(_base64Image!.split(',').last),
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : const Text('Chưa chọn ảnh'),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Chọn ảnh từ thư viện'),
            ),
            const SizedBox(height: 16),

            _buildTextField('Tên trang phục', _nameController),
            _buildTextField('Loại (category)', _categoryController),
            _buildTextField('Màu sắc', _colorController),
            _buildTextField('Phong cách (style)', _styleController),
            _buildTextField('Mùa (season)', _seasonController),
            _buildTextField(
              'Dịp sử dụng (occasions)',
              _occasionsController,
              hint: 'Ví dụ: đi làm, tiệc, du lịch',
            ),

            const SizedBox(height: 16),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _uploadToFirestore,
                    icon: const Icon(Icons.upload),
                    label: const Text('Tải lên'),
                  ),
          ],
        ),
      ),
    );
  }
}

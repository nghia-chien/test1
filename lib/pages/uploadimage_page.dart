import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/activity_history_service.dart';

class UploadClothingPage extends StatefulWidget {
  const UploadClothingPage({super.key});

  @override
  State<UploadClothingPage> createState() => _UploadClothingPageState();
}

class _UploadClothingPageState extends State<UploadClothingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customColorController = TextEditingController();
  final TextEditingController _customStyleController = TextEditingController();

  String? _selectedCategory;
  String? _selectedColor;
  String? _selectedStyle;
  String? _selectedSeason;
  List<String> _selectedOccasions = [];
  String? _base64Image;
  bool _isUploading = false;
  bool _isPublic = true;

  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color primaryBlue = Color(0xFF209CFF);
  static const Color secondaryGrey = Color(0xFF7D7F85);
  static const Color darkgrey = Color(0xFF231f20);
  static const Color black = Color(0xFF000000);

  final List<String> categories = ['Áo', 'Quần', 'Váy', 'Phụ kiện','Giày','Áo Khoác'];
  final List<String> colors = ['Đen', 'Trắng','Xám', 'Đỏ', 'Vàng', 'Cam', 'Xanh lá', 'Xanh dương nhạt', 'Xanh dương đậm', 'Hồng', 'Be','Nâu',];
  final List<String> styles = ['Classic', 'Minimalism', 'Hippie', 'Casual', 'Sporty', 'Preppy', 'Normcore', 'Vintage'];
  final List<String> seasons = ['Xuân', 'Hè', 'Thu', 'Đông', 'Tất Cả'];
  final List<String> occasionOptions = ['Đi làm', 'Tiệc', 'Du lịch', 'Hẹn hò', 'Thường ngày'];

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files != null && input.files!.isNotEmpty) {
      final file = input.files!.first;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      await reader.onLoad.first;
      setState(() {
        _base64Image = reader.result as String?;
      });
    }
  }

  Future<void> _uploadToFirestore() async {
    if (_base64Image == null || _nameController.text.trim().isEmpty) {
      _showError('Vui lòng chọn ảnh và nhập tên');
      return;
    }
    if (_selectedCategory == null) return _showError('Vui lòng chọn loại trang phục');
    if (_selectedColor == null) return _showError('Vui lòng chọn màu sắc');
    if (_selectedStyle == null) return _showError('Vui lòng chọn phong cách');
    if (_selectedSeason == null) return _showError('Vui lòng chọn mùa phù hợp');

    final colorToSave = _selectedColor == 'Khác...' ? _customColorController.text.trim() : _selectedColor;
    final styleToSave = _selectedStyle == 'Khác...' ? _customStyleController.text.trim() : _selectedStyle;

    if (colorToSave == null || colorToSave.isEmpty) {
      return _showError('Vui lòng nhập màu khi chọn "Khác..."');
    }
    if (styleToSave == null || styleToSave.isEmpty) {
      return _showError('Vui lòng nhập phong cách khi chọn "Khác..."');
    }

    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Bạn chưa đăng nhập');
        return;
      }

      final itemRef = await FirebaseFirestore.instance.collection('clothing_items').add({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'color': colorToSave,
        'style': styleToSave,
        'season': _selectedSeason,
        'occasions': _selectedOccasions,
        'base64Image': _base64Image,
        'uploaded_at': Timestamp.now(),
        'public': _isPublic,
      });

      await ActivityHistoryService.addActivity(
        action: 'upload',
        description: 'Tải lên trang phục: ${_nameController.text.trim()}',
        imageUrl: _base64Image,
        metadata: {
          'itemId': itemRef.id,
          'category': _selectedCategory,
          'color': colorToSave,
          'style': styleToSave,
          'season': _selectedSeason,
          'public': _isPublic,
        },
      );

      _resetForm();
      _showMessage('Tải lên thành công!');
    } catch (e) {
      _showError('Lỗi: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showMessage(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Constants.darkBlueGrey));

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _customColorController.clear();
      _customStyleController.clear();
      _selectedCategory = null;
      _selectedColor = null;
      _selectedStyle = null;
      _selectedSeason = null;
      _selectedOccasions = [];
      _base64Image = null;
      _isPublic = true;
    });
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Constants.darkBlueGrey, fontFamily: 'Montserrat', fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Constants.pureWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: secondaryGrey.withAlpha((255 * 0.3).round())),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: black, width: 2),
          ),
          labelStyle: TextStyle(color: Constants.darkBlueGrey, fontFamily: 'Montserrat', fontWeight: FontWeight.w500),
          hintStyle: TextStyle(color: Constants.secondaryGrey, fontFamily: 'Montserrat', fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, List<T> items, T? value, void Function(T?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString()))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: secondaryGrey.withAlpha((255 * 0.3).round())),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: black, width: 2),
          ),
          labelStyle: TextStyle(color: darkgrey),
        ),
        icon: Icon(Icons.arrow_drop_down, color: black),
        dropdownColor: lightGray,
        style: TextStyle(color: darkgrey, fontFamily: 'Montserrat', fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorOptions = [...colors, 'Khác...'];
    final styleOptions = [...styles, 'Khác...'];

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: const Text('Tải ảnh & thông tin trang phục'),
        backgroundColor: lightGray,
        foregroundColor: darkgrey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _base64Image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_base64Image!.split(',').last),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Text('Chưa chọn ảnh'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo, color: lightGray),
              label: const Text('Chọn ảnh từ thư viện', style: TextStyle(color: lightGray)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('Tên trang phục', _nameController),
            _buildDropdown('Loại', categories, _selectedCategory, (val) => setState(() => _selectedCategory = val)),
            _buildDropdown('Màu sắc', colorOptions, _selectedColor, (val) {
              setState(() {
                _selectedColor = val;
              });
            }),
            if (_selectedColor == 'Khác...') _buildTextField('Nhập màu khác', _customColorController),
            _buildDropdown('Phong cách', styleOptions, _selectedStyle, (val) {
              setState(() {
                _selectedStyle = val;
              });
            }),
            if (_selectedStyle == 'Khác...') _buildTextField('Nhập phong cách khác', _customStyleController),
            _buildDropdown('Mùa', seasons, _selectedSeason, (val) => setState(() => _selectedSeason = val)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: occasionOptions.map((option) {
                  final isSelected = _selectedOccasions.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selected ? _selectedOccasions.add(option) : _selectedOccasions.remove(option);
                      });
                    },
                    selectedColor: primaryBlue.withOpacity(0.2),
                    labelStyle: TextStyle(color: isSelected ? primaryBlue : secondaryGrey, fontWeight: FontWeight.w500),
                    backgroundColor: Constants.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? primaryBlue : secondaryGrey),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _uploadToFirestore,
                    icon: const Icon(Icons.upload, color: lightGray),
                    label: const Text('Tải lên', style: TextStyle(color: lightGray)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

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
  String? _selectedCategory;
  String? _selectedColor;
  String? _selectedStyle;
  String? _selectedSeason;
  List<String> _selectedOccasions = [];
  String? _customColor;
  String? _customStyle;
  String? _base64Image;
  bool _isUploading = false;
  bool _isPublic = true;

  final List<String> categories = ['Áo', 'Quần', 'Váy', 'Phụ kiện', 'Mũ'];
  final List<String> colors = ['Đen', 'Trắng','Đỏ', 'Xanh', 'Vàng','Cam','Xanh lá','Xanh nhạt','Xanh đậm','Hồng','Be' ];
  final List<String> styles = ['Classic','Minimalism','Hippie','Bohemian','Sporty ','Preppy','Normcore','Vintage'];
  final List<String> seasons = ['Xuân', 'Hè', 'Thu', 'Đông', 'Tất Cả'];
  final List<String> occasionOptions = ['Đi làm', 'Tiệc', 'Du lịch', 'Hẹn hò', 'Thường ngày'];

  Future<void> _pickImage() async {
    final html.FileUploadInputElement input = html.FileUploadInputElement()..accept = 'image/*';
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
    if (_selectedCategory == null || _selectedColor == null || _selectedStyle == null || _selectedSeason == null) {
      _showError('Vui lòng chọn đủ thông tin');
      return;
    }

    final colorToSave = _selectedColor == 'Khác...' ? _customColor : _selectedColor;
    final styleToSave = _selectedStyle == 'Khác...' ? _customStyle : _selectedStyle;

    if ((_selectedColor == 'Khác...' && (colorToSave == null || colorToSave.trim().isEmpty)) ||
        (_selectedStyle == 'Khác...' && (styleToSave == null || styleToSave.trim().isEmpty))) {
      _showError('Vui lòng nhập giá trị cho trường "Khác..."');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Người dùng chưa đăng nhập';

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
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Constants.darkBlueGrey));

  void _resetForm() {
    setState(() {
      _base64Image = null;
      _nameController.clear();
      _selectedCategory = null;
      _selectedColor = null;
      _selectedStyle = null;
      _selectedSeason = null;
      _selectedOccasions = [];
      _customColor = null;
      _customStyle = null;
      _isPublic = true;
    });
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: Constants.darkBlueGrey,
          fontFamily: 'BeautiqueDisplay',
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Constants.pureWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Constants.secondaryGrey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Constants.primaryBlue, width: 2),
          ),
          labelStyle: TextStyle(
            color: Constants.darkBlueGrey,
            fontFamily: 'BeautiqueDisplay',
          ),
          hintStyle: TextStyle(
            color: Constants.secondaryGrey,
            fontFamily: 'BeautiqueDisplay',
          ),
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
          fillColor: Constants.pureWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Constants.secondaryGrey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Constants.primaryBlue, width: 2),
          ),
          labelStyle: TextStyle(color: Constants.darkBlueGrey),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Constants.primaryBlue),
        dropdownColor: Constants.pureWhite,
        style: TextStyle(
          color: Constants.darkBlueGrey,
          fontFamily: 'BeautiqueDisplay',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorOptions = [...colors, 'Khác...'];
    final styleOptions = [...styles, 'Khác...'];

    return Scaffold(
      backgroundColor: Constants.pureWhite,
      appBar: AppBar(
        title: const Text('Tải ảnh & thông tin trang phục'),
        backgroundColor: Constants.pureWhite,
        foregroundColor: Constants.darkBlueGrey,
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
                      fit: BoxFit.cover,
                    ),
                  )
                : const Text('Chưa chọn ảnh'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo, color: Constants.pureWhite),
              label: const Text('Chọn ảnh từ thư viện', style: TextStyle(color: Constants.pureWhite)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('Tên trang phục', _nameController),
            _buildDropdown('Loại', categories, _selectedCategory, (val) => setState(() => _selectedCategory = val)),
            _buildDropdown('Màu sắc', colorOptions, _selectedColor, (val) {
              setState(() {
                _selectedColor = val;
                if (val != 'Khác...') _customColor = null;
              });
            }),
            if (_selectedColor == 'Khác...')
              _buildTextField('Nhập màu khác', TextEditingController(text: _customColor)),
            _buildDropdown('Phong cách', styleOptions, _selectedStyle, (val) {
              setState(() {
                _selectedStyle = val;
                if (val != 'Khác...') _customStyle = null;
              });
            }),
            if (_selectedStyle == 'Khác...')
              _buildTextField('Nhập phong cách khác', TextEditingController(text: _customStyle)),
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
                        if (selected) {
                          _selectedOccasions.add(option);
                        } else {
                          _selectedOccasions.remove(option);
                        }
                      });
                    },
                    selectedColor: Constants.primaryBlue.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Constants.primaryBlue : Constants.secondaryGrey,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: Constants.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? Constants.primaryBlue : Constants.secondaryGrey),
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
                    icon: const Icon(Icons.upload, color: Constants.pureWhite),
                    label: const Text('Tải lên', style: TextStyle(color: Constants.pureWhite)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryBlue,
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

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
  String? _customOccasion;
  bool _isPublic = true;

  final List<String> categories = ['Áo', 'Quần', 'Váy', 'Phụ kiện', 'Mũ'];
  final List<String> colors = ['Đen', 'Trắng','Đỏ', 'Xanh', 'Vàng','Cam','Xanh lá','Xanh nhạt','Xanh đậm','Hồng','Be' ];
  final List<String> styles = ['Classic','Minimalism','Hippie','Bohemian','Sporty ','Preppy','Normcore','Vintage'];
  final List<String> seasons = ['Xuân', 'Hè', 'Thu', 'Đông', 'Tất Cả'];
  final List<String> occasionOptions = ['Đi làm', 'Tiệc', 'Du lịch', 'Hẹn hò', 'Thường ngày'];

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
    if (_selectedCategory == null || _selectedColor == null || _selectedStyle == null || _selectedSeason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đủ thông tin')),
      );
      return;
    }
    final colorToSave = _selectedColor == 'Khác...' ? _customColor : _selectedColor;
    final styleToSave = _selectedStyle == 'Khác...' ? _customStyle : _selectedStyle;
    if ((_selectedColor == 'Khác...' && (colorToSave == null || colorToSave.trim().isEmpty)) ||
        (_selectedStyle == 'Khác...' && (styleToSave == null || styleToSave.trim().isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá trị cho trường "Khác..."')),
      );
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

      // Thêm activity history cho upload clothing
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải lên thành công!')),
      );
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required T? value,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString()))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ------------------------------
  @override
  Widget build(BuildContext context) {
    final colorOptions = [...colors, 'Khác...'];
    final styleOptions = [...styles, 'Khác...'];
    return Scaffold(
      backgroundColor: Constants.pureWhite,
      appBar: AppBar(
        title: const Text('Tải ảnh & thông tin trang phục', style: TextStyle(color: Constants.darkBlueGrey)),
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
                      height: 200,
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
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Constants.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('Tên trang phục', _nameController),
            _buildDropdown<String>(
              label: 'Loại (category)',
              items: categories,
              value: _selectedCategory,
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            _buildDropdown<String>(
              label: 'Màu sắc',
              items: [...colors, if (_customColor != null && _customColor!.isNotEmpty && !colors.contains(_customColor)) _customColor!, 'Khác...'],
              value: _selectedColor,
              onChanged: (val) {
                setState(() {
                  _selectedColor = val;
                  if (val != 'Khác...') _customColor = null;
                });
              },
            ),
            if (_selectedColor == 'Khác...')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Nhập màu sắc khác',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (val) => setState(() => _customColor = val),
                ),
              ),
            _buildDropdown<String>(
              label: 'Phong cách (style)',
              items: styleOptions,
              value: _selectedStyle,
              onChanged: (val) {
                setState(() {
                  _selectedStyle = val;
                  if (val != 'Khác...') _customStyle = null;
                });
              },
            ),
            if (_selectedStyle == 'Khác...')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Nhập phong cách khác',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (val) => setState(() => _customStyle = val),
                ),
              ),
            _buildDropdown<String>(
              label: 'Mùa (season)',
              items: seasons,
              value: _selectedSeason,
              onChanged: (val) => setState(() => _selectedSeason = val),
            ),
            // Dịp sử dụng (occasions) - multi-select bằng Wrap + FilterChip
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
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
                      selectedColor: Constants.primaryBlue.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? Constants.primaryBlue : Constants.darkBlueGrey.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: Constants.pureWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? Constants.primaryBlue : Constants.secondaryGrey.withOpacity(0.3), width: 1.5),
                      ),
                      elevation: 2,
                      pressElevation: 4,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _uploadToFirestore,
                    icon: const Icon(Icons.upload, color: Constants.pureWhite),
                    label: const Text('Tải lên', style: TextStyle(color: Constants.pureWhite)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      foregroundColor: Constants.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
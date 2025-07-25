import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClothingDetailPage extends StatefulWidget {
  final String clothingItemId;
  final String uid;
  final String? filterCategory;
  final List<String>? outfitItemIds;
  

  const ClothingDetailPage({
    super.key, 
    required this.clothingItemId,
    required this.uid,
    this.filterCategory,
    this.outfitItemIds,
  });

  @override
  State<ClothingDetailPage> createState() => _ClothingDetailPageState();
}

class _ClothingDetailPageState extends State<ClothingDetailPage> {
  Map<String, dynamic>? clothingData;
  List<Map<String, dynamic>> thumbnailItems = [];
  String? selectedMainImageId;
  bool _isEditing = false;
  bool _isLoadingThumbnails = false;
  bool _isLoadingMainItem = false;

  final _formKey = GlobalKey<FormState>();

  List<String> categories = ['Áo', 'Quần', 'Váy', 'Giày', 'Áo Khoác', 'Phụ Kiện'];
  List<String> styles = ['Casual', 'Thanh lịch', 'Thể thao', 'Năng động'];
  List<String> colors = ['Trắng', 'Đen', 'Xám', 'Đỏ', 'Xanh', 'Vàng', 'Nâu'];
  List<String> seasons = ['Xuân', 'Hạ', 'Thu', 'Đông','Tất Cả'];
  List<String> allOccasions = ['Đi học', 'Đi làm', 'Dạo phố', 'Dự tiệc', 'Ở nhà'];

  @override
  void initState() {
    super.initState();
    selectedMainImageId = widget.clothingItemId;
    _loadClothingItem();
    _loadThumbnailItems();
    _loadSelectableOptions();
  }

  Future<void> _loadClothingItem() async {
    setState(() => _isLoadingMainItem = true);
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clothing_items')
          .doc(widget.clothingItemId)
          .get();
      
      if (doc.exists && mounted) {
        setState(() {
          clothingData = doc.data();
          _isLoadingMainItem = false;
        });
      }
    } catch (e) {
      print('Error loading clothing item: $e');
      if (mounted) {
        setState(() => _isLoadingMainItem = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _loadThumbnailItems() async {
    setState(() => _isLoadingThumbnails = true);
    
    try {
      Query query = FirebaseFirestore.instance.collection('clothing_items');
      query = query.where('uid', isEqualTo: widget.uid);
      
      // Filter by category if provided
      if (widget.filterCategory != null) {
        query = query.where('category', isEqualTo: widget.filterCategory);
      }
      
      // Filter by outfit item IDs if provided
      if (widget.outfitItemIds != null && widget.outfitItemIds!.isNotEmpty) {
        if (widget.outfitItemIds!.length <= 10) {
          query = query.where(FieldPath.documentId, whereIn: widget.outfitItemIds);
        } else {
          // Handle more than 10 items with batch queries
          await _loadLargeOutfitItems();
          return;
        }
      }
      
      final querySnapshot = await query.get();
      final items = querySnapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...?(doc.data() as Map<String, dynamic>?),
      }).toList();

      if (mounted) {
        setState(() {
          thumbnailItems = items;
          _isLoadingThumbnails = false;
        });
      }
    } catch (e) {
      print('Error loading thumbnail items: $e');
      if (mounted) {
        setState(() => _isLoadingThumbnails = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách ảnh: $e')),
        );
      }
    }
  }

  Future<void> _loadLargeOutfitItems() async {
    try {
      // Split large lists into chunks of 10 for Firestore 'in' queries
      final chunks = <List<String>>[];
      for (int i = 0; i < widget.outfitItemIds!.length; i += 10) {
        chunks.add(widget.outfitItemIds!.sublist(
          i, 
          i + 10 > widget.outfitItemIds!.length 
            ? widget.outfitItemIds!.length 
            : i + 10
        ));
      }

      final List<Map<String, dynamic>> allItems = [];
      
      for (final chunk in chunks) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('clothing_items')
            .where('uid', isEqualTo: widget.uid)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        
        allItems.addAll(querySnapshot.docs.map<Map<String, dynamic>>((doc) => {
          'id': doc.id,
          ...?(doc.data() as Map<String, dynamic>?),
        }));
      }

      if (mounted) {
        setState(() {
          thumbnailItems = allItems;
          _isLoadingThumbnails = false;
        });
      }
    } catch (e) {
      print('Error loading large outfit items: $e');
      if (mounted) {
        setState(() => _isLoadingThumbnails = false);
      }
    }
  }

  Future<void> _loadSelectableOptions() async {
    // Ví dụ: lấy từ Firestore collection 'options' (bạn có thể đổi collection tuỳ ý)
    try {
      final doc = await FirebaseFirestore.instance.collection('options').doc('clothing').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          if (data['categories'] is List) categories = List<String>.from(data['categories']);
          if (data['styles'] is List) styles = List<String>.from(data['styles']);
          if (data['colors'] is List) colors = List<String>.from(data['colors']);
          if (data['seasons'] is List) seasons = List<String>.from(data['seasons']);
          if (data['occasions'] is List) allOccasions = List<String>.from(data['occasions']);
        });
      }
    } catch (e) {
      // Nếu lỗi thì giữ giá trị mặc định
      print('Không thể load options clothing: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('clothing_items')
          .doc(widget.clothingItemId)
          .update(clothingData!);

      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadClothingItem();
    } catch (e) {
      print('Error saving changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleOccasion(String occasion, bool selected) {
    final list = List<String>.from(clothingData!['occasions'] ?? []);
    if (selected) {
      if (!list.contains(occasion)) {
        list.add(occasion);
      }
    } else {
      list.remove(occasion);
    }
    setState(() {
      clothingData!['occasions'] = list;
    });
  }

  void _selectMainImage(String itemId) {
    setState(() {
      selectedMainImageId = itemId;
    });
  }

  Map<String, dynamic>? _getSelectedItemData() {
    if (selectedMainImageId == widget.clothingItemId) {
      return clothingData;
    } else {
      try {
        return thumbnailItems.firstWhere(
          (item) => item['id'] == selectedMainImageId,
        );
      } catch (e) {
        return clothingData; // Fallback to main item
      }
    }
  }

  Widget _buildSafeImage(String? base64Image, {double? height, double? width}) {
    if (base64Image == null || base64Image.isEmpty) {
      return Container(
        height: height ?? 250,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported, 
              size: height != null ? height / 5 : 50, 
              color: Colors.grey[400],
            ),
            if (height == null || height > 100)
              Text(
                'Không có ảnh',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
    }
    
    try {
      final cleaned = base64Image.contains(',')
          ? base64Image.split(',').last
          : base64Image;
      final bytes = base64Decode(cleaned);
      return Image.memory(
        bytes, 
        height: height ?? 250, 
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height ?? 250,
            width: width,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image, 
                  size: height != null ? height / 5 : 50, 
                  color: Colors.red[300],
                ),
                if (height == null || height > 100)
                  Text(
                    'Ảnh lỗi',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: height ?? 250,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error, 
              size: height != null ? height / 5 : 50, 
              color: Colors.red,
            ),
            if (height == null || height > 100)
              const Text(
                'Ảnh không hợp lệ',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildMainImage() {
    final selectedItem = _getSelectedItemData();
    final base64Image = selectedItem?['base64Image'];
    
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildSafeImage(base64Image, height: 300),
      ),
    );
  }

  Widget _buildThumbnailList() {
    if (_isLoadingThumbnails) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Đang tải...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (thumbnailItems.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text(
                'Không có mục nào để hiển thị',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              'Danh sách ảnh (${thumbnailItems.length})',
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: thumbnailItems.length,
            itemBuilder: (context, index) {
              final item = thumbnailItems[index];
              final isSelected = item['id'] == selectedMainImageId;
              
              return GestureDetector(
                onTap: () => _selectMainImage(item['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        _buildSafeImage(item['base64Image'], height: 100, width: 80),
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDisplay() {
    final selectedItem = _getSelectedItemData();
    if (selectedItem == null) return const SizedBox();

    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin chi tiết',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const Divider(),
            _buildInfoRow('👕 Tên', selectedItem['name'] ?? 'N/A'),
            _buildInfoRow('📦 Loại', selectedItem['category'] ?? 'N/A'),
            _buildInfoRow('🎨 Màu', selectedItem['color'] ?? 'N/A'),
            _buildInfoRow('✨ Phong cách', selectedItem['style'] ?? 'Chưa có'),
            _buildInfoRow('🌤 Mùa', selectedItem['season'] ?? 'N/A'),
            _buildInfoRow('🎯 Dịp', 
              (selectedItem['occasions'] as List?)?.join(', ') ?? 'Chưa có'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMainItem || clothingData == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        
        title: const Text('Chi tiết Trang phục' ,
                      style: TextStyle( 
                        fontSize: 18, 
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.save, color: Colors.green),
              onPressed: _saveChanges,
              tooltip: 'Lưu thay đổi',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadClothingItem();
                });
              },
              tooltip: 'Hủy',
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Chỉnh sửa',
            ),
        ],
      ),
      body: SingleChildScrollView(
        
        padding: const EdgeInsets.all(16),
        child: _isEditing ? _buildEditForm() : _buildViewMode(),
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainImage(),
        const SizedBox(height: 20),
        _buildThumbnailList(),
        const SizedBox(height: 20),
        _buildInfoDisplay(),
      ],
    );
  }

  Widget _buildEditForm() {
    // Đảm bảo allOccasions chứa tất cả dịp hiện tại
    final currentOccasions = List<String>.from(clothingData!['occasions'] ?? []);
    final displayOccasions = List<String>.from(allOccasions);
    for (final o in currentOccasions) {
      if (!displayOccasions.contains(o)) displayOccasions.add(o);
    }
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainImage(),
          const SizedBox(height: 20),
          _buildThumbnailList(),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chỉnh sửa thông tin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const Divider(),

                  // Name
                  TextFormField(
                    initialValue: clothingData!['name'],
                    decoration: const InputDecoration(
                      labelText: 'Tên', 
                        labelStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      prefixIcon: Icon(Icons.label),
                    ),
                    onChanged: (value) => clothingData!['name'] = value,
                    validator: (value) => 
                        value?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField(
                    value: clothingData!['category'],
                    items: categories.map((cat) => 
                        DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (value) => clothingData!['category'] = value,
                    decoration: const InputDecoration(
                      labelText: 'Loại',
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Color
                  DropdownButtonFormField(
                    value: clothingData!['color'],
                    items: [
                      ...colors,
                      if (clothingData!['color'] != null && !colors.contains(clothingData!['color']))
                        clothingData!['color'],
                    ].map((color) => DropdownMenuItem(value: color, child: Text(color))).toList(),
                    onChanged: (value) => clothingData!['color'] = value,
                    decoration: const InputDecoration(
                      labelText: 'Màu sắc',
                      prefixIcon: Icon(Icons.palette),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Style
                  TextFormField(
                    initialValue: clothingData!['style'] ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Phong cách',
                      prefixIcon: Icon(Icons.style),
                    ),
                    onChanged: (value) => clothingData!['style'] = value,
                  ),
                  const SizedBox(height: 16),

                  // Season
                  DropdownButtonFormField(
                    value: clothingData!['season'],
                    items: seasons.map((season) => 
                        DropdownMenuItem(value: season, child: Text(season))).toList(),
                    onChanged: (value) => clothingData!['season'] = value,
                    decoration: const InputDecoration(
                      labelText: 'Mùa',
                      prefixIcon: Icon(Icons.wb_sunny),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Occasions
                  const Text(
                    '🎯 Dịp sử dụng:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  ...displayOccasions.map((o) {
                    final selected = (clothingData!['occasions'] ?? []).contains(o);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(o),
                      onChanged: (val) => _toggleOccasion(o, val!),
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
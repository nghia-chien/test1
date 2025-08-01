import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';

class EditOutfitPage extends StatefulWidget {
  const EditOutfitPage({super.key});

  @override
  State<EditOutfitPage> createState() => _EditOutfitPageState();
}

class _EditOutfitPageState extends State<EditOutfitPage>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedItemIds = [];
  List<QueryDocumentSnapshot> _allItems = [];
  List<QueryDocumentSnapshot> _filteredItems = [];
  String? _editingOutfitId;
  String _selectedCategory = 'Tất cả';

  // Simplified animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Color palette
  final List<String> _categories = [
    'Tất cả', 'Áo', 'Quần', 'Váy', 'Giày', 'Phụ kiện'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadItems();
    _searchController.addListener(_applyFilters);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _promptController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('clothing_items')
        .where('uid', isEqualTo: uid)
        .get();
    setState(() {
      _allItems = snapshot.docs;
      _filteredItems = List.from(_allItems);
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final category = (data['category'] ?? '').toString();
        final matchesSearch = name.contains(query);
        final matchesCategory = _selectedCategory == 'Tất cả' || category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _toggleItem(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  void _selectOutfit(Map<String, dynamic> outfit, String outfitId) {
    setState(() {
      _promptController.text = outfit['prompt'] ?? '';
      _selectedItemIds
        ..clear()
        ..addAll(List<String>.from(outfit['itemIds'] ?? []));
      _editingOutfitId = outfitId;
    });
    Navigator.pop(context);
  }

  Future<void> _saveOutfit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selectedItemIds.isEmpty || _promptController.text.trim().isEmpty) return;

    final data = {
      'uid': uid,
      'prompt': _promptController.text.trim(),
      'itemIds': _selectedItemIds,
      'createdAt': Timestamp.now(),
    };

    try {
      if (_editingOutfitId != null) {
        await FirebaseFirestore.instance
            .collection('saved_outfits')
            .doc(_editingOutfitId)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('saved_outfits')
            .add(data);
      }

      if (!mounted) return;

      setState(() {
        _promptController.clear();
        _searchController.clear();
        _selectedItemIds.clear();
        _editingOutfitId = null;
        _selectedCategory = 'Tất cả';
        _filteredItems = List.from(_allItems);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingOutfitId != null ? 'Đã cập nhật phối đồ' : 'Đã lưu phối đồ mới',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Lỗi khi lưu phối đồ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi lưu phối đồ'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showSelectOutfitDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('saved_outfits')
        .where('uid', isEqualTo: uid)
        .get();

    showDialog(
      context: context,
      barrierColor: Constants.darkBlueGrey.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: 500,
            decoration: BoxDecoration(
              color: Constants.pureWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Constants.darkBlueGrey.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Constants.secondaryGrey.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Constants.primaryBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Chọn Outfit đã lưu",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Constants.darkBlueGrey,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Constants.secondaryGrey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: snapshot.docs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.style_outlined,
                                size: 48,
                                color: Constants.secondaryGrey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Chưa có outfit nào được lưu',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Constants.secondaryGrey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: snapshot.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.docs[index];
                            final outfit = doc.data();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Constants.pureWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Constants.secondaryGrey.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Constants.darkBlueGrey.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Constants.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.style, color: Constants.primaryBlue),
                                ),
                                title: Text(
                                  outfit['prompt'] ?? 'Outfit ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Constants.darkBlueGrey,
                                  ),
                                ),
                                subtitle: Text(
                                  '${(outfit['itemIds'] as List?)?.length ?? 0} món đồ',
                                  style: TextStyle(color: Constants.secondaryGrey),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, color: Constants.secondaryGrey, size: 16),
                                onTap: () => _selectOutfit(outfit, doc.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({required Widget child, bool isSelected = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Constants.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Constants.primaryBlue : Constants.secondaryGrey.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? Constants.primaryBlue.withOpacity(0.2)
                : Constants.darkBlueGrey.withOpacity(0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.secondaryGrey.withOpacity(0.1),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // App Bar
              AppBar(
                backgroundColor: Constants.pureWhite,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Constants.darkBlueGrey),
                  onPressed: () => Navigator.pop(context),
                ),
                centerTitle: true,
                title: const Text(
                  'Chỉnh sửa phối đồ',
                  style: TextStyle(
                    color: Constants.darkBlueGrey,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.folder_open, color: Constants.primaryBlue),
                    onPressed: _showSelectOutfitDialog,
                  ),
                ],
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Outfit Name Input
                      _buildCard(
                        child: TextField(
                          controller: _promptController,
                          style: TextStyle(fontSize: 16, color: Constants.darkBlueGrey),
                          decoration: InputDecoration(
                            labelText: 'Tên phối đồ',
                            labelStyle: TextStyle(color: Constants.secondaryGrey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            prefixIcon: Icon(Icons.edit, color: Constants.darkBlueGrey),
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Search and Filter
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildCard(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm...',
                                  hintStyle: TextStyle(color: Constants.secondaryGrey.withOpacity(0.6)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  prefixIcon: Icon(Icons.search, color: Constants.darkBlueGrey),
                                  contentPadding: EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildCard(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2.2),
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                icon: Icon(Icons.tune, color: Constants.primaryBlue),
                                underline: const SizedBox(),
                                items: _categories
                                    .map((cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat, style: TextStyle(color: Constants.darkBlueGrey)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCategory = val);
                                    _applyFilters();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Selected Items Preview
                      if (_selectedItemIds.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Constants.primaryBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mục đã chọn (${_selectedItemIds.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Constants.darkBlueGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _selectedItemIds.map((id) {
                              final item = _allItems.firstWhereOrNull((e) => e.id == id);
                              final data = item?.data() as Map<String, dynamic>?;
                              final base64 = data?['base64Image'] ?? '';
                              
                              return Container(
                                width: 70,
                                margin: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () => _toggleItem(id),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Constants.primaryBlue, width: 2),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: base64.startsWith('data:image')
                                              ? Image.memory(
                                                  base64Decode(base64.split(',').last),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                )
                                              : Container(
                                                  color: Constants.secondaryGrey.withOpacity(0.1),
                                                  child: Icon(Icons.checkroom, color: Constants.secondaryGrey),
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Constants.darkBlueGrey,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.close, color: Constants.pureWhite, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Items Grid Header
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Constants.secondaryGrey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tủ đồ của bạn (${_filteredItems.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Constants.darkBlueGrey,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Items Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,

                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final doc = _filteredItems[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final base64 = data['base64Image'] ?? '';
                          final isSelected = _selectedItemIds.contains(doc.id);
                          
                          return GestureDetector(
                            onTap: () => _toggleItem(doc.id),
                            child: _buildCard(
                              isSelected: isSelected,
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.all(8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: base64.startsWith('data:image')
                                                ? Image.memory(
                                                    base64Decode(base64.split(',').last),
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    color: Constants.secondaryGrey.withOpacity(0.1),
                                                    child: Icon(
                                                      Icons.checkroom,
                                                      color: Constants.secondaryGrey,
                                                      size: 32,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Constants.primaryBlue,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(Icons.check, color: Constants.pureWhite, size: 16),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Save Button
      floatingActionButton: _selectedItemIds.isNotEmpty && _promptController.text.trim().isNotEmpty
          ? Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Constants.primaryBlue, Constants.primaryBlue.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Constants.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _saveOutfit,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _editingOutfitId != null ? Icons.update : Icons.save,
                          color: Constants.pureWhite,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _editingOutfitId != null ? 'Cập nhật' : 'Lưu phối đồ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Constants.pureWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
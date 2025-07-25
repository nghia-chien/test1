import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import 'uploadimage_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'clothing_detail_page.dart';
import '../constants/constants.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> with TickerProviderStateMixin {
  String _selectedCategory = 'Tất cả';
  int _selectedTabIndex = 0;
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _waveAnimation;

  static const Color pearl = Color(0xFFF8F8FF);
  static const Color primaryBlue = Color(0xFF209CFF);
  static const Color secondaryGrey = Color(0xFF7D7F85);
  static const Color darkgrey = Color(0xFF231f20);
  static const Color white = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color darkBlue = Color(0xFF006cff);
  static const Color black =Color(0xFF000000);

  final List<String> _categories = [
    'Tất cả', 'Áo', 'Quần', 'Đầm', 'Áo Khoác', 'Giày', 'Phụ Kiện'
  ];

  final List<String> tabs = ['Trang phục', 'Outfit'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fadeController.forward();
    _slideController.forward();
    _waveController.repeat();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _scaleController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _waveController = AnimationController(duration: const Duration(seconds: 3), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  List<ClothingItem> _filterByCategory(List<ClothingItem> items) {
    if (_selectedCategory == 'Tất cả') return items;
    return items.where((item) => item.category == _selectedCategory).toList();
  }

  String? _getFilterCategory() {
    return _selectedCategory == 'Tất cả' ? null : _selectedCategory;
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 42, // Giảm chiều cao để phù hợp với điện thoại
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(21), // Bo tròn bằng nửa chiều cao
        border: Border.all(color: secondaryGrey.withAlpha((255 * 0.2).round()), width: 1),
        boxShadow: [
          BoxShadow(
            color: darkgrey.withAlpha((255 * 0.08).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: isSelected 
                    ? LinearGradient(
                        colors: [primaryBlue, darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13, // Giảm size font để gọn gàng hơn
                      color: isSelected ? white : secondaryGrey,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildCategoryFilter() {
      return SizedBox(
        height: 50,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: FilterChip(
                label: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? pearl : darkBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = category),
                backgroundColor: pearl,
                selectedColor: primaryBlue,
                checkmarkColor: pearl,
                side: BorderSide(
                  color: isSelected ? primaryBlue : darkBlue.withOpacity(0.5),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: isSelected ? 6 : 2,
                shadowColor: primaryBlue.withOpacity(0.3),
              ),
            );
          },
        ),
      );
    }

  Widget _buildClothingGrid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [primaryBlue.withOpacity(0.3), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 64, color: primaryBlue),
              const SizedBox(height: 16),
              Text(
                'Vui lòng đăng nhập',
                style: TextStyle(fontSize: 18, color: darkBlue, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildCategoryFilter(),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clothing_items')
                .where('uid', isEqualTo: uid)
                .orderBy('uploaded_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primaryBlue, const Color.fromARGB(255, 255, 255, 255)]),
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          color: pearl, strokeWidth: 4,
                          backgroundColor: primaryBlue.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Đang tải dữ liệu...',
                        style: TextStyle(color: darkBlue, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [darkBlue.withOpacity(0.4), Colors.transparent],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.checkroom_outlined, size: 80, color: primaryBlue.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Tủ đồ trống',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: darkgrey.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Hãy thêm món đồ đầu tiên vào tủ đồ của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: darkBlue, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final clothingItems = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ClothingItem(
                  id: doc.id,
                  name: data['name'] ?? '',
                  category: data['category'] ?? '',
                  imageUrl: data['base64Image'] ?? '',
                  color: data['color'] ?? '',
                  matchingColors: [],
                  style: data['style'] ?? '',
                  season: data['season'] ?? '',
                  occasions: List<String>.from(data['occasions'] ?? []),
                );
              }).toList();

              final filteredItems = _filterByCategory(clothingItems);

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  return _ClothingItemCard(
                    item: filteredItems[index],
                    index: index,
                    filterCategory: _getFilterCategory(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      color: Colors.grey[50],
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildClothingGrid()
                    : _buildPostGrid('saved_outfits'),
              ),
            ],
          ),
        ),
      ),
    ),
      floatingActionButton: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            _scaleController.forward().then((_) => _scaleController.reverse());
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const UploadClothingPage())
            );
          },
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 12,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          icon: const Icon(Icons.add_rounded, size: 26),
          label: const Text(
            'Thêm Đồ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
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
          return Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryBlue, const Color.fromARGB(255, 255, 255, 255)]),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải dữ liệu: ${snapshot.error}',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [darkBlue.withOpacity(0.4), Colors.transparent],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.style_outlined, size: 60, color: primaryBlue),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chưa có outfit nào',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

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

            if (isWide) {
              return MasonryGridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return collectionName == 'saved_outfits'
                      ? _buildSavedOutfitCard(doc)
                      : _buildClothingGrid();
                },
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: collectionName == 'saved_outfits'
                        ? _buildSavedOutfitCard(doc)
                        : _buildClothingGrid(),
                  );
                },
              );
            }
          },
        );
      },
    );
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
            color: white,
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

}


class _ClothingItemCard extends StatefulWidget {
  final ClothingItem item;
  final int index;
  final String? filterCategory;

  const _ClothingItemCard({required this.item, required this.index, this.filterCategory});

  @override
  State<_ClothingItemCard> createState() => _ClothingItemCardState();
}

class _ClothingItemCardState extends State<_ClothingItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  static const Color primaryOcean = Color.fromARGB(255, 0, 0, 0);
  static const Color lightOcean = Color.fromARGB(255, 213, 4, 4);
  static const Color pearl = Color.fromARGB(255, 0, 0, 255);
  static const Color darkBlue = Color(0xFF006cff); 
  //static const Color skyBlue = Color.fromARGB(255, 225, 116, 14);
  static const Color primaryBlue = Color(0xFF209CFF);
  static const Color secondaryGrey = Color(0xFF7D7F85);

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut)
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _hoverAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isHovered = true);
              _hoverController.forward();
            },
            onTapUp: (_) {
              setState(() => _isHovered = false);
              _hoverController.reverse();
            },
            onTapCancel: () {
              setState(() => _isHovered = false);
              _hoverController.reverse();
            },
            onTap: () {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClothingDetailPage(
                    clothingItemId: widget.item.id,
                    uid: uid,
                    filterCategory: widget.filterCategory,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                
                // gradient: LinearGradient(
                //                     colors: [const Color.fromARGB(255, 255, 255, 255), const Color.fromARGB(255, 255, 255, 255)],
                //                   ),
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                // border: Border.all(
                //   color:  darkBlue,
                //   width: 2,
                // ),
                
                boxShadow: [
                  BoxShadow(
                    color: _isHovered 
                      ? primaryOcean.withOpacity(0.3) 
                      : Colors.grey.shade700.withOpacity(0.1),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: Offset(0, _isHovered ? 8 : 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),//ảnh
                        child: widget.item.imageUrl.isNotEmpty
                            ? Image.memory(
                                Uri.parse(widget.item.imageUrl).data!.contentAsBytes(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      
                                        color:  lightOcean.withOpacity(0.3),
                                      
                                    ),
                                    child: Icon(Icons.image_not_supported_outlined,
                                        size: 48, color: primaryOcean),
                                  );
                                },
                              )//ảnh ảo
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [darkBlue, const Color.fromARGB(255, 57, 219, 200).withOpacity(0.3)],
                                  ),
                                ),
                                child: Icon(Icons.checkroom_outlined,
                                    size: 48, color: primaryOcean),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      //padding: const EdgeInsets.all(16),
                      child: Column( //tên item
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color.fromARGB(255, 70, 70, 70),
                              //height: 1.2,
                            ),
                            //maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


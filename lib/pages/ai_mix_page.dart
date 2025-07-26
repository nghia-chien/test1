// ... imports như trước
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../utils/responsive_helper.dart';
import '../constants/constants.dart';
import 'outfit_detail_page.dart';

class AiMixPage extends StatefulWidget {
  const AiMixPage({super.key});
  @override
  State<AiMixPage> createState() => _AiMixPageState();
}

class _AiMixPageState extends State<AiMixPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  List<ClothingItem> _allItems = [];
  List<List<ClothingItem>> _suggestedOutfits = [];
  String? _seasonFilter;
  String? _occasionFilter;
  Set<String> _savedOutfitHashes = {};
  String _outfitHash(List<ClothingItem> items) => items.map((i) => i.id).toSet().join(',');
  bool _showFilters = false;


  final Color primaryBlue = Color(0xFF209CFF);
  final Color lightGrey = Constants.secondaryGrey.withValues(alpha: 0.2);
  final Color midGrey = Constants.secondaryGrey;

  // Color matching system
  final Map<String, List<String>> _colorGroups = {
    'neutral': ['white', 'black', 'gray', 'grey', 'beige', 'cream', 'trắng', 'đen', 'xám', 'be'],
    'warm': ['red', 'orange', 'yellow', 'pink', 'brown', 'đỏ', 'cam', 'vàng', 'hồng', 'nâu'],
    'cool': ['blue', 'green', 'purple', 'navy', 'teal', 'xanh', 'tím', 'xanh navy'],
    'earth': ['brown', 'tan', 'olive', 'khaki', 'camel', 'nâu', 'be', 'ô liu'],
  };

  @override
  void initState() {
    super.initState();
    _fetchClothingItems();
    _fetchSavedOutfitHashes(); // 👈 Thêm dòng này
  }


  Future<void> _fetchSavedOutfitHashes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('saved_outfits')
        .where('uid', isEqualTo: uid)
        .get();

    final hashes = snapshot.docs.map((doc) {
      final itemIds = List<String>.from(doc['itemIds'] ?? []);
      itemIds.sort(); // đảm bảo giống hash logic
      return itemIds.join(',');
    }).toSet();

    setState(() {
      _savedOutfitHashes = hashes;
    });
  }

  
  Future<void> _fetchClothingItems() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('clothing_items')
          .where('uid', isEqualTo: uid)
          .orderBy('uploaded_at', descending: true)
          .get();

      final items = snapshot.docs.map((doc) => ClothingItem.fromFirestore(doc.id, doc.data())).toList();

      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Lỗi khi tải dữ liệu. Vui lòng thử lại.');
    }
  }

  void _generateOutfits() async {
    if (_promptController.text.isEmpty) {
      _showErrorSnackBar('Vui lòng nhập mô tả outfit');
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestedOutfits.clear(); // 👈 XÓA dữ liệu cũ trước khi tạo outfit mới
    });
    
    try {
      final prompt = _promptController.text.toLowerCase();
      final keywords = prompt.split(' ');

      final filtered = _allItems.where((item) {
        return keywords.any((keyword) =>
                  item.name.toLowerCase().contains(keyword) ||
                  item.style.toLowerCase().contains(keyword) ||
                  item.color.toLowerCase().contains(keyword) ||
                  item.season.toLowerCase().contains(keyword) ||
                  item.category.toLowerCase().contains(keyword) ||
                  item.occasions.any((o) => o.toLowerCase().contains(keyword))) &&
               (_seasonFilter == null || _seasonFilter == 'Tất Cả' || item.season == _seasonFilter || item.season == 'Tất Cả') &&
               (_occasionFilter == null || _occasionFilter == '' || item.occasions.contains(_occasionFilter!));
      }).toList();

      if (filtered.isEmpty) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Không tìm thấy trang phục phù hợp');
        return;
      }

      final outfits = _createOutfitsFromItems(filtered);
      
      setState(() {
        _suggestedOutfits = outfits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Lỗi khi tạo outfit. Vui lòng thử lại.');
    }
  }

  // Random outfit generation with color matching
  void _generateRandomOutfits() async {
    if (_allItems.isEmpty) {
      _showErrorSnackBar('Không có trang phục nào để tạo outfit');
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestedOutfits.clear(); // 👈 XÓA dữ liệu cũ trước khi random
    });
    
    try {
      // Filter items based on season and occasion if selected
      final filtered = _allItems.where((item) {
        return (_seasonFilter == null || _seasonFilter == 'Tất Cả' || item.season == _seasonFilter) &&
               (_occasionFilter == null || _occasionFilter == '' || item.occasions.contains(_occasionFilter!));
      }).toList();

      if (filtered.isEmpty) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Không tìm thấy trang phục phù hợp với bộ lọc');
        return;
      }

      final randomOutfits = _createRandomColorMatchedOutfits(filtered);
      
      setState(() {
        _suggestedOutfits = randomOutfits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Lỗi khi tạo outfit ngẫu nhiên. Vui lòng thử lại.');
    }
  }

  // Create random outfits with color coordination
  List<List<ClothingItem>> _createRandomColorMatchedOutfits(List<ClothingItem> items) {
    final tops = items.where((i) => i.category == 'Áo').toList();
    final bottoms = items.where((i) => i.category == 'Quần' || i.category == 'Váy').toList();
    final shoes = items.where((i) => i.category == 'Giày').toList();
    final jackets = items.where((i) => i.category == 'Áo Khoác').toList();
    final accessories = items.where((i) => i.category == 'Phụ kiện').toList();

    if (tops.isEmpty || bottoms.isEmpty || shoes.isEmpty) {
      return []; // Not enough items to create outfits
    }

    final random = Random();
    final outfits = <List<ClothingItem>>[];
    final maxOutfits = 12; // Limit number of random outfits

    // Generate random outfits with color coordination
    for (int i = 0; i < maxOutfits && i < tops.length * 2; i++) {
      final top = tops[random.nextInt(tops.length)];
      final compatibleBottoms = _findColorCompatibleItems(top, bottoms);
      
      if (compatibleBottoms.isNotEmpty) {
        final bottom = compatibleBottoms[random.nextInt(compatibleBottoms.length)];
        final compatibleShoes = _findColorCompatibleItems(top, shoes);
        
        if (compatibleShoes.isNotEmpty) {
          final shoe = compatibleShoes[random.nextInt(compatibleShoes.length)];
          final outfit = [top, bottom, shoe];
          
          // Add optional items if available
          if (jackets.isNotEmpty && random.nextBool()) {
            final compatibleJackets = _findColorCompatibleItems(top, jackets);
            if (compatibleJackets.isNotEmpty) {
              outfit.add(compatibleJackets[random.nextInt(compatibleJackets.length)]);
            }
          }
          
          if (accessories.isNotEmpty && random.nextBool()) {
            outfit.add(accessories[random.nextInt(accessories.length)]);
          }
          
          // Check if this outfit combination already exists
          if (!_outfitExists(outfit, outfits)) {
            outfits.add(outfit);
          }
        }
      }
    }

    return outfits;
  }

  // Find items that are color compatible
  List<ClothingItem> _findColorCompatibleItems(ClothingItem baseItem, List<ClothingItem> items) {
    final baseColorGroup = _getColorGroup(baseItem.color.toLowerCase());
    
    return items.where((item) {
      final itemColorGroup = _getColorGroup(item.color.toLowerCase());
      
      // Neutral colors go with everything
      if (baseColorGroup == 'neutral' || itemColorGroup == 'neutral') {
        return true;
      }
      
      // Same color group
      if (baseColorGroup == itemColorGroup) {
        return true;
      }
      
      // Special combinations
      if ((baseColorGroup == 'warm' && itemColorGroup == 'earth') ||
          (baseColorGroup == 'earth' && itemColorGroup == 'warm')) {
        return true;
      }
      
      return false;
    }).toList();
  }

  // Get color group for a color
  String _getColorGroup(String color) {
    for (final entry in _colorGroups.entries) {
      if (entry.value.any((c) => color.contains(c))) {
        return entry.key;
      }
    }
    return 'neutral'; // Default to neutral if no match
  }

  // Check if outfit already exists
  bool _outfitExists(List<ClothingItem> newOutfit, List<List<ClothingItem>> existingOutfits) {
    for (final existing in existingOutfits) {
      if (existing.length == newOutfit.length &&
          existing.every((item) => newOutfit.any((newItem) => newItem.id == item.id))) {
        return true;
      }
    }
    return false;
  }

  // Create outfits from filtered items (original logic)
  List<List<ClothingItem>> _createOutfitsFromItems(List<ClothingItem> items) {
    final tops = items.where((i) => i.category == 'Áo').toList();
    final pants = items.where((i) => i.category == 'Quần').toList();
    final skirts = items.where((i) => i.category == 'Váy').toList();
    final shoes = items.where((i) => i.category == 'Giày').toList();
    final jackets = items.where((i) => i.category == 'Áo Khoác').toList();
    final accessories = items.where((i) => i.category == 'Phụ kiện').toList();

    List<List<ClothingItem>> generatedOutfits = [];

    for (var top in tops) {
      for (var bottom in pants) {
        for (var shoe in shoes) {
          if (_isMatching(top, bottom, shoe)) {
            final optional = _matchOptional([top, bottom, shoe], jackets, accessories);
            generatedOutfits.add([top, bottom, shoe, ...optional]);
          }
        }
      }
      for (var skirt in skirts) {
        for (var shoe in shoes) {
          if (_isMatching(top, skirt, shoe)) {
            final optional = _matchOptional([top, skirt, shoe], jackets, accessories);
            generatedOutfits.add([top, skirt, shoe, ...optional]);
          }
        }
      }
    }

    return generatedOutfits;
  }

  Future<void> _saveOutfit(List<ClothingItem> items) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final itemIds = items.map((i) => i.id).toList()..sort(); // sắp xếp để đảm bảo thứ tự
    final hash = itemIds.join(',');

    // Kiểm tra outfit đã lưu chưa
    final existing = await FirebaseFirestore.instance
        .collection('saved_outfits')
        .where('uid', isEqualTo: uid)
        .where('itemIds', isEqualTo: itemIds)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      _showSnackBar("Outfit đã được lưu trước đó", isError: false);
      setState(() {
        _savedOutfitHashes.add(hash); // đánh dấu
      });
      return;
    }

    // Nếu chưa tồn tại -> lưu mới
    await FirebaseFirestore.instance.collection('saved_outfits').add({
      'uid': uid,
      'prompt': _promptController.text.trim(),
      'seasonFilter': _seasonFilter,
      'occasionFilter': _occasionFilter,
      'itemIds': itemIds,
      'createdAt': Timestamp.now(),
    });

    setState(() {
      _savedOutfitHashes.add(hash);
    });

    _showSnackBar("Đã lưu outfit thành công!");
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }


  bool _isMatching(ClothingItem a, ClothingItem b, ClothingItem c) {
    return (a.style == b.style && b.style == c.style) ||
        (a.color == b.color || a.color == c.color || b.color == c.color);
  }

  List<ClothingItem> _matchOptional(List<ClothingItem> main, List<ClothingItem> jackets, List<ClothingItem> accessories) {
    List<ClothingItem> opt = [];
    if (jackets.isNotEmpty) {
      var match = jackets.firstWhere(
          (j) => main.any((i) => i.style == j.style || i.color == j.color),
          orElse: () => jackets.first);
      opt.add(match);
    }
    if (accessories.isNotEmpty) opt.add(accessories.first);
    return opt;
  }

  Uint8List decodeBase64Image(String dataUrl) {
    try {
      if (dataUrl.isEmpty) return Uint8List(0);
      return base64Decode(dataUrl.split(',').last);
    } catch (e) {
      print('Error decoding image: $e');
      return Uint8List(0);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final crossAxisCount = ResponsiveHelper.getCrossAxisCount(context);

  return Scaffold(
    backgroundColor: Constants.pureWhite,
    body: Column(
      children: [
        // Header section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          hintText: 'Mặc gì hôm nay',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _generateOutfits(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                    icon: const Icon(Icons.tune),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_showFilters)
                Row(
                  children: [
                    _buildDropdown(
                      label: 'Mùa',
                      value: _seasonFilter,
                      items: ['', 'Xuân', 'Hè', 'Thu', 'Đông'],
                      labelBuilder: (s) => s.isEmpty ? 'Tất cả' : s,
                      onChanged: (v) => setState(() => _seasonFilter = v),
                    ),
                    const SizedBox(width: 12),
                    _buildDropdown(
                      label: 'Dịp',
                      value: _occasionFilter,
                      items: ['', 'Đi làm', 'Tiệc', 'Du lịch', 'Hẹn hò'],
                      labelBuilder: (s) => s.isEmpty ? 'Tất cả' : s,
                      onChanged: (v) => setState(() => _occasionFilter = v),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      
                      onPressed: _isLoading ? null : _generateRandomOutfits,
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Random'),
                      
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _generateOutfits,
                      icon: const Icon(Icons.search),
                      label: const Text('Tìm kiếm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryBlue))
                : _suggestedOutfits.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có outfit nào\nHãy thử tìm kiếm hoặc tạo ngẫu nhiên',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _suggestedOutfits.length,
                        itemBuilder: (_, i) => _buildOutfitCard(_suggestedOutfits[i], i),
                      ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDropdown({
  required String label,
  required String? value,
  required List<String> items,
  required void Function(String?) onChanged,
  String Function(String)? labelBuilder,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        underline: Container(),
        value: value,
        hint: Text(label, style: const TextStyle(color: Colors.grey)),
        items: items.map((s) {
          return DropdownMenuItem<String>(
            value: s,
            child: Text(
              labelBuilder != null ? labelBuilder(s) : s,
              style: const TextStyle(color: Colors.black),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
 
  Widget _buildOutfitCard(List<ClothingItem> outfit, int index) {
    final isSaved = _savedOutfitHashes.contains(_outfitHash(outfit));

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OutfitDetailPage(
            items: outfit,
            prompt: _promptController.text,
            seasonFilter: _seasonFilter ?? '',
            occasionFilter: _occasionFilter ?? '',
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Constants.darkBlueGrey.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Outfit ${index + 1}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.save_alt_outlined : Icons.save_alt_outlined,
                      color: isSaved ? primaryBlue : midGrey,
                      size: 22,
                    ),
                    onPressed: () => _saveOutfit(outfit),
                  ),
                ],
              ),
            ),
            
            // Outfit Items Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: outfit.map((item) {
                    final image = decodeBase64Image(item.imageUrl);
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: image.isNotEmpty
                            ? Image.memory(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../utils/responsive_helper.dart';

class AiMixPage extends StatefulWidget {
  const AiMixPage({super.key});

  @override
  State<AiMixPage> createState() => _AiMixPageState();
}

class _AiMixPageState extends State<AiMixPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  List<ClothingItem> _allItems = [];
  List<ClothingItem> _suggestedItems = [];

  final List<String> _recentPrompts = [
    'Trang phục mùa hè năng động',
    'Đồ công sở lịch sự',
    'Trang phục hẹn hò',
    'Phong cách đường phố',
  ];

  @override
  void initState() {
    super.initState();
    _fetchClothingItems();
  }

  Future<void> _fetchClothingItems() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('clothing_items')
          .orderBy('uploaded_at', descending: true)
          .get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
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

      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      setState(() => _isLoading = false);
    }
  }

  void _generateSuggestions() {
    if (_promptController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final prompt = _promptController.text.toLowerCase();
    final keywords = prompt.split(' ');

    final filtered = _allItems.where((item) {
      return keywords.any((keyword) =>
          item.name.toLowerCase().contains(keyword) ||
          item.style.toLowerCase().contains(keyword) ||
          item.color.toLowerCase().contains(keyword) ||
          item.season.toLowerCase().contains(keyword) ||
          item.category.toLowerCase().contains(keyword) ||
          item.occasions.any((o) => o.toLowerCase().contains(keyword)));
    }).toList();

    setState(() {
      _suggestedItems = filtered;
      _isLoading = false;

      if (!_recentPrompts.contains(_promptController.text)) {
        _recentPrompts.insert(0, _promptController.text);
        if (_recentPrompts.length > 5) _recentPrompts.removeLast();
      }
    });
  }

  Uint8List decodeBase64Image(String dataUrl) {
    try {
      final cleaned = dataUrl.split(',').last;
      return base64Decode(cleaned);
    } catch (_) {
      return Uint8List(0); // Trả về dữ liệu rỗng nếu lỗi
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final crossAxisCount = ResponsiveHelper.getCrossAxisCount(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE7ECEF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: ResponsiveHelper.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Trợ lý Mix Đồ AI",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text("Gợi ý trang phục từ mô tả của bạn",
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  isTablet || isDesktop
                      ? Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _promptController,
                                decoration: InputDecoration(
                                  hintText: 'Ví dụ: "đồ mùa hè năng động"',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onSubmitted: (_) => _generateSuggestions(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _generateSuggestions,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: const Text("Tìm kiếm"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF3A8EDC), width: 2),
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _promptController,
                                      decoration: const InputDecoration(
                                        hintText: "Gợi ý phong cách?",
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (_) => _generateSuggestions(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                    color: const Color(0xFF3A8EDC),
                                    onPressed: _generateSuggestions,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentPrompts
                        .map((prompt) => ActionChip(
                              label: Text(prompt),
                              onPressed: () {
                                _promptController.text = prompt;
                                _generateSuggestions();
                              },
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _suggestedItems.isEmpty && _promptController.text.isNotEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Không tìm thấy trang phục phù hợp',
                                  style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        )
                      : _suggestedItems.isEmpty
                          ? const Center(
                              child: Text(
                                'Nhập yêu cầu để nhận gợi ý từ tủ đồ',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : GridView.builder(
                              padding: ResponsiveHelper.getScreenPadding(context),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.75,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                              itemCount: _suggestedItems.length,
                              itemBuilder: (context, index) {
                                final item = _suggestedItems[index];
                                final imageBytes = decodeBase64Image(item.imageUrl);

                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      // TODO: Chi tiết
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: Image.memory(
                                            imageBytes,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (_, __, ___) => const Center(
                                              child: Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 4,
                                                children: [
                                                  Chip(
                                                    label: Text(
                                                      item.style,
                                                      style: const TextStyle(fontSize: 10),
                                                    ),
                                                    visualDensity: VisualDensity.compact,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  Chip(
                                                    label: Text(
                                                      item.category,
                                                      style: const TextStyle(fontSize: 10),
                                                    ),
                                                    visualDensity: VisualDensity.compact,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

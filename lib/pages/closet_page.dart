import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import 'uploadimage_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Áo',
    'Quần',
    'Đầm',
    'Áo Khoác',
    'Giày',
    'Phụ Kiện'
  ];

  List<ClothingItem> _filterByCategory(List<ClothingItem> items) {
    if (_selectedCategory == 'All') return items;
    return items.where((item) => item.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE7ECEF),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [       
          const SizedBox(height: 16),
          // Category Filter
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: theme.colorScheme.primary.withAlpha(30),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.white,
                  elevation: 2,
                  pressElevation: 4,
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Real-time Firestore Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clothing_items')
                  .where('uid', isEqualTo: uid)
                  .orderBy('uploaded_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Không có món đồ nào.'));
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _ClothingItemCard(item: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadClothingPage()),
                );
              
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm đồ'),
      ),
    );
  }

}

class _ClothingItemCard extends StatelessWidget {
  final ClothingItem item;

  const _ClothingItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: Show detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.memory(
                  Uri.parse(item.imageUrl).data!.contentAsBytes(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.palette, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(item.color,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600])),
                      const Spacer(),
                      Text(item.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

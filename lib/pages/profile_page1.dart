import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import 'uploadimage_page.dart';

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

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserInfo() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getClothingItemsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    final collection = FirebaseFirestore.instance.collection('clothingItems');
    Query<Map<String, dynamic>> query = collection.where('uid', isEqualTo: uid);

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.orderBy('uploaded_at', descending: true).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE7ECEF),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _getUserInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              final data = snapshot.data!.data()!;
              final imageUrl = data['photoUrl'] ?? '';
              final name = data['name'] ?? 'Chưa có tên';
              final email = data['email'] ?? '';
              final bio = data['bio'] ?? '';

              return Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.pink.shade300,
                          Colors.orange.shade300,
                          Colors.pink.shade200,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 42,
                          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.person, size: 40, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        if (bio.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              bio,
                              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // Category filter
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
                    color: isSelected ? theme.colorScheme.primary : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.white,
                  elevation: 2,
                  pressElevation: 4,
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Real-time stream of clothing items
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getClothingItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có món đồ nào'));
                }

                final items = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final data = items[index].data();
                    final name = data['name'] ?? '';
                    final category = data['category'] ?? '';
                    final base64Image = data['base64Image'] ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: base64Image.isNotEmpty
                                ? Image.memory(
                                    Uri.parse(base64Image).data!.contentAsBytes(),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : const Icon(Icons.image, size: 80, color: Colors.grey),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(category, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
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

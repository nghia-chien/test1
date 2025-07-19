import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

class ProfilePage1 extends StatefulWidget {
  const ProfilePage1({super.key});

  @override
  State<ProfilePage1> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage1> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  String? _imageUrl;
  String? _backgroundUrl;

  int selectedTabIndex = 0;
  final List<String> tabs = ["bài viết", "trang phục"];
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                color: Constants.pureWhite,
                child: Column(
                  children: [
                    _buildTabBar(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              _buildContentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(tabs.length, (index) {
        final label = tabs[index];
        final isActive = selectedTabIndex == index;
        return GestureDetector(
          onTap: () => setState(() => selectedTabIndex = index),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isActive ? Constants.primaryBlue : Constants.darkBlueGrey.withOpacity(0.6),
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 2,
                  width: 24,
                  color: Constants.primaryBlue,
                )
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContentSection() {
    return selectedTabIndex == 0 ? _buildPostGrid('clothing_items') : _buildPostGrid('posts');
  }

  Widget _buildOutfitCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? '';
    final base64Image = data['base64Image'];
    final season = data['season'] ?? '';
    final category = data['category'] ?? '';

    Uint8List? imageBytes;
    if (base64Image != null) {
      final base64 = base64Image.split(',').last;
      imageBytes = base64Decode(base64);
    }
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageBytes != null)
            Image.memory(imageBytes, fit: BoxFit.cover, height: 180),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mùa: $season | Loại: $category'),

              ],
            ),
          ),
        ],
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
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Constants.secondaryGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải dữ liệu: ${snapshot.error}',
                    style: TextStyle(color: Constants.secondaryGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Constants.secondaryGrey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(color: Constants.secondaryGrey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        
        // Sort documents by timestamp if available
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

            return Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? MasonryGridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        return collectionName == 'clothing_items'
                            ? _buildOutfitCard(docs[index])
                            : _buildOutfitCard(docs[index]);
                      },
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: collectionName == 'clothing_items'
                              ? _buildOutfitCard(docs[index])
                              : _buildOutfitCard(docs[index]),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}

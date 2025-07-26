import 'package:cloud_firestore/cloud_firestore.dart';
import 'clothing_item.dart';

class Outfit {
  final String id;
  final String uid;
  final List<ClothingItem> items;
  final List<String> itemIds; // dùng để lưu & tải item từ Firestore
  final String prompt;
  final String seasonFilter;
  final String occasionFilter;
  final Timestamp createdAt;

  Outfit({
    required this.id,
    required this.uid,
    required this.items,
    required this.itemIds,
    required this.prompt,
    required this.seasonFilter,
    required this.occasionFilter,
    required this.createdAt,
  });

  /// ✅ Dùng khi tạo mới (items có sẵn)
  factory Outfit.newOutfit({
    required String uid,
    required List<ClothingItem> items,
    required String prompt,
    required String seasonFilter,
    required String occasionFilter,
  }) {
    return Outfit(
      id: '', // ID sẽ được tạo bởi Firestore
      uid: uid,
      items: items,
      itemIds: items.map((e) => e.id).toList(),
      prompt: prompt,
      seasonFilter: seasonFilter,
      occasionFilter: occasionFilter,
      createdAt: Timestamp.now(),
    );
  }

  /// ✅ Parse từ Firestore
  factory Outfit.fromFirestore(String id, Map<String, dynamic> data, List<ClothingItem> itemList) {
    return Outfit(
      id: id,
      uid: data['uid'] ?? '',
      prompt: data['prompt'] ?? '',
      seasonFilter: data['seasonFilter'] ?? '',
      occasionFilter: data['occasionFilter'] ?? '',
      itemIds: List<String>.from(data['itemIds'] ?? []),
      items: itemList,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  /// ✅ Dùng khi lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'prompt': prompt,
      'seasonFilter': seasonFilter,
      'occasionFilter': occasionFilter,
      'itemIds': itemIds,
      'createdAt': createdAt,
    };
  }
}

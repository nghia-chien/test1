import 'package:cloud_firestore/cloud_firestore.dart';

class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl;        // sẽ đọc từ base64Image
  final String color;
  final List<String> matchingColors; // optional, có thể để []
  final String style;
  final String season;
  final List<String> occasions;
        // optional nếu không có trong Firestore

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.color,
    required this.matchingColors,
    required this.style,
    required this.season,
    required this.occasions,

  });

  factory ClothingItem.fromFirestore(String id, Map<String, dynamic> data) {
  return ClothingItem(
    id: id,
    name: data['name'] ?? '',
    category: data['category'] ?? '',
    imageUrl: data['base64Image'] ?? '',
    color: data['color'] ?? '',
    matchingColors: [], // hoặc parse nếu bạn lưu trong Firestore
    style: data['style'] ?? '',
    season: data['season'] ?? '',
    occasions: List<String>.from(data['occasions'] ?? []),

  );
}
}

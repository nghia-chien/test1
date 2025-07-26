import 'package:cloud_firestore/cloud_firestore.dart';

class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl; // chứa base64Image
  final String color;
  final List<String> matchingColors;
  final String style;
  final String season;
  final List<String> occasions;

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

  /// ✅ Parse từ Firestore snapshot
  factory ClothingItem.fromFirestore(String id, Map<String, dynamic> data) {
    return ClothingItem(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['base64Image'] ?? '',
      color: data['color'] ?? '',
      matchingColors: List<String>.from(data['matchingColors'] ?? []),
      style: data['style'] ?? '',
      season: data['season'] ?? '',
      occasions: List<String>.from(data['occasions'] ?? []),
    );
  }

  /// ✅ Chuyển sang Map để upload lên Firestore nếu cần
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'base64Image': imageUrl,
      'color': color,
      'matchingColors': matchingColors,
      'style': style,
      'season': season,
      'occasions': occasions,
    };
  }
}

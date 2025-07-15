import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';

class OutfitDetailPage extends StatelessWidget {
  final List<ClothingItem> items;
  final String prompt, seasonFilter, occasionFilter;

  const OutfitDetailPage({
    required this.items,
    required this.prompt,
    required this.seasonFilter,
    required this.occasionFilter,
    super.key,
  });

  Uint8List decodeBase64Image(String base64Image) {
    try {
      final cleaned = base64Image.split(',').last;
      return base64Decode(cleaned);
    } catch (_) {
      return Uint8List(0); // fallback rỗng
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết Outfit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧠 Gợi ý: $prompt', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (seasonFilter.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('☁️ Mùa: $seasonFilter'),
              ),
            if (occasionFilter.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('📅 Dịp: $occasionFilter'),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: items.map((item) {
                  final imageBytes = decodeBase64Image(item.imageUrl);
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Column(
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
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.category,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
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
      return Uint8List(0);
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(title: const Text('Chi tiết Outfit')),
    body: Padding(
      
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "💡 Gợi ý: ${prompt.isNotEmpty ? prompt : 'Random'}",
            
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
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
            
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final imageBytes = decodeBase64Image(item.imageUrl);
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, color: Constants.secondaryGrey),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.category,
                              style: const TextStyle(fontSize: 12, color: Constants.secondaryGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
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

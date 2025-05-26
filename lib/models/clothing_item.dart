class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final String color;
  final List<String> matchingColors; // Colors that match well with this item
  final String style; // casual, formal, sporty, etc.
  final String season;
  final List<String> occasions;
  final double price;
  final String brand;

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
    required this.price,
    required this.brand,
  });
}

class Outfit {
  final String id;
  final String name;
  final List<ClothingItem> items;
  final String season;
  final String occasion;
  final double score;
  final Map<String, double> scores; // Detailed scores for different aspects

  Outfit({
    required this.id,
    required this.name,
    required this.items,
    required this.season,
    required this.occasion,
    this.score = 0.0,
    required this.scores,
  });
}

// Sample clothing items
final List<ClothingItem> sampleClothingItems = [
  // Tops
  ClothingItem(
    id: 't1',
    name: 'White Cotton T-Shirt',
    category: 'Tops',
    imageUrl: 'https://picsum.photos/200/300?random=1',
    color: 'White',
    matchingColors: ['Black', 'Navy', 'Beige', 'Gray', 'Denim'],
    style: 'Casual',
    season: 'All',
    occasions: ['Casual', 'Sport'],
    price: 29.99,
    brand: 'BasicWear',
  ),
  ClothingItem(
    id: 't2',
    name: 'Black Silk Blouse',
    category: 'Tops',
    imageUrl: 'https://picsum.photos/200/300?random=2',
    color: 'Black',
    matchingColors: ['White', 'Red', 'Beige', 'Gray'],
    style: 'Formal',
    season: 'All',
    occasions: ['Formal', 'Business'],
    price: 89.99,
    brand: 'LuxeStyle',
  ),
  ClothingItem(
    id: 't3',
    name: 'Striped Button-Up Shirt',
    category: 'Tops',
    imageUrl: 'https://picsum.photos/200/300?random=3',
    color: 'Blue',
    matchingColors: ['White', 'Navy', 'Beige', 'Gray'],
    style: 'Smart-Casual',
    season: 'All',
    occasions: ['Business', 'Smart-Casual'],
    price: 59.99,
    brand: 'ModernBasics',
  ),

  // Bottoms
  ClothingItem(
    id: 'b1',
    name: 'Classic Blue Jeans',
    category: 'Bottoms',
    imageUrl: 'https://picsum.photos/200/300?random=4',
    color: 'Denim',
    matchingColors: ['White', 'Black', 'Gray', 'Red', 'Navy'],
    style: 'Casual',
    season: 'All',
    occasions: ['Casual', 'Smart-Casual'],
    price: 79.99,
    brand: 'DenimCo',
  ),
  ClothingItem(
    id: 'b2',
    name: 'Black Tailored Trousers',
    category: 'Bottoms',
    imageUrl: 'https://picsum.photos/200/300?random=5',
    color: 'Black',
    matchingColors: ['White', 'Gray', 'Navy', 'Red'],
    style: 'Formal',
    season: 'All',
    occasions: ['Formal', 'Business'],
    price: 99.99,
    brand: 'LuxeStyle',
  ),
  ClothingItem(
    id: 'b3',
    name: 'Beige Chinos',
    category: 'Bottoms',
    imageUrl: 'https://picsum.photos/200/300?random=6',
    color: 'Beige',
    matchingColors: ['White', 'Black', 'Navy', 'Brown'],
    style: 'Smart-Casual',
    season: 'Spring,Summer',
    occasions: ['Smart-Casual', 'Business'],
    price: 69.99,
    brand: 'ModernBasics',
  ),

  // Outerwear
  ClothingItem(
    id: 'o1',
    name: 'Black Leather Jacket',
    category: 'Outerwear',
    imageUrl: 'https://picsum.photos/200/300?random=7',
    color: 'Black',
    matchingColors: ['White', 'Gray', 'Denim'],
    style: 'Edgy',
    season: 'Fall,Winter',
    occasions: ['Casual', 'Party'],
    price: 199.99,
    brand: 'UrbanEdge',
  ),
  ClothingItem(
    id: 'o2',
    name: 'Navy Blazer',
    category: 'Outerwear',
    imageUrl: 'https://picsum.photos/200/300?random=8',
    color: 'Navy',
    matchingColors: ['White', 'Gray', 'Beige', 'Light Blue'],
    style: 'Smart-Casual',
    season: 'All',
    occasions: ['Business', 'Smart-Casual', 'Formal'],
    price: 149.99,
    brand: 'ClassicCut',
  ),
  ClothingItem(
    id: 'o3',
    name: 'Beige Trench Coat',
    category: 'Outerwear',
    imageUrl: 'https://picsum.photos/200/300?random=9',
    color: 'Beige',
    matchingColors: ['Black', 'Navy', 'White', 'Gray'],
    style: 'Classic',
    season: 'Fall,Spring',
    occasions: ['Smart-Casual', 'Business'],
    price: 179.99,
    brand: 'LuxeStyle',
  ),

  // Shoes
  ClothingItem(
    id: 's1',
    name: 'White Sneakers',
    category: 'Shoes',
    imageUrl: 'https://picsum.photos/200/300?random=10',
    color: 'White',
    matchingColors: ['Black', 'Denim', 'Gray', 'Navy'],
    style: 'Casual',
    season: 'All',
    occasions: ['Casual', 'Sport', 'Smart-Casual'],
    price: 89.99,
    brand: 'UrbanKicks',
  ),
  ClothingItem(
    id: 's2',
    name: 'Black Oxford Shoes',
    category: 'Shoes',
    imageUrl: 'https://picsum.photos/200/300?random=11',
    color: 'Black',
    matchingColors: ['Gray', 'Navy', 'Black'],
    style: 'Formal',
    season: 'All',
    occasions: ['Formal', 'Business'],
    price: 159.99,
    brand: 'ClassicCut',
  ),
  ClothingItem(
    id: 's3',
    name: 'Brown Leather Boots',
    category: 'Shoes',
    imageUrl: 'https://picsum.photos/200/300?random=12',
    color: 'Brown',
    matchingColors: ['Beige', 'Denim', 'Black'],
    style: 'Smart-Casual',
    season: 'Fall,Winter',
    occasions: ['Casual', 'Smart-Casual'],
    price: 129.99,
    brand: 'UrbanEdge',
  ),

  // Accessories
  ClothingItem(
    id: 'a1',
    name: 'Black Leather Belt',
    category: 'Accessories',
    imageUrl: 'https://picsum.photos/200/300?random=13',
    color: 'Black',
    matchingColors: ['Black', 'Gray', 'Navy'],
    style: 'Formal',
    season: 'All',
    occasions: ['Formal', 'Business', 'Smart-Casual'],
    price: 49.99,
    brand: 'LuxeStyle',
  ),
  ClothingItem(
    id: 'a2',
    name: 'Silver Watch',
    category: 'Accessories',
    imageUrl: 'https://picsum.photos/200/300?random=14',
    color: 'Silver',
    matchingColors: ['Black', 'Navy', 'Gray', 'White'],
    style: 'Classic',
    season: 'All',
    occasions: ['Formal', 'Business', 'Smart-Casual', 'Casual'],
    price: 199.99,
    brand: 'TimePiece',
  ),
  ClothingItem(
    id: 'a3',
    name: 'Navy Silk Tie',
    category: 'Accessories',
    imageUrl: 'https://picsum.photos/200/300?random=15',
    color: 'Navy',
    matchingColors: ['White', 'Light Blue', 'Gray'],
    style: 'Formal',
    season: 'All',
    occasions: ['Formal', 'Business'],
    price: 39.99,
    brand: 'ClassicCut',
  ),
];

// Sample outfits
final List<Outfit> sampleOutfits = [
  Outfit(
    id: '1',
    name: 'Business Professional',
    items: [sampleClothingItems[1], sampleClothingItems[4], sampleClothingItems[10]],
    season: 'Fall',
    occasion: 'Business',
    score: 95.0,
    scores: {
      'color': 90.0,
      'occasion': 100.0,
      'season': 100.0,
      'style': 95.0,
    },
  ),
  Outfit(
    id: '2',
    name: 'Casual Weekend',
    items: [sampleClothingItems[0], sampleClothingItems[3], sampleClothingItems[9]],
    season: 'All',
    occasion: 'Casual',
    score: 92.0,
    scores: {
      'color': 85.0,
      'occasion': 100.0,
      'season': 100.0,
      'style': 90.0,
    },
  ),
]; 
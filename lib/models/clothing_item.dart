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
  // Áo
  ClothingItem(
    id: 't1',
    name: 'Áo Thun Cotton Trắng',
    category: 'Áo',
    imageUrl: 'lib/images/item/aothun_trang.jpg',
    color: 'Trắng',
    matchingColors: ['Đen', 'Xanh Navy', 'Be', 'Xám', 'Jeans'],
    style: 'Năng Động',
    season: 'Tất Cả',
    occasions: ['Thường Ngày', 'Thể Thao'],
    price: 299000,
    brand: 'BasicWear',
  ),
  ClothingItem(
    id: 't2',
    name: 'Áo Sơ Mi Lụa Đen',
    category: 'Áo',
    imageUrl: 'lib/images/item/aosomi_den.jpg',
    color: 'Đen',
    matchingColors: ['Trắng', 'Đỏ', 'Be', 'Xám'],
    style: 'Công Sở',
    season: 'Tất Cả',
    occasions: ['Công Sở', 'Lịch Sự'],
    price: 899000,
    brand: 'LuxeStyle',
  ),
  ClothingItem(
    id: 't3',
    name: 'Áo Sơ Mi Sọc',
    category: 'Áo',
    imageUrl: 'lib/images/item/aosomi_soc.jpg',
    color: 'Xanh',
    matchingColors: ['Trắng', 'Xanh Navy', 'Be', 'Xám'],
    style: 'Smart-Casual',
    season: 'Tất Cả',
    occasions: ['Công Sở', 'Hẹn Hò'],
    price: 599000,
    brand: 'ModernBasics',
  ),

  // Quần
  ClothingItem(
    id: 'b1',
    name: 'Quần Jeans Xanh Cổ Điển',
    category: 'Quần',
    imageUrl: 'lib/images/item/quan_jeans_xanh.jpg',
    color: 'Jeans',
    matchingColors: ['Trắng', 'Đen', 'Xám', 'Đỏ', 'Xanh Navy'],
    style: 'Năng Động',
    season: 'Tất Cả',
    occasions: ['Thường Ngày', 'Dạo Phố'],
    price: 799000,
    brand: 'DenimCo',
  ),
  ClothingItem(
    id: 'b2',
    name: 'Quần Âu Đen',
    category: 'Quần',
    imageUrl: 'lib/images/item/quan_au_den.jpg',
    color: 'Đen',
    matchingColors: ['Trắng', 'Xám', 'Xanh Navy', 'Đỏ'],
    style: 'Công Sở',
    season: 'Tất Cả',
    occasions: ['Công Sở', 'Lịch Sự'],
    price: 999000,
    brand: 'LuxeStyle',
  ),
  ClothingItem(
    id: 'b3',
    name: 'Quần Kaki Be',
    category: 'Quần',
    imageUrl: 'lib/images/item/quan_kaki_be.jpg',
    color: 'Be',
    matchingColors: ['Trắng', 'Đen', 'Xanh Navy', 'Nâu'],
    style: 'Smart-Casual',
    season: 'Xuân,Hè',
    occasions: ['Dạo Phố', 'Công Sở'],
    price: 699000,
    brand: 'ModernBasics',
  ),

  // Áo Khoác
  ClothingItem(
    id: 'o1',
    name: 'Áo Khoác Da Đen',
    category: 'Áo Khoác',
    imageUrl: 'lib/images/item/aokhoac_den.jpg',
    color: 'Đen',
    matchingColors: ['Trắng', 'Xám', 'Jeans'],
    style: 'Cá Tính',
    season: 'Thu,Đông',
    occasions: ['Dạo Phố', 'Tiệc'],
    price: 1999000,
    brand: 'UrbanEdge',
  ),
  ClothingItem(
    id: 'o2',
    name: 'Áo Blazer Xanh Navy',
    category: 'Áo Khoác',
    imageUrl: 'lib/images/item/aokhoac_xanh.jpg',
    color: 'Xanh Navy',
    matchingColors: ['Trắng', 'Xám', 'Be', 'Xanh Nhạt'],
    style: 'Smart-Casual',
    season: 'Tất Cả',
    occasions: ['Công Sở', 'Lịch Sự', 'Tiệc'],
    price: 1499000,
    brand: 'ClassicCut',
  ),
  ClothingItem(
    id: 'o3',
    name: 'Áo Măng Tô Be',
    category: 'Áo Khoác',
    imageUrl: 'lib/images/item/aokhoac_mangtoc.jpg',
    color: 'Be',
    matchingColors: ['Đen', 'Xanh Navy', 'Trắng', 'Xám'],
    style: 'Cổ Điển',
    season: 'Thu,Xuân',
    occasions: ['Dạo Phố', 'Công Sở'],
    price: 1799000,
    brand: 'LuxeStyle',
  ),

  // Giày
  ClothingItem(
    id: 's1',
    name: 'Giày Sneaker Trắng',
    category: 'Giày',
    imageUrl: 'lib/images/item/giay_sneaker_trang.jpg',
    color: 'Trắng',
    matchingColors: ['Đen', 'Jeans', 'Xám', 'Xanh Navy'],
    style: 'Năng Động',
    season: 'Tất Cả',
    occasions: ['Thường Ngày', 'Thể Thao', 'Dạo Phố'],
    price: 899000,
    brand: 'UrbanKicks',
  ),
  ClothingItem(
    id: 's2',
    name: 'Giày Tây Đen',
    category: 'Giày',
    imageUrl: 'lib/images/item/giay_tay_den.jpg',
    color: 'Đen',
    matchingColors: ['Xám', 'Xanh Navy', 'Đen'],
    style: 'Công Sở',
    season: 'Tất Cả',
    occasions: ['Công Sở', 'Lịch Sự'],
    price: 1599000,
    brand: 'ClassicCut',
  ),
  ClothingItem(
    id: 's3',
    name: 'Giày Boot Da Nâu',
    category: 'Giày',
    imageUrl: 'lib/images/item/giay_boot_nau.jpg',
    color: 'Nâu',
    matchingColors: ['Be', 'Jeans', 'Đen'],
    style: 'Smart-Casual',
    season: 'Thu,Đông',
    occasions: ['Dạo Phố', 'Hẹn Hò'],
    price: 1299000,
    brand: 'UrbanEdge',
  ),

  // Phụ Kiện
  ClothingItem(
    id: 'a1',
    name: 'Thắt Lưng Da Đen',
    category: 'Phụ Kiện',
    imageUrl: 'lib/images/item/thatlung_den.jpg',
    color: 'Đen',
    matchingColors: ['Đen', 'Xám', 'Xanh Navy'],
    style: 'Công Sở',
    season: 'Tất Cả',
    occasions: ['Công Sở', 'Lịch Sự', 'Smart-Casual'],
    price: 499000,
    brand: 'LuxeStyle',
  ),
  ClothingItem(
    id: 'a2',
    name: 'Đồng Hồ Bạc',
    category: 'Phụ Kiện',
    imageUrl: 'lib/images/item/dongho_bac.jpg',
    color: 'Bạc',
    matchingColors: ['Đen', 'Xanh Navy', 'Xám', 'Trắng'],
    style: 'Cổ Điển',
    season: 'Tất Cả',
    occasions: ['Công Sở', 'Lịch Sự', 'Smart-Casual', 'Thường Ngày'],
    price: 1999000,
    brand: 'TimePiece',
  ),
  ClothingItem(
    id: 'a3',
    name: 'Cà Vạt Lụa Xanh Navy',
    category: 'Phụ Kiện',
    imageUrl: 'lib/images/item/cavat_xanh.jpg',
    color: 'Xanh Navy',
    matchingColors: ['Trắng', 'Xanh Nhạt', 'Xám'],
    style: 'Công Sở',
    season: 'Tất Cả',
    occasions: ['Công Sở', 'Lịch Sự'],
    price: 399000,
    brand: 'ClassicCut',
  ),
];

// Sample outfits
final List<Outfit> sampleOutfits = [
  Outfit(
    id: '1',
    name: 'Trang Phục Công Sở',
    items: [sampleClothingItems[1], sampleClothingItems[4], sampleClothingItems[10]],
    season: 'Thu',
    occasion: 'Công Sở',
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
    name: 'Trang Phục Cuối Tuần',
    items: [sampleClothingItems[0], sampleClothingItems[3], sampleClothingItems[9]],
    season: 'Tất Cả',
    occasion: 'Thường Ngày',
    score: 92.0,
    scores: {
      'color': 85.0,
      'occasion': 100.0,
      'season': 100.0,
      'style': 90.0,
    },
  ),
]; 
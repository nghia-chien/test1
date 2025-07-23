import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import 'chat_screen.dart';
import 'notification.dart';
import 'uploadimage_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'calendar_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../utils/responsive_helper.dart';
import '../constants/constants.dart';
import 'history_page.dart';
import 'CreateOutfitPage.dart';
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? weatherDescription;
  double? temperature;
  String? weatherIconCode;
  String? cityName;
  String? countryCode;
  String? _userName;
  final TextEditingController _searchController = TextEditingController();

  // Recent Outfits demo images (bạn có thể thay bằng ảnh thật hoặc link mạng)
  final List<String> outfitImagePaths = [
    'images/logo.png',
    'images/logo_dt.png',
    'images/banner.png',
    // Thêm các ảnh khác nếu có
  ];

  List<AnimatedText> _generateAnimatedTexts() {
    final name = _userName ?? 'bạn';
    List<String> messages = [
      'Chào bạn quay trở lại, $name ',
      'Bạn muốn tư vấn điều gì?',
      'Hãy nhập điều bạn muốn!',
    ];
    if (weatherDescription != null && temperature != null) {
      if (temperature! >= 28) {
        messages.insert(1, 'Hôm nay trời nóng, bạn có muốn mặc bộ đồ mát mẻ?');
      } else if (temperature! <= 20) {
        messages.insert(1, 'Có vẻ trời đang lạnh, bạn có muốn chọn bộ đồ ấm áp?');
      }
    }
    return messages
        .map((msg) => TypewriterAnimatedText(msg, speed: const Duration(milliseconds: 60)))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    fetchWeatherData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userName = doc.data()?['name'] ?? 'Guest';
      });
    } else {
      setState(() {
        _userName = 'Guest';
      });
    }
  }

  Future<void> fetchWeatherData() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final weather = await WeatherService.fetchWeather(position.latitude, position.longitude);
        setState(() {
          weatherDescription = weather['weather'][0]['description'];
          temperature = weather['main']['temp'];
          weatherIconCode = weather['weather'][0]['icon'];
          cityName = weather['name'];
          countryCode = weather['sys']?['country'];
        });
      }
    } catch (e) {
      debugPrint('Lỗi lấy thời tiết: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.white,
              ],
              stops: [0.0, 0.5],
            ),
          ),
          child: Center(
            child: Container(
              padding: ResponsiveHelper.getScreenPadding(context),
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getMaxWidth(context),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner
                    Padding(
                      padding: const EdgeInsets.only(top: 0, left: 2, right: 2, bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'images/banner.png',
                          fit: BoxFit.cover,
                          width: double.maxFinite,
                          height: 140,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    buildActionGrid(context),
                    const SizedBox(height: 20),
                    _buildAIStylishPrompt(),
                    const SizedBox(height: 12),
                    _buildSearchBox(),
                    const SizedBox(height: 20),
                    _buildRecentOutfitsTitle(),
                    const SizedBox(height: 12),
                    _buildRecentOutfits(),
                    const SizedBox(height: 25),
                    buildWeatherCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildActionGrid(BuildContext context) {
    final actions = [
      {
        'icon': Icons.upload_file,
        'label': 'Thêm đồ',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadClothingPage()),
          );
        }
      },
      {
        'icon': Icons.style_outlined, 
        'label': 'Tạo outfit', 
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditOutfitPage()),
          );
      }
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Kế hoạch',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarPage()),
          );
        }
      },
      {
        'icon': Icons.history,
        'label': 'Lịch sử',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryPage()),
          );
        }
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((item) {
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: item['onTap'] as VoidCallback,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Constants.pureWhite,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Constants.darkBlueGrey.withOpacity(0.1), blurRadius: 4)],
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 26,
                    color: Constants.primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAIStylishPrompt() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      color: const Color(0xFFFAFAFA),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFFAFAFA),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF5F5F5),
                child: const Icon(Icons.smart_toy, color: Constants.primaryBlue, size: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      child: AnimatedTextKit(
                        animatedTexts: _generateAnimatedTexts(),
                        repeatForever: true,
                        pause: const Duration(milliseconds: 1200),
                        isRepeatingAnimation: true,
                        displayFullTextOnTap: true,
                        stopPauseOnTap: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "AI Stylist",
                      style: TextStyle(
                        fontFamily: 'BeautiqueDisplay',
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: const Color(0xFFF2F2F2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Gợi ý phong cách?",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Color(0xFF7D7F85)),
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              onPressed: () {
                final input = _searchController.text.trim();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      weatherDescription: weatherDescription,
                      temperature: temperature,
                      initialQuery: input.isNotEmpty ? input : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOutfitsTitle() {
    return const Text("Recent Outfits", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 18));
  }

  Widget _buildRecentOutfits() {
    double height = ResponsiveHelper.isMobile(context) ? 140 : 140;
    double width = height * 0.7;
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: outfitImagePaths.map((url) => _recentOutfitImg(url, width, height)).toList(),
      ),
    );
  }

  Widget _recentOutfitImg(String url, double width, double height) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
        ),
      ),
    );
  }

  Widget buildWeatherCard() {
    if (weatherDescription == null || temperature == null || weatherIconCode == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Constants.primaryBlue,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 3)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Text('🌤️', style: TextStyle(fontSize: 28, color: Colors.white)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Đang tải thời tiết...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final iconUrl = 'https://openweathermap.org/img/wn/$weatherIconCode@4x.png';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Constants.primaryBlue,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(iconUrl, width: 80, height: 80, fit: BoxFit.cover),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${temperature!.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weatherDescription!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$cityName, $countryCode',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

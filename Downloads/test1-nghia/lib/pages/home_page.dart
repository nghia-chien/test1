import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import 'chat_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'calendar_page.dart';
import 'dart:async'; // Added for Timer
import 'notification_page.dart'; // Added for NotificationPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  // Dữ liệu thời tiết
  String? weatherDescription;
  double? temperature;
  String? weatherIconCode;
  String? cityName;
  String? countryCode;

  // Controller cho ô tìm kiếm
  final TextEditingController _searchController = TextEditingController();

  // ScrollController cho Recent Outfits
  final ScrollController _recentOutfitsController = ScrollController();

  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _recentOutfitsController.dispose();
    _timer.cancel();
    super.dispose();
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
      backgroundColor: Colors.transparent,
      body: Container(
        // Gradient nền dịu mắt
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F7FA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thêm nút chuông thông báo
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.blue, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationPage()),
                        );
                      },
                    ),
                  ],
                ),
                // Đồng hồ thời gian thực
                Center(
                  child: Text(
                    '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 10),
                // Hàng nút chức năng chính
                _buildActionRow(),
                const SizedBox(height: 28),
                // Khu vực AI Stylish với hiệu ứng gõ chữ
                _buildAIStylishPrompt(),
                const SizedBox(height: 28),
                // Ô tìm kiếm
                _buildSearchBox(context),
                const SizedBox(height: 32),
                // Tiêu đề Recent Outfits
                _buildRecentOutfitsTitle(),
                const SizedBox(height: 14),
                // Danh sách ảnh Recent Outfits
                _buildRecentOutfits(),
                const SizedBox(height: 32),
                // Thẻ thời tiết
                buildWeatherCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hàng nút chức năng chính (Upload, Create, ...)
  Widget _buildActionRow() {
    final actions = [
      {'icon': Icons.upload_file, 'label': 'Upload'},
      {'icon': Icons.checkroom, 'label': 'Create'},
      {'icon': Icons.calendar_today, 'label': 'Plan'},
      {'icon': Icons.bar_chart, 'label': 'Review'},
      {'icon': Icons.history, 'label': 'History'},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              if (action['icon'] == Icons.calendar_today) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarPage()),
                );
              } else {
                // Các nút khác giữ nguyên (hoặc thêm logic sau)
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Column(
                children: [
                  Icon(action['icon'] as IconData, color: const Color(0xFF5B67CA), size: 28),
                  const SizedBox(height: 6),
                  Text(action['label'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Khu vực AI Stylish với hiệu ứng gõ chữ
  Widget _buildAIStylishPrompt() {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(isDarkMode: false, initialMessage: null),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF5B67CA).withOpacity(0.12),
                child: const Icon(Icons.smart_toy, color: Color(0xFF5B67CA), size: 32),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText('Hỏi gì cũng được!'),
                        TypewriterAnimatedText('Tôi có thể tư vấn phong cách!'),
                        TypewriterAnimatedText('Bạn thích sắc màu hay đơn giản?'),
                      ],
                      repeatForever: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("AI Stylish", style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Color(0xFF0D47A1))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ô tìm kiếm phong cách
  Widget _buildSearchBox(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Gợi ý phong cách?",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _navigateToChatWithQuery(text);
                  }
                },
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF5B67CA),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () {
                  if (_searchController.text.trim().isNotEmpty) {
                    _navigateToChatWithQuery(_searchController.text);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm chuyển sang trang chat với câu hỏi từ ô tìm kiếm
  void _navigateToChatWithQuery(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          isDarkMode: false,
          initialMessage: query,
        ),
      ),
    );
    // Xóa nội dung ô tìm kiếm sau khi chuyển trang
    _searchController.clear();
  }

  // Tiêu đề Recent Outfits
  Widget _buildRecentOutfitsTitle() {
    return const Text(
      "Recent Outfits",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
        fontSize: 19,
      ),
    );
  }

  // Danh sách ảnh Recent Outfits (ảnh to hơn, bo góc đẹp, có xử lý lỗi)
  Widget _buildRecentOutfits() {
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              _recentOutfitsController.animateTo(
                _recentOutfitsController.offset - 220,
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              controller: _recentOutfitsController,
              child: ListView(
                controller: _recentOutfitsController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _recentOutfitImg('lib/images/home/outfit1.jpg'),
                  _recentOutfitImg('lib/images/home/outfit2.jpg'),
                  _recentOutfitImg('lib/images/home/outfit3.jpg'),
                  _recentOutfitImg('lib/images/home/outfit4.jpg'),
                  _recentOutfitImg('lib/images/home/outfit5.jpg'),
                  _recentOutfitImg('lib/images/home/outfit6.jpg'),
                  _recentOutfitImg('lib/images/home/outfit7.jpg'),
                  _recentOutfitImg('lib/images/home/outfit8.jpg'),
                  _recentOutfitImg('lib/images/home/outfit9.jpg'),
                  _recentOutfitImg('lib/images/home/outfit10.jpg'),
                  // ... thêm các link ảnh khác
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              _recentOutfitsController.animateTo(
                _recentOutfitsController.offset + 220,
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _recentOutfitImg(String url) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 200,
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url, fit: BoxFit.cover),
      ),
    );
  }

  // Thẻ thời tiết (hiển thị thông tin thời tiết, có thể nâng cấp hiệu ứng Lottie)
  Widget buildWeatherCard() {
    if (weatherDescription == null || temperature == null || weatherIconCode == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final iconUrl = 'https://openweathermap.org/img/wn/$weatherIconCode@4x.png';
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.lightBlue.shade50,
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.network(iconUrl, width: 80, height: 80),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${temperature!.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text(weatherDescription!.toUpperCase(), style: const TextStyle(fontSize: 16)),
              Text('$cityName, $countryCode', style: const TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
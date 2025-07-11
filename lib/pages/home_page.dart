import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import 'chat_screen.dart';
import 'notification.dart';
import 'profile_page.dart';
import 'uploadimage_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'calendar_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

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

  final List<String> outfitImagePaths = [
    'lib/images/feed/autumn_essentials.jpg',
    'lib/images/feed/summer_vibe.jpg',
    'lib/images/feed/timeless_elegance.jpg',
    'lib/images/feed/urban_street.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    fetchWeatherData();
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

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const NotificationPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECF0F1),
        elevation: 0,
        title: Text("Hi, ${_userName ?? 'Loading...'} 👋"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              _buildActionRow(),
              const SizedBox(height: 20),
              _buildAIStylishPrompt(),
              const SizedBox(height: 30),
              _buildSearchBox(),
              const SizedBox(height: 30),
              _buildRecentOutfitsTitle(),
              const SizedBox(height: 12),
              _buildRecentOutfits(),
              const SizedBox(height: 32),
              buildWeatherCard(),
            ],
          ),
        ),
      ),
    );
  }

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
                
              }
              if(action['icon'] == Icons.upload_file) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadClothingPage()),
                );
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
              builder: (context) => const ChatScreen(),
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
                        TypewriterAnimatedText('Chào bạn đến với WHY'),
                        TypewriterAnimatedText('Bạn muốn tư vấn điều gì?'),
                        TypewriterAnimatedText('Hãy nhập điều bạn muốn!'),
                      ],
                      repeatForever: true,
                      pause: const Duration(milliseconds: 1200),
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

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF3A8EDC), width: 2),
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF3A8EDC),
            ),
            child: IconButton(
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
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => ChatScreen(initialQuery: input),
                  //   ),
                  // );
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
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: outfitImagePaths.map((url) => _recentOutfitImg(url)).toList(),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Icon(icon, color: const Color(0xFF2C3E50), size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E50))),
      ],
    );
  }

  Widget _recentOutfitImg(String url) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 80,
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))],
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          children: [
            Text('🌤️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(child: Text("Đang tải thời tiết...", style: TextStyle(fontSize: 18))),
          ],
        ),
      );
    }

    final iconUrl = 'https://openweathermap.org/img/wn/$weatherIconCode@4x.png';
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(30),
        color: Colors.blue.shade50,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.network(iconUrl, width: 80, height: 80, fit: BoxFit.cover),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${temperature!.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Text(weatherDescription!.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              Text('$cityName, $countryCode', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}

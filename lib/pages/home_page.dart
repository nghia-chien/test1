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
import 'history_page.dart';
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

//build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      
      body: SafeArea(
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
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    final actions = [
      {'icon': Icons.upload_file, 'label': 'Upload'},
      {'icon': Icons.checkroom, 'label': 'Create'},
      {'icon': Icons.calendar_today, 'label': 'Plan'},
      {'icon': Icons.history, 'label': 'History'},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.asMap().entries.map((entry) {
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
              } else if (action['icon'] == Icons.history) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Column(
                children: [
                  Icon(action['icon'] as IconData, color: const Color.fromARGB(255, 228, 8, 8), size: 28),
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
                backgroundColor: const Color(0xFF5B67CA).withAlpha((0.12 * 255).round()),
                child: const Icon(Icons.smart_toy, color: Color(0xFF5B67CA), size: 32),
              ),
              const SizedBox(width: 18),
              // Text section - wrapped and constrained
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
                      "AI Stylish",
                      style: TextStyle(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF0D47A1),
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Text('Vui lòng đăng nhập');
    }

    double height = ResponsiveHelper.isMobile(context) ? 70 : 100;
    int imageCount = ResponsiveHelper.isMobile(context) ? 6 : 10;

    return SizedBox(
      height: height,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clothing_items')
            .where('uid', isEqualTo: uid)
            .orderBy('uploaded_at', descending: true)
            .limit(imageCount)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bạn chưa thêm món đồ nào'));
          }

          final items = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['base64Image'] ?? data['imageUrl'] ?? '';
          }).where((url) => url.isNotEmpty).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _recentOutfitImg(items[index], height);
            },
          );
        },
      ),
    );
  }


  Widget _recentOutfitImg(String url, double size) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Builder(
          builder: (context) {
            if (url.startsWith('data:image')) {
              try {
                final uriData = Uri.parse(url).data;
                if (uriData == null) return const Icon(Icons.broken_image);
                final bytes = uriData.contentAsBytes();
                return Image.memory(bytes, fit: BoxFit.cover);
              } catch (e) {
                return const Icon(Icons.broken_image);
              }
            } else {
              return Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
              );
            }
          },
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

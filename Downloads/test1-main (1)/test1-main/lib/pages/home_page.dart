import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _userName;
  String? weatherDescription;
  double? temperature;
  String? weatherIconCode;
  String? cityName;
  String? countryCode;

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
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'Guest';
        });
      } else {
        setState(() {
          _userName = 'Guest';
        });
      }
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
      backgroundColor: const Color(0xFFE7ECEF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Greeting on the left
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Hi, ${_userName ?? 'Loading...'} 👋",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    // Icons on the right
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, size: 28),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_outline, size: 28),
                          onPressed: () {},
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _actionButton(Icons.file_upload, "Upload"),
                    _actionButton(Icons.checkroom, "Create"),
                    _actionButton(Icons.calendar_today, "Plan"),
                    _actionButton(Icons.bar_chart, "Review"),
                    _actionButton(Icons.history, "History"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFA3C7E6),
                      radius: 20,
                      child: Image.network(
                        'https://storage.googleapis.com/a1aa/image/e1813bb2-c35b-444d-183b-06a6e0a3d4b6.jpg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7941D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("Hỏi gì cũng được!", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 64.0, top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("AI Stylish", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF3A8EDC), width: 2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Gợi ý phong cách?',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        color: const Color(0xFF3A8EDC),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          onPressed: () {},
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Recent Outfits", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _recentOutfitImg('https://storage.googleapis.com/a1aa/image/99891187-057f-40f6-48e3-726c266b71c7.jpg'),
                    _recentOutfitImg('https://storage.googleapis.com/a1aa/image/a7e61f45-ca02-4b50-d3ac-b305024747e3.jpg'),
                    _recentOutfitImg('https://storage.googleapis.com/a1aa/image/2b1cb033-039d-46b9-66a2-da15b53a35a4.jpg'),
                    _recentOutfitImg('https://storage.googleapis.com/a1aa/image/bd7e2998-776c-40ce-04d1-916082f07f7e.jpg'),
                    _recentOutfitImg('https://storage.googleapis.com/a1aa/image/9dc0b7b2-83af-4b1d-4690-6970febc8c92.jpg'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: buildWeatherCard(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF3A8EDC),
        unselectedItemColor: const Color(0xFF7F8C8D),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'AI Stylist'),
          BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Welcome'),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Icon(icon, color: const Color(0xFF2C3E50), size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E50)))
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
        child: Image.network(url, fit: BoxFit.cover),
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
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2)),
          ],
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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2)),
        ],
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
              Text(
                '${temperature!.toStringAsFixed(1)}°C',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(
                weatherDescription!.toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              if (cityName != null && countryCode != null)
                Text(
                  '$cityName, $countryCode',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black54),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

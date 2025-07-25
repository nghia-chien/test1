import 'package:cursor/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/testing.dart';
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
import 'profile_page2.dart';

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

  static const Color primaryBlue = Color(0xFF209CFF);
  static const Color secondaryGrey = Color(0xFF7D7F85);
  static const Color darkgrey = Color(0xFF231f20);
  static const Color white = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color darkBlue = Color(0xFF006cff);
  static const Color black =Color(0xFF000000);

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

void _showNotifications() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Notifications",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink(); // Nội dung thực sự nằm trong transitionBuilder
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeInOut.transform(animation.value);
        return Transform.translate(
          offset: Offset(0, -300 + (300 * curvedValue)), // Trượt từ trên xuống
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              color: Colors.white,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 400, // Tùy chỉnh chiều cao panel
                child: const NotificationPanel(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final isWideScreen = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isTablet(context);
        return Scaffold(
        appBar: isWideScreen
        ? null
        :  AppBar(
            backgroundColor: primaryBlue,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 80,
            titleSpacing: 8, // Đổi số này để chỉnh khoảng cách lề trái
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Image.asset(
                        'images/logo2.png',
                        width: 120,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 0), // chỉnh lề trái dòng slogan
                      child: const Text(
                        "With Honor. be You",
                        style: TextStyle(
                          fontSize: 11, // chỉnh font size nhỏ
                          color: Colors.white,
                          fontFamily: 'BeautiqueDisplay',
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(top: 12.0), // Đưa icon xuống dưới
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                        onPressed: _showNotifications,
                      ),
                      IconButton(
                        icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(key: PageStorageKey('profile')),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                Color(0xFF209CFF),
                Colors.white,
              ],
              stops: [0.0, 0.7],
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
                    const Text(
                      "AI Stylist",
                      style: TextStyle(fontFamily: 'BeautiqueDisplay',fontWeight: FontWeight.bold,fontStyle: FontStyle.italic, color: darkgrey, fontSize: 18)
                    ),
                    
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

    return Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.white.withAlpha((255 * 0.9).round()),
    // border: Border.all(
    //   color: const Color.fromARGB(255, 134, 134, 134).withAlpha((255 * 0.5).round()), // hoặc bất kỳ màu nào bạn muốn
    //   width: 1.5,
    // ),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
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
                  // decoration: BoxDecoration(
                  //   color: Constants.pureWhite,
                  //   shape: BoxShape.circle,
                  //   boxShadow: [BoxShadow(color: Constants.darkBlueGrey.withOpacity(0.1), blurRadius: 4)],
                  // ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 26,
                    color: primaryBlue,
                  ),
                ),
                //const SizedBox(height: 6),
                Text(
                  item['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: black,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color:  white,//.withAlpha((255 * 0.5).round()),
        border: Border.all(
          color: Colors.grey, // hoặc bất kỳ màu nào bạn muốn
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Animated hintText khi ô search rỗng
                if (_searchController.text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7D7F85),
                      ),
                      maxLines: 1,
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
                  ),

                // TextField hiển thị lên trên
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}), // Cập nhật để ẩn hintText khi gõ
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Color(0xFF7D7F85)),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: primaryBlue,
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
    return const Text("Recent Outfits",style: TextStyle(fontFamily: 'BeautiqueDisplay',fontWeight: FontWeight.bold,fontStyle: FontStyle.italic, color: darkgrey, fontSize: 18));
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
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
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
              return CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: primaryBlue,
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
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 151, 197, 233),
            AppColors.primaryBlue,
          ],
          stops: [0.1, 0.8],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 3),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${temperature!.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Image.network(
                iconUrl,
                width: 60,
                height: 50,
                fit: BoxFit.cover,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            weatherDescription!.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '$cityName, $countryCode',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
}
}
import 'package:cursor/main.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/weather_service.dart';
import 'dart:convert';

// Updated color scheme
class AppColors {
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color primaryBlue = Color(0xFF209CFF);
  static const Color secondaryGrey = Color(0xFF7D7F85);
  static const Color darkgrey = Color(0xFF231f20);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color darkBlue = Color(0xFF006cff);
  static const Color black =Color(0xFF000000);
}

class ClothingItem {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  
  ClothingItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
  });
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isMonthlyView = true;
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _calendarData = {};

  @override
  void initState() {
    super.initState();
    loadCalendarDataFromFirestore();
  }

  Future<void> loadCalendarDataFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('calendar_outfits')
        .where('uid', isEqualTo: uid)
        .get();

    final Map<String, Map<String, dynamic>> data = {};
    for (final doc in snapshot.docs) {
      final calendar = doc.data();
      final dateKey = calendar['date'];
      data[dateKey] = calendar;
    }

    setState(() {
      _calendarData = data;
      _isLoading = false;
    });
  }

  Future<void> _showSelectOutfitDialog(String dateKey) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('saved_outfits')
        .where('uid', isEqualTo: uid)
        .get();

    showDialog(
      
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            // Sử dụng MediaQuery để đảm bảo dialog không vượt quá màn hình
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: const Text(
                        "Select Outfit",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: snapshot.docs.isEmpty
                      ? const Center(
                          child: Text(
                            'No outfits saved yet',
                            style: TextStyle(color: AppColors.darkgrey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.docs.length,
                          itemBuilder: (context, index) {
                            final outfit = snapshot.docs[index].data();
                            outfit['id'] = snapshot.docs[index].id;
                            return _buildOutfitCard(outfit, index);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutfitImages(String outfitId) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('saved_outfits').doc(outfitId).get(),
      builder: (context, outfitSnapshot) {
        if (outfitSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (!outfitSnapshot.hasData || outfitSnapshot.data?.data() == null) {
          return const Center(
              child:
                  Text("Outfit not found", style: TextStyle(color: Colors.white)));
        }

        final outfitData = outfitSnapshot.data!.data() as Map<String, dynamic>;
        final itemIds = List<String>.from(outfitData['itemIds'] ?? []);

        if (itemIds.isEmpty) {
          return const Center(
              child: Text("Outfit has no items",
                  style: TextStyle(color: Colors.white)));
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('clothing_items')
              .where(FieldPath.documentId, whereIn: itemIds)
              .get(),
          builder: (context, itemsSnapshot) {
            if (itemsSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }
            if (!itemsSnapshot.hasData) {
              return const Center(
                  child: Text("Could not load items",
                      style: TextStyle(color: Colors.white)));
            }

            final clothingItems = itemsSnapshot.data!.docs;
            if (clothingItems.isEmpty) {
              return const Center(
                  child: Text("No items found for this outfit.",
                      style: TextStyle(color: Colors.white)));
            }

            return SizedBox(
              height: 60, // Giảm chiều cao để tránh overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: clothingItems.length,
                itemBuilder: (context, index) {
                  final item = clothingItems[index].data() as Map<String, dynamic>;
                  final base64 = item['base64Image'] ?? '';
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 50, // Giảm kích thước
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.lightGray,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: base64.isNotEmpty && base64.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(base64.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error, size: 20),
                            )
                          : const Icon(Icons.image_not_supported,
                              color: AppColors.darkgrey, size: 20),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

Widget _buildOutfitDisplay() {
  final DateTime selectedDay = _selectedDay ?? DateTime.now();

  final dateKey = DateFormat('yyyy-MM-dd').format(selectedDay);
  final calendarEntry = _calendarData[dateKey];
  final outfitId = calendarEntry?['outfitId'];

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 0),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.09), // Responsive padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(255, 108, 160, 232),
            const Color.fromARGB(255, 176, 236, 253),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.15 * 255).round()),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Ngày tháng năm
          Text(
            'Ngày : ${DateFormat('dd/MM/yyyy').format(selectedDay)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.035,
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 20),
          // Outfit images
          SizedBox(
            height: 70,
            child: outfitId == null
                ? Center(
                    child: Text(
                      'Chưa có trang phục cho ngày này',
                      style: TextStyle(
                        color: Colors.white.withAlpha((0.8 * 255).round()),
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _buildOutfitImages(outfitId),
          ),
          const SizedBox(height: 22),
          // Buttons
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showSelectOutfitDialog(dateKey),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.015,
                        ),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        child: Text(
                          "Đổi đồ",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final docRef = FirebaseFirestore.instance
                            .collection('calendar_outfits')
                            .doc(dateKey);
                        await docRef.delete();
                        await loadCalendarDataFromFirestore();
                        setState(() {
                          _selectedDay = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE74C3C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.015,
                        ),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        child: Text(
                          "Xóa",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}


  Widget _buildOutfitCard(Map<String, dynamic> outfit, int index) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('clothing_items')
          .where(FieldPath.documentId, whereIn: List<String>.from(outfit['itemIds'] ?? []))
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final clothingItems = snapshot.data?.docs ?? [];

        return InkWell(
          onTap: () async {
            final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
            final uid = FirebaseAuth.instance.currentUser?.uid;

            final docRef = FirebaseFirestore.instance.collection('calendar_outfits').doc(dateKey);

            await docRef.set({
              'outfitId': outfit['id'],
              'uid': uid,
              'date': dateKey,
            });
            
            Navigator.pop(context);
            await loadCalendarDataFromFirestore();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkgrey.withAlpha((0.2 * 255).round())),

            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          outfit['prompt'] ?? "Outfit ${index + 1}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        
                      ),
                    ],
                  ),
                ),
                if (clothingItems.isNotEmpty)
                  SizedBox(
                    height: 70, // Giảm chiều cao
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: clothingItems.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, i) {
                        final item = clothingItems[i].data() as Map<String, dynamic>;
                        final base64 = item['base64Image'] ?? '';
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 50, // Giảm kích thước
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.lightGray,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: base64.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(base64.split(',').last),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_not_supported, size: 20),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDayCells() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = (firstDayOfMonth.weekday % 7);
    List<Widget> cells = [];

    for (int i = 0; i < firstWeekday; i++) {
      cells.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final key = DateFormat('yyyy-MM-dd').format(date);
      final data = _calendarData[key];
      final isToday = date.day == DateTime.now().day &&
          date.month == DateTime.now().month &&
          date.year == DateTime.now().year;

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.black
                  : _selectedDay == date
                      ? AppColors.primaryBlue.withAlpha((0.1 * 255).round())
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: _selectedDay == date
                    ? AppColors.primaryBlue
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontWeight:  FontWeight.bold,
                      color: isToday ? Colors.white : AppColors.black,
                      fontSize: 14, // Giảm font size
                      fontFamily: 'Montserrat'
                    ),
                  ),
                ),
                if (data?['outfitId'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 4, // Giảm kích thước
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    while (cells.length < 42) {
      cells.add(Container());
    }

    return cells;
  }

Widget _buildHorizontalWeekView() {
  final today = DateTime.now();
  final screenWidth = MediaQuery.of(context).size.width;

  return Column(
    children: [ Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, Color(0xFFCACACA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 255, 255, 255)),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Thời tiết tuần này',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: Color.fromARGB(255, 255, 255, 255)),
                  onPressed: () => setState(() {
                    _isMonthlyView = !_isMonthlyView;
                    _selectedDay = null;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          // Weather section (white alpha background)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: WeeklyPlanner(lat: 21.0285, lon: 105.8542),
          ),
        const SizedBox(height: 20),
        ])), const SizedBox(height: 20),
          // Daily calendar section with horizontal scroll
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.05 * 255).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Hàng ngày',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Horizontal Scrollable Day List
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date = today.add(Duration(days: index));
                      final key = DateFormat('yyyy-MM-dd').format(date);
                      final data = _calendarData[key];
                      final isSelected = _selectedDay != null &&
                          _selectedDay!.day == date.day &&
                          _selectedDay!.month == date.month &&
                          _selectedDay!.year == date.year;

                      final weekdays = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
                      final dayName = weekdays[date.weekday - 1];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDay = date;
                          });
                        },
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryBlue : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.028,
                                  color: isSelected ? Colors.white : AppColors.darkgrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (data?['outfitId'] != null)
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : kPrimaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.checkroom,
                                    size: 10,
                                    color: isSelected ? kPrimaryBlue : Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ]
      );
        
    
  
}

 @override
  Widget build(BuildContext context) {
    final daysOfWeek = [ 'CN','Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7'];
    
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            )
          : Column(
              children: [
                if (_isMonthlyView) Padding(
                  padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Thời tiết tuần này',
                          style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month, color: Color.fromARGB(255, 0, 0, 0)),
                        onPressed: () => setState(() {
                          _isMonthlyView = !_isMonthlyView;
                          _selectedDay = null;
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_isMonthlyView) ...[
                          Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    kPrimaryBlue,
                                    
                                    const Color.fromARGB(255, 148, 185, 237),
                                    const Color.fromARGB(255, 180, 214, 231),
                                    const Color.fromARGB(255, 148, 185, 237),
                                    const Color.fromARGB(255, 220, 227, 234),
                                  ],
                                  //stops: [0.1,0.3,0.2,0.1,0.3]
                                ),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 77, 142, 195), // Màu viền
                                  width: 2, // Độ dày viền
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha((0.05 * 255).round()),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                ]),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left,
                                            color: AppColors.black),
                                        onPressed: () => setState(() {
                                          _focusedDay = DateTime(
                                              _focusedDay.year,
                                              _focusedDay.month - 1,
                                              1);
                                          _selectedDay = null;
                                        }),
                                      ),
                                      Flexible(
                                        child: Text(
                                          DateFormat('MMMM yyyy')
                                              .format(_focusedDay),
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.width * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right,
                                            color: AppColors.black),
                                        onPressed: () => setState(() {
                                          _focusedDay = DateTime(
                                              _focusedDay.year,
                                              _focusedDay.month + 1,
                                              1);
                                          _selectedDay = null;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: daysOfWeek
                                        .map((d) => Expanded(
                                              child: Center(
                                                child: Text(
                                                  d,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color.fromARGB(255, 0, 0, 0),
                                                    fontSize: MediaQuery.of(context).size.width * 0.03,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                // Sử dụng AspectRatio để đảm bảo tỷ lệ phù hợp
                                AspectRatio(
                                  aspectRatio: 7/6, // 7 columns, 6 rows
                                  child: GridView.count(
                                    crossAxisCount: 7,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(8),
                                    children: _buildDayCells(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          _buildHorizontalWeekView(),
                        ],
                      ],
                    ),
                  ),
                ),
                // Đặt _buildOutfitDisplay bên ngoài Expanded và SingleChildScrollView
                _buildOutfitDisplay(),
              ],
            ),
    );
  }
}
class WeeklyPlanner extends StatefulWidget {
  final double lat;
  final double lon;
  const WeeklyPlanner({required this.lat, required this.lon, super.key});

  @override
  State<WeeklyPlanner> createState() => _WeeklyPlannerState();
}

class _WeeklyPlannerState extends State<WeeklyPlanner> {
  List<Map<String, dynamic>>? forecast;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  void loadWeather() async {
    try {
      final data = await WeatherService.fetchWeeklyForecast(widget.lat, widget.lon);
      setState(() {
        forecast = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    if (_error != null || forecast == null || forecast!.isEmpty) {
      return const Center(
        child: Text(
          'Weather unavailable',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return buildWeeklyWeatherCard(forecast!);
  }
Widget buildWeeklyWeatherCard(List<Map<String, dynamic>> dailyForecasts) {
  final days = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(7, (index) {
      // Nếu index vượt quá độ dài danh sách → bỏ qua
      if (index >= dailyForecasts.length) {
        return const SizedBox(width: 40); // placeholder rỗng
      }

      final forecast = dailyForecasts[index];

      // Kiểm tra dữ liệu hợp lệ
      if (forecast['main'] == null ||
          forecast['main']['temp'] == null ||
          forecast['weather'] == null ||
          forecast['weather'].isEmpty ||
          forecast['weather'][0]['icon'] == null) {
        return const SizedBox(width: 40); // placeholder rỗng
      }

      final temp = (forecast['main']['temp'] as num).round();
      final weatherIcon = forecast['weather'][0]['icon'];

      return SizedBox(
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              days[index],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Image.network(
              'https://openweathermap.org/img/wn/$weatherIcon.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.cloud,
                size: 32,
                color: Color.fromARGB(255, 255, 0, 0),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$temp°',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }),
  );
}

}
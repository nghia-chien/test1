import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/weather_service.dart';
import 'dart:convert';


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
          backgroundColor: Constants.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select Outfit",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.darkBlueGrey,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Constants.darkBlueGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: snapshot.docs.isEmpty
                      ? const Center(
                          child: Text(
                            'No outfits saved yet',
                            style: TextStyle(color: Constants.secondaryGrey),
                          ),
                        )
                      : ListView.builder(
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

  Future<List<Map<String, dynamic>>> fetchOutfitItems(String outfitId) async {
    final outfitSnapshot = await FirebaseFirestore.instance
        .collection('saved_outfits')
        .doc(outfitId)
        .get();

    final data = outfitSnapshot.data();
    if (data == null || data['itemIds'] == null) return [];

    final List<dynamic> itemIds = data['itemIds'];
    final List<Map<String, dynamic>> items = [];

    for (final itemId in itemIds) {
      final itemSnapshot = await FirebaseFirestore.instance
          .collection('clothing_items')
          .doc(itemId)
          .get();
      if (itemSnapshot.exists) {
        final itemData = itemSnapshot.data();
        if (itemData != null) items.add(itemData);
      }
    }

    return items;
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

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            height: 68, // tăng chiều cao cell hơn nữa
            decoration: BoxDecoration(
              color: _selectedDay == date ? Constants.primaryBlue.withOpacity(0.1) : Constants.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDay == date ? Constants.primaryBlue : Constants.secondaryGrey.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedDay == date ? Constants.primaryBlue : Constants.darkBlueGrey,
                  ),
                ),
                if (data?['outfitId'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Constants.primaryBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.checkroom,
                      size: 12,
                      color: Constants.pureWhite,
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

            await FirebaseFirestore.instance
                .collection('calendar_outfits')
                .doc(dateKey)
                .set({
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
              color: Constants.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Constants.secondaryGrey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Constants.darkBlueGrey.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          outfit['prompt'] ?? "Outfit ${index + 1}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Constants.darkBlueGrey,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Constants.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Select',
                          style: TextStyle(
                            color: Constants.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: clothingItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, i) {
                      final item = clothingItems[i].data() as Map<String, dynamic>;
                      final base64 = item['base64Image'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Constants.secondaryGrey.withOpacity(0.1),
                          border: Border.all(color: Constants.secondaryGrey.withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: base64.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(base64.split(',').last),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontal7Days() {
    final today = DateTime.now();
    return Column(
      children: [
        // Weather forecast
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weather Forecast',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.darkBlueGrey,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: WeeklyPlanner(lat: 21.0285, lon: 105.8542),
              ),
            ],
          ),
        ),
        // Daily calendar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Calendar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.darkBlueGrey,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final date = today.add(Duration(days: index));
                    final key = DateFormat('yyyy-MM-dd').format(date);
                    final data = _calendarData[key];
                    final isSelected = _selectedDay != null &&
                        date.year == _selectedDay!.year &&
                        date.month == _selectedDay!.month &&
                        date.day == _selectedDay!.day;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = date),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Constants.primaryBlue.withOpacity(0.1) : Constants.pureWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Constants.primaryBlue : Constants.secondaryGrey.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat.E('vi').format(date),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Constants.primaryBlue : Constants.darkBlueGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? Constants.primaryBlue : Constants.darkBlueGrey,
                              ),
                            ),
                            if (data?['outfitId'] != null)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Constants.primaryBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.checkroom,
                                  color: Constants.pureWhite,
                                  size: 12,
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    
    return Scaffold(
      backgroundColor: Constants.pureWhite,
      appBar: AppBar(
        backgroundColor: Constants.pureWhite,
        elevation: 0,
        title: const Text(
          'Fashion Calendar',
          style: TextStyle(
            color: Constants.darkBlueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () => setState(() {
                _isMonthlyView = !_isMonthlyView;
                _selectedDay = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryBlue,
                foregroundColor: Constants.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isMonthlyView ? Icons.view_week : Icons.calendar_month,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isMonthlyView ? 'Week' : 'Month',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Constants.primaryBlue),
              ),
            )
          : Column(
              children: [
                if (_isMonthlyView) ...[
                  Container(
                    color: Constants.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Constants.darkBlueGrey),
                          onPressed: () => setState(() {
                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                            _selectedDay = null;
                          }),
                        ),
                        Text(
                          DateFormat('MMMM yyyy', 'vi').format(_focusedDay),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Constants.darkBlueGrey,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Constants.darkBlueGrey),
                          onPressed: () => setState(() {
                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                            _selectedDay = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Constants.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: daysOfWeek
                          .map((d) => Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Constants.darkBlueGrey,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Constants.pureWhite,
                      child: GridView.count(
                        crossAxisCount: 7,
                        padding: const EdgeInsets.all(8),
                        children: _buildDayCells(),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(child: _buildHorizontal7Days()),
                ],
                if (_selectedDay != null)
                  Container(
                    width: double.infinity,
                    color: Constants.pureWhite,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected: ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Constants.darkBlueGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('calendar_outfits')
                              .doc(DateFormat('yyyy-MM-dd').format(_selectedDay!))
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Constants.primaryBlue),
                              );
                            }
                            
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            if (data == null) {
                              return ElevatedButton(
                                onPressed: () => _showSelectOutfitDialog(
                                  DateFormat('yyyy-MM-dd').format(_selectedDay!),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.primaryBlue,
                                  foregroundColor: Constants.pureWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text("Add Outfit"),
                              );
                            }
                            final outfitId = data['outfitId'] as String?;
                            if (outfitId == null) return const SizedBox();

                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future: fetchOutfitItems(outfitId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final items = snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Outfit Items:",
                                      style: TextStyle(
                                        color: Constants.secondaryGrey.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                          final item = items[index];
                                          final base64Image = item['base64Image'] ?? '';

                                          return Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            width: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: Constants.secondaryGrey.withOpacity(0.1),
                                              border: Border.all(color: Constants.secondaryGrey.withOpacity(0.3)),
                                            ),
                                            child: base64Image.startsWith('data:image')
                                                ? Image.memory(
                                                    base64Decode(base64Image.split(',').last),
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Icon(Icons.image_not_supported),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _showSelectOutfitDialog(
                                            DateFormat('yyyy-MM-dd').format(_selectedDay!),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Constants.primaryBlue,
                                            foregroundColor: Constants.pureWhite,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text("Change"),
                                        ),
                                        const SizedBox(width: 12),
                                        OutlinedButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('calendar_outfits')
                                                .doc(DateFormat('yyyy-MM-dd').format(_selectedDay!))
                                                .delete();
                                            await loadCalendarDataFromFirestore();
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text("Remove"),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
// Weather forecast widget
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
          valueColor: AlwaysStoppedAnimation<Color>(Constants.primaryBlue),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Weather unavailable',
          style: TextStyle(color: Constants.secondaryGrey.withOpacity(0.6)),
        ),
      );
    }
    if (forecast == null || forecast!.isEmpty) {
      return Center(
        child: Text(
          'No weather data',
          style: TextStyle(color: Constants.secondaryGrey.withOpacity(0.6)),
        ),
      );
    }
    return buildWeeklyWeatherCard(forecast!);
  }

  Widget buildWeeklyWeatherCard(List<Map<String, dynamic>> dailyForecasts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dailyForecasts.map((forecast) {
          final date = DateTime.parse(forecast['dt_txt']);
          final day = DateFormat.E('vi').format(date);
          final tempMax = (forecast['main']['temp_max'] as num).round();
          final tempMin = (forecast['main']['temp_min'] as num).round();
          final weatherIcon = forecast['weather'][0]['icon'];
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Constants.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Constants.secondaryGrey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Constants.darkBlueGrey.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Constants.darkBlueGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Image.network(
                  'https://openweathermap.org/img/wn/$weatherIcon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.cloud,
                    size: 32,
                    color: Constants.secondaryGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$tempMax°/$tempMin°',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Constants.darkBlueGrey,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
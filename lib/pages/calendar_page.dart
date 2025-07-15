import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Dữ liệu mẫu: Map ngày -> outfit/thời tiết/sự kiện
  final Map<String, Map<String, dynamic>> _calendarData = {
    '2024-06-10': {
      'outfit': 'outfit1.png',
      'weather': '01d',
      'event': 'Tiệc tối'
    },
    '2024-06-12': {
      'outfit': 'outfit2.png',
      'weather': '10d',
      'event': 'Mua sắm'
    },
  };

  List<Widget> _buildDayCells() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = (firstDayOfMonth.weekday % 7); // 0: CN, 1: T2, ...

    List<Widget> cells = [];

    // Ô trống đầu tháng
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(Container());
    }

    // Các ngày trong tháng
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final key = DateFormat('yyyy-MM-dd').format(date);
      final data = _calendarData[key];

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _selectedDay == date ? Colors.purple.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedDay == date ? Colors.purple : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (data?['weather'] != null)
                  Image.network(
                    'https://openweathermap.org/img/wn/${data?['weather']}.png',
                    width: 24,
                  ),
                if (data?['outfit'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Image.asset(
                      'assets/outfits/${data?['outfit']}',
                      width: 24,
                    ),
                  ),
                if (data?['event'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.event, color: Colors.pink, size: 16),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Đảm bảo đủ 42 ô (6 hàng)
    while (cells.length < 42) {
      cells.add(Container());
    }

    return cells;
  }

  void _showAddEventDialog() {
    if (_selectedDay == null) return;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final TextEditingController eventController = TextEditingController();
    final TextEditingController outfitController = TextEditingController();
    String? weatherIcon;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm sự kiện cho ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: eventController,
                decoration: const InputDecoration(labelText: 'Tên sự kiện'),
              ),
              TextField(
                controller: outfitController,
                decoration: const InputDecoration(labelText: 'Tên outfit (ảnh asset)'),
              ),
              DropdownButtonFormField<String>(
                value: weatherIcon,
                items: [
                  '01d', '02d', '03d', '04d', '09d', '10d', '11d', '13d', '50d'
                ].map((icon) => DropdownMenuItem(
                  value: icon,
                  child: Row(
                    children: [
                      Image.network('https://openweathermap.org/img/wn/$icon.png', width: 24),
                      const SizedBox(width: 8),
                      Text(icon),
                    ],
                  ),
                )).toList(),
                onChanged: (val) => weatherIcon = val,
                decoration: const InputDecoration(labelText: 'Icon thời tiết'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _calendarData[dateKey] = {
                  'event': eventController.text,
                  'outfit': outfitController.text,
                  'weather': weatherIcon,
                };
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch thời trang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = null;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Dự báo 7 ngày tiếp theo ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dự báo thời tiết 7 ngày tới', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 120,
                  child: WeeklyPlanner(lat: 21.0285, lon: 105.8542),
                ),
              ],
            ),
          ),
          // --- Lịch tháng ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                    _selectedDay = null;
                  }),
                ),
                Text(
                  DateFormat('MMMM yyyy', 'vi').format(_focusedDay),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                    _selectedDay = null;
                  }),
                ),
              ],
            ),
          ),
          // Lưới thứ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ))
                .toList(),
          ),
          // Lưới ngày
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              children: _buildDayCells(),
            ),
          ),
          // Chi tiết ngày đã chọn
          if (_selectedDay != null)
            Container(
              width: double.infinity,
              color: Colors.purple.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (_calendarData[DateFormat('yyyy-MM-dd').format(_selectedDay!)]?['event'] != null)
                    Text('Sự kiện: ${_calendarData[DateFormat('yyyy-MM-dd').format(_selectedDay!)]?['event']}'),
                  if (_calendarData[DateFormat('yyyy-MM-dd').format(_selectedDay!)]?['outfit'] != null)
                    Text('Outfit: ${_calendarData[DateFormat('yyyy-MM-dd').format(_selectedDay!)]?['outfit']}'),
                  if (_calendarData[DateFormat('yyyy-MM-dd').format(_selectedDay!)]?['weather'] != null)
                    Text('Thời tiết: ${_calendarData[DateFormat('yyyy-MM-dd').format(_selectedDay!)]?['weather']}'),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Widget dự báo 7 ngày ---
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Lỗi: $_error'));
    }
    if (forecast == null || forecast!.isEmpty) {
      return const Center(child: Text('Không có dữ liệu thời tiết.'));
    }
    return buildWeeklyWeatherCard(forecast!);
  }
}

Widget buildWeeklyWeatherCard(List<Map<String, dynamic>> dailyForecasts) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: dailyForecasts.map((forecast) {
        final date = DateTime.parse(forecast['dt_txt']);
        final day = DateFormat.E('vi').format(date); // Thứ
        final tempMax = (forecast['main']['temp_max'] as num).round();
        final tempMin = (forecast['main']['temp_min'] as num).round();
        final weatherIcon = forecast['weather'][0]['icon'];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
              Image.network('https://openweathermap.org/img/wn/$weatherIcon.png', width: 32),
              Text('$tempMax° / $tempMin°'),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

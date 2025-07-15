import 'package:flutter/material.dart';
import '../services/activity_history_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECEF),
      appBar: AppBar(
        title: const Text('Lịch Kế Hoạch'),
        backgroundColor: const Color(0xFFE8EDF1),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar Header
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFE8EDF1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                      });
                    },
                  ),
                  Text(
                    '${_focusedDate.month}/${_focusedDate.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Calendar Grid
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Day headers
                    Row(
                      children: ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7']
                          .map((day) => Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    day,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    
                    // Calendar days
                    Expanded(
                      child: _buildCalendarGrid(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Events for selected date
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sự kiện ngày ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEventList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEventDialog();
        },
        backgroundColor: const Color(0xFF2C4C74),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final days = <Widget>[];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      days.add(const Expanded(child: SizedBox()));
    }
    
    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      days.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2C4C74)
                    : isToday
                        ? const Color(0xFF2C4C74).withValues(alpha: 0.3)
                        : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected || isToday ? Colors.white : Colors.black,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      children: days,
    );
  }

  Widget _buildEventList() {
    // Mock events - trong thực tế sẽ lấy từ database
    final events = [
      {'title': 'Họp nhóm', 'time': '09:00', 'color': Colors.blue},
      {'title': 'Mua sắm', 'time': '14:00', 'color': Colors.green},
      {'title': 'Gym', 'time': '18:00', 'color': Colors.orange},
    ];

    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Không có sự kiện nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: events.map((event) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (event['color'] as Color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: event['color'] as Color),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: event['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              event['time'] as String,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm sự kiện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên sự kiện',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Thời gian (HH:MM)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final time = timeController.text.trim();
              
              if (title.isNotEmpty && time.isNotEmpty) {
                // TODO: Lưu sự kiện vào database
                
                // Thêm activity history
                await ActivityHistoryService.addActivity(
                  action: 'calendar',
                  description: 'Thêm sự kiện: $title lúc $time',
                  metadata: {
                    'title': title,
                    'time': time,
                    'date': '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  },
                );
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm sự kiện')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  late Timer _timer;
  late DateTime _now;

  final TextEditingController _noteController = TextEditingController();
  bool _isLoadingNote = false;
  String? _noteDocId;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
    _loadNoteForDate(_selectedDate);
  }

  @override
  void dispose() {
    _timer.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNoteForDate(DateTime date) async {
    setState(() {
      _isLoadingNote = true;
      _noteController.text = '';
      _noteDocId = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingNote = false;
      });
      return;
    }
    final dateStr = _dateToString(date);
    final query = await FirebaseFirestore.instance
        .collection('notes')
        .where('uid', isEqualTo: user.uid)
        .where('date', isEqualTo: dateStr)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      _noteController.text = query.docs.first['note'] ?? '';
      _noteDocId = query.docs.first.id;
    } else {
      _noteController.text = '';
      _noteDocId = null;
    }
    setState(() {
      _isLoadingNote = false;
    });
  }

  Future<void> _saveNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dateStr = _dateToString(_selectedDate);
    final note = _noteController.text.trim();
    if (_noteDocId != null) {
      // Update
      await FirebaseFirestore.instance.collection('notes').doc(_noteDocId).update({
        'note': note,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create
      final doc = await FirebaseFirestore.instance.collection('notes').add({
        'uid': user.uid,
        'date': dateStr,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _noteDocId = doc.id;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu ghi chú!')));
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch cá nhân'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Đồng hồ thời gian thực
              Text(
                '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 24),
              CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadNoteForDate(date);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Ngày đã chọn: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _isLoadingNote
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _noteController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Ghi chú cho ngày này',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _saveNote,
                            child: const Text('Lưu ghi chú'),
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
} 
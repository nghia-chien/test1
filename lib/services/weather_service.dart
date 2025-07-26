// lib/services/weather_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'f94c5b656cfbe42910530eb22b03f890'; // Thay bằng API key thật của bạn
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    final url = '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=vi';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchWeeklyForecast(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=vi';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> forecastList = data['list'];

      // Lấy 1 lần / ngày từ kết quả mỗi 3 giờ (mỗi ngày có 8 bản ghi)
      final Map<String, Map<String, dynamic>> dailyMap = {};

      for (var item in forecastList) {
        final date = DateTime.parse(item['dt_txt']);
        final dayKey = '${date.year}-${date.month}-${date.day}';

        // Chọn bản ghi giữa trưa làm đại diện (12:00)
        if (date.hour == 12 && !dailyMap.containsKey(dayKey)) {
          dailyMap[dayKey] = item;
        }
      }

      return dailyMap.values.take(7).toList();
    } else {
      throw Exception('Failed to load forecast');
    }
  }

  static IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.beach_access; // Or some other rain icon
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return Icons.cloud_queue;
      default:
        return Icons.wb_cloudy;
    }
  }
}
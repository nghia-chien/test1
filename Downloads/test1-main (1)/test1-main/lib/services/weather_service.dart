// lib/services/weather_service.dart
import 'dart:convert';
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
}

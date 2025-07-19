import 'package:flutter/material.dart';
import '../constants/constants.dart';

class ColorUpdater {
  // Các màu cũ cần thay thế
  static const Map<String, Color> oldColors = {
    'Colors.white': Colors.white,
    'Colors.black': Colors.black,
    'Colors.grey': Colors.grey,
    'Color(0xFF4285F4)': Color(0xFF4285F4),
    'Color(0xFF6366F1)': Color(0xFF6366F1),
  };

  // Các màu mới tương ứng
  static const Map<String, Color> newColors = {
    'Colors.white': Constants.pureWhite,
    'Colors.black': Constants.darkBlueGrey,
    'Colors.grey': Constants.secondaryGrey,
    'Color(0xFF4285F4)': Constants.primaryBlue,
    'Color(0xFF6366F1)': Constants.primaryBlue,
  };

  // Các style cần cập nhật
  static Map<String, TextStyle> get oldTextStyles => {
    'Colors.black': const TextStyle(color: Colors.black),
    'Colors.grey': const TextStyle(color: Colors.grey),
    'Colors.black87': const TextStyle(color: Colors.black87),
    'Colors.grey[600]': TextStyle(color: Colors.grey[600]),
  };

  static Map<String, TextStyle> get newTextStyles => {
    'Colors.black': TextStyle(color: Constants.darkBlueGrey),
    'Colors.grey': TextStyle(color: Constants.secondaryGrey),
    'Colors.black87': TextStyle(color: Constants.darkBlueGrey),
    'Colors.grey[600]': TextStyle(color: Constants.secondaryGrey),
  };
} 
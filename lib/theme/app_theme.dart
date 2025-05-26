import 'package:flutter/material.dart';

class AppTheme {
//nền sáng 
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.lightGreen,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 53, 53, 53),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black),
    ),
  );
//nền tối 
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blueGrey,
    scaffoldBackgroundColor: const Color.fromARGB(255, 33, 33, 33),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 50, 50, 50),
      titleTextStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 20),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color.fromARGB(255, 48, 48, 48)),
    ),
    
  );
}

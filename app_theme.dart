import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme - Blue, Green, Purple Colors
  static ThemeData lightTheme = ThemeData(
    primaryColor: Color(0xFF6A11CB), // Purple
    primaryColorDark: Color(0xFF2575FC), // Blue
    primaryColorLight: Color(0xFF02AAB0), // Teal
    secondaryHeaderColor: Color(0xFF00CDAC), // Green
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF6A11CB),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6A11CB),
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2575FC),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.grey[800],
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Color(0xFF6A11CB),
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Color(0xFF6A11CB), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    ),
    colorScheme: ColorScheme.light(
      primary: Color(0xFF6A11CB),
      secondary: Color(0xFF00CDAC),
      background: Colors.white,
      surface: Colors.white,
    ).copyWith(
      surface: Colors.white,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    primaryColor: Color(0xFFBB86FC),
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
    ),
    colorScheme: ColorScheme.dark(
      primary: Color(0xFFBB86FC),
      secondary: Color(0xFF03DAC6),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
    ),
  );
}
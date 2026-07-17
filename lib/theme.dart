import 'package:flutter/material.dart';

// Netflix-inspired dark palette
const kBackground = Color(0xFF141414);
const kSurface = Color(0xFF1F1F1F);
const kSurfaceLight = Color(0xFF2A2A2A);
const kRed = Color(0xFFE50914);
const kTextPrimary = Colors.white;
const kTextSecondary = Color(0xFFB3B3B3);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.dark(
      primary: kRed,
      secondary: kRed,
      surface: kSurface,
      onPrimary: Colors.white,
      onSurface: kTextPrimary,
    ),
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kTextPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: kTextPrimary,
      displayColor: kTextPrimary,
    ),
    cardTheme: const CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      hintStyle: const TextStyle(color: kTextSecondary),
      labelStyle: const TextStyle(color: kTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kRed, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kTextSecondary),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kRed,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0B0B0B),
      selectedItemColor: kRed,
      unselectedItemColor: kTextSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kSurfaceLight,
      contentTextStyle: TextStyle(color: kTextPrimary),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kRed),
    listTileTheme: const ListTileThemeData(
      textColor: kTextPrimary,
      iconColor: kTextSecondary,
    ),
    dividerTheme: const DividerThemeData(color: kSurfaceLight),
  );
}

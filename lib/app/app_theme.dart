import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF382414);
  static const blue = Color(0xFFC8500B);
  static const orange = Color(0xFFC8500B);
  static const yellow = Color(0xFFFFC928);
  static const canvas = Color(0xFFFFFAF2);
  static const border = Color(0xFFF0E4D4);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: orange, primary: orange, secondary: yellow, surface: Colors.white),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: navy,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w800),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: Color(0x18382414),
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: border)),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: orange,
          unselectedLabelColor: Color(0xFF8A7866),
          indicatorColor: orange,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(fontWeight: FontWeight.w700),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: orange,
            side: const BorderSide(color: Color(0xFFFFD36A)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            minimumSize: const Size(44, 46),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: yellow,
          foregroundColor: navy,
          elevation: 2,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: orange),
        dividerColor: border,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: orange, width: 1.7)),
          labelStyle: const TextStyle(color: Color(0xFF8A7866)),
          prefixIconColor: orange,
        ),
      );
}

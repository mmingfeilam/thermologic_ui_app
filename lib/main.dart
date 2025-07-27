import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(ThermoLogicApp());
}

class ThermoLogicApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThermoLogic AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1E3A8A), // Deep blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}

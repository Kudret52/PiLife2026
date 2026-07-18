import 'package:flutter/material.dart';

import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const PiLifeApp());
}

class PiLifeApp extends StatelessWidget {
  const PiLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiLife',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B2D90)),
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}

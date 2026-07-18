import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final loggedIn = await UserService.loadUser();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => loggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5B2D90),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 65,
              backgroundColor: Color(0xFFF4AF2C),
              child: Text(
                "π",
                style: TextStyle(
                  fontSize: 70,
                  color: Color(0xFF5B2D90),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 30),

            Text(
              "PiLife",
              style: TextStyle(
                fontSize: 34,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

            SizedBox(height: 12),

            Text(
              "Hayatını organize et",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),

            SizedBox(height: 40),

            CircularProgressIndicator(color: Color(0xFFF4AF2C)),
          ],
        ),
      ),
    );
  }
}

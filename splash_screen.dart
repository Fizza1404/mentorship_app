import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getString('uid') != null;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => isLoggedIn ? const HomeScreen() : LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140, height: 140,
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                        'images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, e, s) => const Icon(Icons.school, size: 70, color: Color(0xFF6A11CB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('UNIVERSITY MENTORSHIP', style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  const Text('Mentorship & Academic Growth', style: TextStyle(fontSize: 13, color: Colors.white70, letterSpacing: 1)),
                ],
              ),
            ),
            const Positioned(
              bottom: 50, left: 0, right: 0,
              child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white70))),
            )
          ],
        ),
      ),
    );
  }
}
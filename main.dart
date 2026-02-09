import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'services/notification_service.dart';

// Screens imports
import 'screens/auth/splash_screen.dart';

// Providers
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => MyAuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Mentorship',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF6A11CB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A11CB),
          primary: const Color(0xFF6A11CB),
          secondary: const Color(0xFF2575FC),
        ),
        
        // --- Updated Typography System (Professional Sizes) ---
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
          titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
          titleMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
          bodyLarge: GoogleFonts.poppins(fontSize: 16, color: Colors.black87), // Standard Body
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: Colors.black54), // Secondary Text
          labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF6A11CB),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          iconTheme: const IconThemeData(color: Colors.white, size: 24),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
      home: SplashScreen(),
    );
  }
}
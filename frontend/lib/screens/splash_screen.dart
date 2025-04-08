import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Check login status after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndNavigate();
    });
  }

  Future<void> _checkLoginAndNavigate() async {
    try {
      // Show splash for a minimal time (800ms)
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;

      // Simple token check
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.containsKey('access_token');
      
      if (!mounted) return;

      // Navigate based on token presence
      if (hasToken) {
        Navigator.pushReplacementNamed(context, '/swipe');
        _verifyTokenInBackground();
      } else {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      print('Error in splash screen: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }
  
  void _verifyTokenInBackground() {
    Future.microtask(() async {
      try {
        final isValid = await _authService.isLoggedIn(skipTokenVerification: false);
        if (!isValid && mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      } catch (e) {
        print('Background token verification error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Light blue background
      body: Center(
        child: Image.asset(
          'logo_images/1.png', // Using the first logo image
          width: 200, // Adjust size as needed
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}


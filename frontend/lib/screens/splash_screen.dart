import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.65, curve: Curves.easeOut),
    ));

    // Start the animation
    _controller.forward();

    // Check login status after animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndNavigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginAndNavigate() async {
    try {
      // Show splash for a longer time (2000ms = 2 seconds)
      await Future.delayed(const Duration(milliseconds: 2000));
      
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Image.asset(
                  'logo_images/1.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


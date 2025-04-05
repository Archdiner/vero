import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _pulseController;
  final AuthService _authService = AuthService();
  bool _contentVisible = false; // Track if content is visible

  // 6 particles with positions, colors, radii, delay, and pulsePhase.
  final List<_Particle> _particles = [
    // Left side (blue)
    _Particle(
      offset: Offset(-120, -30),
      color: AppColors.primaryBlue,
      radius: 4,
      delay: 0.0,
      pulsePhase: 0.0,
    ),
    _Particle(
      offset: Offset(-100, 0),
      color: AppColors.primaryLightBlue,
      radius: 5,
      delay: 0.15,
      pulsePhase: 0.2,
    ),
    _Particle(
      offset: Offset(-125, 30),
      color: AppColors.primaryBlue,
      radius: 3,
      delay: 0.3,
      pulsePhase: 0.4,
    ),
    // Right side (white)
    _Particle(
      offset: Offset(125, 30),
      color: Colors.white70,
      radius: 4,
      delay: 0.0,
      pulsePhase: 0.6,
    ),
    _Particle(
      offset: Offset(100, 0),
      color: Colors.white70,
      radius: 5,
      delay: 0.15,
      pulsePhase: 0.8,
    ),
    _Particle(
      offset: Offset(120, -30),
      color: Colors.white70,
      radius: 3,
      delay: 0.3,
      pulsePhase: 0.5,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Make content visible immediately
    setState(() {
      _contentVisible = true;
    });

    // Start animations with shorter durations 
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Continuous pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Start login check as soon as we've rendered the first frame
    _checkLoginAfterFirstFrame();
  }

  // Use this method to ensure the splash screen is visible before checking login
  void _checkLoginAfterFirstFrame() {
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

      // Navigate immediately based on token
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
  
  // Verify token validity after user is already in the app
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
  void dispose() {
    _bubbleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return a very simple widget structure that renders instantly
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background color (renders instantly)
            Container(color: Colors.black),
            
            // Particles - only show if content is visible
            if (_contentVisible)
              for (final p in _particles)
                _AnimatedParticle(
                  particle: p,
                  bubbleController: _bubbleController,
                  pulseController: _pulseController,
                ),

            // Centered Logo + "Vero" - always show immediately
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Icon(
                      Icons.location_on,
                      size: 80,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vero',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Particle data: final offset, color, radius, bubble delay, pulse phase offset.
class _Particle {
  final Offset offset;
  final Color color;
  final double radius;
  final double delay;      // 0..1 => when the bubble starts in the 2s timeline
  final double pulsePhase; // 0..1 => shifts the pulsing wave

  _Particle({
    required this.offset,
    required this.color,
    required this.radius,
    required this.delay,
    required this.pulsePhase,
  });
}

/// A widget that:
/// 1) Staggers bubble-up from below based on 'delay'
/// 2) Fades in
/// 3) Continuously changes size (pulses) using a second controller
class _AnimatedParticle extends StatelessWidget {
  final _Particle particle;
  final AnimationController bubbleController;
  final AnimationController pulseController;

  const _AnimatedParticle({
    Key? key,
    required this.particle,
    required this.bubbleController,
    required this.pulseController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to both controllers
    return AnimatedBuilder(
      animation: Listenable.merge([bubbleController, pulseController]),
      builder: (context, child) {
        // 1) Compute bubble progress with delay
        double effectiveProgress;
        if (bubbleController.value < particle.delay) {
          effectiveProgress = 0.0;
        } else {
          effectiveProgress =
              (bubbleController.value - particle.delay) / (1 - particle.delay);
        }
        effectiveProgress = effectiveProgress.clamp(0.0, 1.0);

        // Start offset: 150px below final
        final startOffset = Offset(
          particle.offset.dx,
          particle.offset.dy + 150,
        );

        // Current bubble offset
        final currentOffset = Offset(
          startOffset.dx +
              (particle.offset.dx - startOffset.dx) * effectiveProgress,
          startOffset.dy +
              (particle.offset.dy - startOffset.dy) * effectiveProgress,
        );

        // Fade in
        final opacity = effectiveProgress;

        // Convert offset from center -> alignment
        final halfWidth = MediaQuery.of(context).size.width / 2;
        final halfHeight = MediaQuery.of(context).size.height / 2;
        final alignment = Alignment(
          currentOffset.dx / halfWidth,
          currentOffset.dy / halfHeight,
        );

        // 2) Pulse scale
        // We only want to start pulsing once the bubble is fully visible,
        // so multiply amplitude by effectiveProgress.
        final pulseValue = (pulseController.value + particle.pulsePhase) % 1.0;
        // sin wave => -1..1, so scale => 1 +/- 0.2
        double scaleFactor = 1.0 + (sin(pulseValue * 2 * pi) * 0.2 * effectiveProgress);

        // Final size
        final bubbleSize = (particle.radius * 2) * scaleFactor;

        return Align(
          alignment: alignment,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: bubbleSize,
              height: bubbleSize,
              decoration: BoxDecoration(
                color: particle.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}


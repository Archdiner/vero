import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/themes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _pulseController;
  final AuthService _authService = AuthService();

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

    // 2s bubble-up animation
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Continuous pulse animation (e.g., 2s cycle)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Check login status and navigate
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    try {
      // Wait for the splash animation
      await Future.delayed(const Duration(milliseconds: 2500));
      
      if (!mounted) return;

      final isLoggedIn = await _authService.isLoggedIn();
      print('Splash screen: Login status checked, isLoggedIn: $isLoggedIn');
      
      if (!mounted) return;

      if (isLoggedIn) {
        // Check if user has completed onboarding
        final hasCompletedOnboarding = await _authService.hasCompletedOnboarding();
        print('Splash screen: Onboarding completed: $hasCompletedOnboarding');
        
        if (hasCompletedOnboarding) {
          Navigator.pushReplacementNamed(context, '/swipe');
        } else {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      print('Error checking login status in splash screen: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Particles
          for (final p in _particles)
            _AnimatedParticle(
              particle: p,
              bubbleController: _bubbleController,
              pulseController: _pulseController,
            ),

          // Centered Logo + "Vero"
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 80,
                        color: AppColors.primaryBlue, // Use the theme blue color
                      ),
                    ],
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

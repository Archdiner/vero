import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 6 total particles with BOTH x and y offsets
  // arranged around the logo in a rough arc
  final List<_Particle> _particles = [
    // Left side
    _Particle(
      initialOffset: Offset(-120, -30),
      color: Colors.orange,
      radius: 4,
    ),
    _Particle(
      initialOffset: Offset(-100, 0),
      color: Colors.orangeAccent,
      radius: 5,
    ),
    _Particle(
      initialOffset: Offset(-125, 30),
      color: Colors.orange,
      radius: 3,
    ),
    // Right side
    _Particle(
      initialOffset: Offset(125, 30),
      color: Colors.white70,
      radius: 4,
    ),
    _Particle(
      initialOffset: Offset(100, 0),
      color: Colors.white70,
      radius: 5,
    ),
    _Particle(
      initialOffset: Offset(120, -30),
      color: Colors.white70,
      radius: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Controls the bobbing animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Navigate after 2 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 2), () {
        bool isLoggedIn = false; // Replace with actual auth check
        if (isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // pure black
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // -- 1) Particles --
              ..._particles.map((p) => _buildAnimatedParticle(p)),

              // -- 2) Centered Logo + "Vero" --
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Overlapping Icon + "V"
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 80,
                            color: const Color(0xFFFF6F40), // Orange
                          ),
                          const Text(
                            'V',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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

              // -- 3) Loading Spinner (Lower) --
              Align(
                alignment: const Alignment(0, 0.9),
                // 0.8 is quite low on the screen. 
                // Increase to 0.85 or 0.9 if you want it even lower.
                child: SpinKitRing(
                  color: const Color(0xFFFF6F40),
                  size: 70.0,     // Increase diameter
                  lineWidth: 6.0, // Increase thickness
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedParticle(_Particle particle) {
    final progress = _controller.value; // 0 -> 1
    // Simple bobbing effect using sin/cos
    final dx = particle.initialOffset.dx + sin(progress * 2 * pi) * 10;
    final dy = particle.initialOffset.dy + cos(progress * 2 * pi) * 10;

    // Convert from pixel offsets to alignment
    final halfWidth = MediaQuery.of(context).size.width / 2;
    final halfHeight = MediaQuery.of(context).size.height / 2;

    return Align(
      alignment: Alignment(dx / halfWidth, dy / halfHeight),
      child: Container(
        width: particle.radius * 2,
        height: particle.radius * 2,
        decoration: BoxDecoration(
          color: particle.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Particle data class
class _Particle {
  final Offset initialOffset;
  final Color color;
  final double radius;

  _Particle({
    required this.initialOffset,
    required this.color,
    required this.radius,
  });
}

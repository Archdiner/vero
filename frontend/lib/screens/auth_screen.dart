import 'package:flutter/material.dart';

import '../widgets/furniture_pattern_background.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = Theme.of(context).brightness;
    
    // Define colors using the exact hex values
    final scaffoldBg = const Color(0xFF0F1A24);  // Dark blue background #0F1A24
    final dynamicTextPrimary = Colors.white;  // Always white text for better contrast
    final dynamicTextSecondary = Colors.white.withOpacity(0.8);  // Slightly transparent white
    
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // 1. Background Pattern
          const FurniturePatternBackground(
            opacity: 0.2,  // Increased opacity for better visibility
            spacing: 70,    // Tighter spacing
            iconColor: Color(0xFF293542), // Muted blue-grey #293542
          ),

          // 2. Gradient Overlay - Starts halfway down the screen
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.6, // Covers bottom 60% of screen
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scaffoldBg.withOpacity(0.0),
                    scaffoldBg.withOpacity(0.5),
                    scaffoldBg.withOpacity(0.9),
                    scaffoldBg,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 3. Main Content
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 70), // Reduced from 48
                    Image.asset(
                      'logo_images/white_logo.png',
                      height: 75,
                    ),
                    const SizedBox(height: 16), // Reduced from 24
                    Text(
                      'Welcome to Roomly',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: dynamicTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16), // Reduced from 16
                    Text(
                      'Find the perfect roommate — fast. Whether you\'re looking for a study buddy, a night owl, or someoe who respects your fridge space, we\'ve got covered.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        color: dynamicTextSecondary,
                        height: 1.5,
                      ),
                    ),

                    // Illustration
                    const SizedBox(height: 100),
                    SizedBox(
                      height: size.height * 0.25, // Constrained to 25% of screen height
                      child: Image.asset(
                        'logo_images/roommates.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    // No bottom padding

                    // Buttons Section
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: scaffoldBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: const Text(
                          'Find a Roommate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Already have an account? Log in',
                        style: TextStyle(
                          color: dynamicTextSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final Color color;
  
  BackgroundPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    const spacing = 80.0;  // Reduced spacing between icons
    const iconSize = 20.0; // Smaller icons
    
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        // Draw small squares for a subtle pattern
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x + (spacing / 2), y + (spacing / 2)),
              width: iconSize,
              height: iconSize,
            ),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => false;
}


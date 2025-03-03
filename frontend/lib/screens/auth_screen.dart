import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1) Mosaic
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.8,
            child: MasonryGridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              padding: const EdgeInsets.all(16),
              itemCount: 9,
              itemBuilder: (context, index) {
                final columnIndex = index % 3;
                final rowIndex = index ~/ 3;

                double tileHeight;
                if (columnIndex == 0) {
                  tileHeight = (rowIndex % 2 == 0) ? 180 : 230;
                } else if (columnIndex == 1) {
                  tileHeight = (rowIndex % 2 == 0) ? 230 : 180;
                } else {
                  tileHeight = (rowIndex % 2 == 0) ? 180 : 230;
                }

                return SizedBox(
                  height: tileHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      // Make placeholders lighter to see the gradient better
                      color: Colors.grey[600],
                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.white70,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2) Multi-stop gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,   // 0 -> 0.2
                    Colors.black26,       // 0.2 -> 0.35
                    Colors.black54,       // 0.35 -> 0.5
                    Colors.black87,       // 0.5 -> 0.7
                    Colors.black,         // 0.7 -> 1.0
                  ],
                  stops: [
                    0.15,  // Start fading at 20% down
                    0.3, // then darker
                    0.45,  
                    0.65,  // fully black by 70%
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // 3) Foreground text & button
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 50,
                  color: Color(0xFFFF6F40),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome To Vero',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: const Text(
                    'Discover the best restaurants near you in just a few taps! Whether you’re craving a quick bite, a cozy café, or a fine dining experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    'Already have an account? Log in',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

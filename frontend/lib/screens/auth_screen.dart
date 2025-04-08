import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../utils/themes.dart'; // Import the theme system

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = Theme.of(context).brightness;
    
    // Define dynamic colors based on brightness:
    final scaffoldBg = brightness == Brightness.dark ? Colors.black : Colors.white;
    final bgColor = scaffoldBg; // use the same for gradient
    final placeholderColor =
        brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[300];
    // For text: in dark mode use the AppColors; in light mode, use black or dark grey.
    final dynamicTextPrimary =
        brightness == Brightness.dark ? AppColors.textPrimary : Colors.black;
    final dynamicTextSecondary =
        brightness == Brightness.dark ? AppColors.textSecondary : Colors.black54;
    
    return Scaffold(
      backgroundColor: scaffoldBg,
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
                      // Use dynamic placeholder color
                      color: placeholderColor,
                      child: Icon(
                        Icons.image_outlined,
                        color: dynamicTextSecondary,
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    bgColor.withOpacity(0.26),
                    bgColor.withOpacity(0.54),
                    bgColor.withOpacity(0.87),
                    bgColor,
                  ],
                  stops: const [
                    0.15,
                    0.3,
                    0.45,
                    0.65,
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
                Icon(
                  Icons.location_on,
                  size: 50,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome To Vero',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: dynamicTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Discover the best restaurants near you in just a few taps! Whether you\'re craving a quick bite, a cozy café, or a fine dining experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dynamicTextSecondary,
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
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: dynamicTextPrimary,
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
                  child: Text(
                    'Already have an account? Log in',
                    style: TextStyle(
                      color: dynamicTextSecondary,
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

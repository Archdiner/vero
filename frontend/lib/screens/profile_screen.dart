import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart' as utils;
import '../utils/themes.dart'; // Import our theme system
// Import main.dart to access the global themeNotifier
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _email;
  String? _username;
  bool _isLoading = false;
  bool _isDarkTheme = true;
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    // Initialize the local theme flag from the global themeNotifier.
    _isDarkTheme = themeNotifier.value == ThemeMode.dark;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // If there's no token, redirect to login.
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${utils.BASE_URL}/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _email = data['email'];
          _username = data['fullname']; // Use full name here.
          _profilePicture = data['profile_picture'];
        });
        
        // If profile picture isn't in the response, try to get it from SharedPreferences
        if (_profilePicture == null || _profilePicture!.isEmpty) {
          _profilePicture = prefs.getString('profile_image_url');
        }
      } else {
        if (response.statusCode == 401) {
          await prefs.remove('access_token');
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Exception while fetching profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use theme-aware background color.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // Use the theme’s appBarTheme background.
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        // Let the theme set the icon colors.
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProfileBody() {
    if (_email == null || _username == null) {
      return Center(
        child: Text(
          'No profile data',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // TOP USER INFO CARD
          Container(
            padding: const EdgeInsets.all(16),
            // Use a dark or light container color based on the current brightness.
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // User avatar with profile picture
                Hero(
                  tag: 'user-profile-picture',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Use a theme-aware fallback color.
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      border: Border.all(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                      image: _profilePicture != null && _profilePicture!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_profilePicture!),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                print('Error loading profile image: $exception');
                              },
                            )
                          : null,
                    ),
                    child: _profilePicture == null || _profilePicture!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 40,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Name & email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // PROFILE SETTINGS SECTION
          _buildSectionHeader('Profile settings'),
          const SizedBox(height: 8),
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Personal information',
            onTap: () {
              Navigator.pushNamed(context, '/update_profile');
            },
          ),
          _buildSettingsItem(
            icon: Icons.tune,
            title: 'Preferences',
            onTap: () {
              Navigator.pushNamed(context, '/update_preferences');
            },
          ),
          _buildSettingsItem(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () {
              // Navigate to notifications screen
            },
          ),
          _buildThemeToggleItem(),

          const SizedBox(height: 24),

          // SUPPORT SECTION
          _buildSectionHeader('Support'),
          const SizedBox(height: 8),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Contact us',
            onTap: () {
              // Navigate to contact page
            },
          ),
          _buildSettingsItem(
            icon: Icons.star_border,
            title: 'Rate us',
            onTap: () {
              // Launch app store rating page
            },
          ),

          const SizedBox(height: 24),

          // LEGAL SECTION
          _buildSectionHeader('Legal section'),
          const SizedBox(height: 8),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'CGU',
            onTap: () {
              // Terms & conditions
            },
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              // Privacy policy page
            },
          ),

          const SizedBox(height: 24),

          // LOGOUT
          _buildSettingsItem(
            icon: Icons.logout,
            iconColor: Colors.redAccent,
            title: 'Logout',
            titleColor: Colors.redAccent,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          // Use a dark or light background based on current brightness.
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: titleColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).iconTheme.color?.withOpacity(0.4), size: 16),
          ],
        ),
      ),
    );
  }

Widget _buildThemeToggleItem() {
  final brightness = Theme.of(context).brightness;
  final colorScheme = Theme.of(context).colorScheme;
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      // Match the same background logic you use in your other items:
      color: brightness == Brightness.dark
          ? const Color(0xFF1E1E1E) // or AppColors.surface
          : Colors.grey[200],       // or a light color from themes.dart
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        // Use theme’s icon color
        Icon(Icons.brightness_4_outlined, color: Theme.of(context).iconTheme.color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Theme',
            // Use the theme's onSurface or onBackground color instead of white
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
        ),
        Text(
          _isDarkTheme ? 'Dark' : 'Light',
          // Same idea here — rely on theme color
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
        ),
        const SizedBox(width: 8),
        Switch(
          activeColor: AppColors.primaryBlue,
          value: _isDarkTheme,
          onChanged: (val) async {
            setState(() {
              _isDarkTheme = val;
            });
            // Update global theme
            themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
            // Persist the preference
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isDarkTheme', val);
          },
        ),
      ],
    ),
  );
}

  Widget _buildBottomNavBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left: search icon to indicate current screen
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color, size: 28),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/swipe');
            },
          ),
          // Center: chat icon
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).iconTheme.color, size: 26),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/matches');
            },
          ),
          // Right: person icon (active)
          IconButton(
            icon: Icon(Icons.person_outline, color: AppColors.primaryBlue, size: 28),
            onPressed: () {
              // Already on profile screen
            },
          ),
        ],
      ),
    );
  }
}

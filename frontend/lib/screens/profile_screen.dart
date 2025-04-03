import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart' as utils;
import '../utils/themes.dart'; // Import our theme system

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
      backgroundColor: Colors.black, // Same as SwipeScreen.
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
      return const Center(
        child: Text(
          'No profile data',
          style: TextStyle(color: Colors.white),
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
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
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
                      color: Colors.grey[800],
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
                          color: Colors.white,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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
              Navigator.pushReplacementNamed(context, '/update_profile');
            },
          ),
          _buildSettingsItem(
            icon: Icons.tune,
            title: 'Preferences',
            onTap: () {
              // Handle preferences locally
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preferences feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
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
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color iconColor = Colors.white70,
    Color titleColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: titleColor, fontSize: 14),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.brightness_4_outlined, color: Colors.white70),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Theme',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            _isDarkTheme ? 'Dark' : 'Light',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Switch(
            activeColor: AppColors.primaryBlue,
            value: _isDarkTheme,
            onChanged: (val) {
              setState(() {
                _isDarkTheme = val;
              });
              // Optionally add theme logic here.
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
                  // Left: search icon (orange) to indicate current screen
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white54, size: 28),
                    onPressed: () {
                      // Already on search screen
                    },
                  ),
                  // Center: chat icon
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 26),
                    onPressed: () {
                      // Navigate to matches screen
                      Navigator.pushReplacementNamed(context, '/matches');
                    },
                  ),
                  // Right: person icon (gray)
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: AppColors.primaryBlue, size: 28),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/profile');
                    },
                  ),
                ],
              ),
            );
  }
}

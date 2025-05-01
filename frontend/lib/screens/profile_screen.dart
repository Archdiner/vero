import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart' as utils;
import '../utils/themes.dart';
import '../main.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/furniture_pattern_background.dart';

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
    _isDarkTheme = themeNotifier.value == ThemeMode.dark;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${utils.BASE_URL}/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _email = data['email'];
          _username = data['fullname'];
          _profilePicture = data['profile_picture'];
        });
        if (_profilePicture == null || _profilePicture!.isEmpty) {
          _profilePicture = prefs.getString('profile_image_url');
        }
      } else if (response.statusCode == 401) {
        await prefs.remove('access_token');
        Navigator.pushReplacementNamed(context, '/login');
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
      extendBodyBehindAppBar: true,
      backgroundColor: Color(0xFF0F1A24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Stack(
        children: [
          const FurniturePatternBackground(
            spacing: 70,
            opacity: 0.2,
            iconColor: Color(0xFF293542),
          ),

          // loader stays the same
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Padding(
              // push below status bar + toolbar
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
              child: _buildProfileBody(),
            ),
        ],
      ),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF000A14)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'user-profile-picture',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
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
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Profile settings'),
          const SizedBox(height: 8),
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Personal information',
            onTap: () => Navigator.pushNamed(context, '/update_profile'),
          ),
          _buildSettingsItem(
            icon: Icons.tune,
            title: 'Preferences',
            onTap: () => Navigator.pushNamed(context, '/update_preferences'),
          ),
          _buildSettingsItem(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          // _buildThemeToggleItem(),
          const SizedBox(height: 24),
          _buildSectionHeader('Support'),
          const SizedBox(height: 8),
          _buildSettingsItem(
            icon: Icons.mail_outline,
            title: 'Email us',
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'admin@gulfintelai.com',
                query: Uri.encodeQueryComponent(
                    'subject=Contact Inquiry&body=Hello, I would like to get in touch with you.'),
              );
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
              } else {
                print('Could not launch email client');
              }
            },
          ),
          _buildSettingsItem(
            icon: Icons.star_border,
            title: 'Rate us',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Legal section'),
          const SizedBox(height: 8),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'CGU',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
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
          color: Theme.of(context)
              .colorScheme
              .onBackground
              .withOpacity(0.7),
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
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF000A14)
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
            Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                size: 16),
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
        color: brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.brightness_4_outlined, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Theme',
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
            ),
          ),
          Text(
            _isDarkTheme ? 'Dark' : 'Light',
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
              themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
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
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color, size: 28),
            onPressed: () => Navigator.pushReplacementNamed(context, '/swipe'),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).iconTheme.color, size: 26),
            onPressed: () => Navigator.pushReplacementNamed(context, '/matches'),
          ),
          IconButton(
            icon: Icon(Icons.person, color: AppColors.primaryBlue, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

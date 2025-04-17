import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/roommate_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/detailed_profile_view.dart';
import '../utils/themes.dart'; // Import our theme system
import '../widgets/furniture_pattern_background.dart';
import 'dart:math' as math;

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final RoommateService _roommateService = RoommateService();
  List<UserProfile> _matches = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final matches = await _roommateService.fetchMatches();
      
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching matches: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to format match date
  String _formatMatchDate(String? matchedAt) {
    if (matchedAt == null) return 'Recently';
    
    try {
      final date = DateTime.parse(matchedAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'Just now';
        }
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      print('Error parsing date: $e');
      return 'Recently';
    }
  }

  // Helper method to get compatibility color
  Color _getCompatibilityColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 70) return Color(0xFF2ECC71); // Green
    if (score >= 50) return Color(0xFFFFB74D); // Orange
    return Color(0xFFFF6B6B); // Red
  }

  // Helper method to get university color
  Color _getUniversityColor(String? university) {
    if (university == null) return Colors.grey;
    switch (university.toLowerCase()) {
      case 'cornell university':
        return Color(0xFFB31B1B); // Cornell Red
      case 'columbia university':
        return Color(0xFF1F45FC); // Columbia Blue
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F1A24),
      body: Stack(
        children: [
          // Background Pattern
          const FurniturePatternBackground(
            spacing: 70,
            opacity: 0.2,
            iconColor: Color(0xFF293542),
          ),
          // Main Content
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Your Matches',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SafeArea(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: AppColors.buttonBlue),
                        )
                      : _hasError
                          ? _buildErrorState()
                          : _matches.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _fetchMatches,
                                  color: AppColors.buttonBlue,
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(16),
                                    itemCount: _matches.length,
                                    itemBuilder: (context, index) {
                                      final match = _matches[index];
                                      return _buildMatchCard(match);
                                    },
                                  ),
                                ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildMatchCard(UserProfile match) {
    String matchTime = _formatMatchDate(match.matchedAt);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showMatchOptions(match, Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    match.profilePicture.isNotEmpty
                        ? match.profilePicture
                        : 'https://via.placeholder.com/100?text=No+Image',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.white.withOpacity(0.1),
                        child: Icon(Icons.person, color: Colors.white54, size: 40),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                // Match Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.fullName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${match.age ?? ""}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (match.age != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              match.major ?? '',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Matched $matchTime',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                // Compatibility Wheel
                CustomPaint(
                  size: Size(100, 100),
                  painter: CompatibilityWheelPainter(
                    percentage: match.compatibilityScore ?? 0,
                    strokeWidth: 2.3,
                  ),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: Text(
                        '${(match.compatibilityScore ?? 0).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavBarItem(Icons.search, false, () {
            Navigator.pushReplacementNamed(context, '/swipe');
          }),
          _buildNavBarItem(Icons.chat_bubble, true, () {}),
          _buildNavBarItem(Icons.person_outline, false, () {
            Navigator.pushReplacementNamed(context, '/profile');
          }),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, bool isActive, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        icon,
        color: isActive ? AppColors.buttonBlue : Colors.white54,
        size: 28,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            color: Colors.white54,
            size: 72,
          ),
          SizedBox(height: 16),
          Text(
            'No matches yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'When you and another person both like each other, they\'ll show up here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/swipe');
            },
            icon: Icon(Icons.search),
            label: Text('Find Roommates'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load matches',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchMatches,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showMatchOptions(UserProfile match, Brightness brightness) {
    showModalBottomSheet(
      context: context,
      backgroundColor: brightness == Brightness.dark ? Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              match.fullName,
              style: TextStyle(
                color: brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_camera, color: AppColors.primaryBlue),
              title: Text(
                'Open Instagram',
                style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                _openInstagramProfile(match);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: brightness == Brightness.dark ? Colors.white70 : Colors.black54),
              title: Text(
                'View Profile',
                style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDetailedProfile(match);
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: Colors.red),
              title: Text(
                'Unmatch',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showUnmatchConfirmation(match);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ONLY changed text colors in light mode for the detailed profile
  void _showDetailedProfile(UserProfile match) {
    final brightness = Theme.of(context).brightness;
    // Create a custom text theme only for light mode to make white text -> black, light grey -> dark grey
    final customTextTheme = brightness == Brightness.light
        ? Theme.of(context).textTheme.copyWith(
            // "bodyLarge" is roughly the old "bodyText1"
            bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black),
            // "bodyMedium" is roughly the old "bodyText2"
            bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
            // "titleLarge" is roughly the old "headline6"
            titleLarge: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black),
          )
        : Theme.of(context).textTheme;

    print('Showing detailed profile for: ${match.fullName}');
    print('Preferences data: Cleanliness: ${match.cleanlinessLevel}, SleepTime: ${match.sleepTime}, WakeTime: ${match.wakeTime}');
    print('More preferences: Smoking: ${match.smokingPreference}, Drinking: ${match.drinkingPreference}, Pets: ${match.petPreference}');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: brightness == Brightness.dark ? Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      // Override the theme in light mode to make text black/dark grey
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(textTheme: customTextTheme),
        child: DetailedProfileView(
          userProfile: match,
          onInstagramTap: (username) => _openInstagramProfile(match),
          actionButtons: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showUnmatchConfirmation(match);
                  },
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Unmatch",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showUnmatchConfirmation(UserProfile match) {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: brightness == Brightness.dark ? Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Unmatch',
            style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Are you sure you want to unmatch with ${match.fullName}?',
            style: TextStyle(color: brightness == Brightness.dark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _unmatchUser(match);
              },
              child: Text(
                'Unmatch',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _unmatchUser(UserProfile match) async {
    try {
      final success = await _roommateService.unmatchUser(match.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unmatched from ${match.fullName}'),
            duration: Duration(seconds: 2),
          ),
        );
        _fetchMatches();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unmatch. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error unmatching user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while unmatching.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openInstagramProfile(UserProfile match) {
    print('Opening Instagram for ${match.fullName}. Instagram: ${match.instagramUsername}, University: ${match.university}');
    
    if (match.instagramUsername != null && match.instagramUsername!.isNotEmpty) {
      final instagramUrl = 'https://instagram.com/${match.instagramUsername}';
      _launchURL(instagramUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${match.fullName}\'s Instagram not available'),
          action: SnackBarAction(
            label: 'Add Manually',
            onPressed: () {
              _showInstagramInputDialog(match);
            },
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
  
  void _showInstagramInputDialog(UserProfile match) {
    final brightness = Theme.of(context).brightness;
    final TextEditingController _controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: brightness == Brightness.dark ? Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Add ${match.fullName}\'s Instagram',
            style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
          content: TextField(
            controller: _controller,
            style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Enter Instagram username',
              hintStyle: TextStyle(color: brightness == Brightness.dark ? Colors.white54 : Colors.black54),
              prefixText: '@',
              prefixStyle: TextStyle(color: brightness == Brightness.dark ? Colors.white70 : Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: brightness == Brightness.dark ? Colors.white30 : Colors.black26),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_controller.text.isNotEmpty) {
                  final instagramUrl = 'https://instagram.com/${_controller.text.trim()}';
                  _launchURL(instagramUrl);
                }
              },
              child: Text(
                'Open',
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Instagram'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool _hasAnyPreferences(UserProfile match) {
    return match.cleanlinessLevel != null ||
        match.sleepTime != null ||
        match.wakeTime != null ||
        match.smokingPreference != null ||
        match.drinkingPreference != null ||
        match.petPreference != null ||
        match.musicPreference != null ||
        match.socialPreference != null ||
        (match.guestPolicy != null && match.guestPolicy!.isNotEmpty) ||
        (match.roomTypePreference != null && match.roomTypePreference!.isNotEmpty) ||
        (match.religiousPreference != null && match.religiousPreference!.isNotEmpty) ||
        (match.dietaryRestrictions != null && match.dietaryRestrictions!.isNotEmpty) ||
        match.budgetRange != null;
  }
  
  String _formatSleepSchedule(String? sleepTime, String? wakeTime) {
    String schedule = '';
    if (sleepTime != null && sleepTime.isNotEmpty) {
      schedule += 'Sleep: $sleepTime';
    }
    if (wakeTime != null && wakeTime.isNotEmpty) {
      if (schedule.isNotEmpty) {
        schedule += ' • ';
      }
      schedule += 'Wake: $wakeTime';
    }
    return schedule.isNotEmpty ? schedule : 'Not specified';
  }
  
  String _capitalizeSocialPreference(String value) {
    if (value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1);
  }
  
  Widget _buildPreferenceItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryBlue,
          size: 18,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom painter for the compatibility wheel
class CompatibilityWheelPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;

  CompatibilityWheelPainter({
    required this.percentage,
    this.strokeWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = _getCompatibilityColor(percentage)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2, // Start from top
      progressAngle,
      false,
      progressPaint,
    );
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 70) return Color(0xFF2ECC71); // Green
    if (score >= 50) return Color(0xFFFFB74D); // Orange
    return Color(0xFFFF6B6B); // Red
  }

  @override
  bool shouldRepaint(CompatibilityWheelPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.strokeWidth != strokeWidth;
  }
}

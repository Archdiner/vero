import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/themes.dart'; // Import the theme system

class DetailedProfileView extends StatelessWidget {
  final UserProfile userProfile;
  final Widget? actionButtons;
  final Function(String)? onInstagramTap;

  const DetailedProfileView({
    Key? key,
    required this.userProfile,
    this.actionButtons,
    this.onInstagramTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine brightness and define our text colors
    final brightness = Theme.of(context).brightness;
    final primaryTextColor = brightness == Brightness.dark ? Colors.white : Colors.black;
    final secondaryTextColor = brightness == Brightness.dark ? Colors.white70 : Colors.black54;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      userProfile.profilePicture.isNotEmpty
                          ? userProfile.profilePicture
                          : 'https://via.placeholder.com/150?text=No+Image',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            color: brightness == Brightness.dark ? Colors.white54 : Colors.black45,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name, age, university details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${userProfile.fullName}, ${userProfile.age}",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProfile.university ?? 'Unknown University',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                        if (userProfile.yearOfStudy != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Year ${userProfile.yearOfStudy}",
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (userProfile.major != null && userProfile.major!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            userProfile.major!,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        // Display compatibility score
                        if (userProfile.compatibilityScore != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: AppColors.primaryBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${userProfile.compatibilityScore!.toInt()}% Compatible',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Bio section
              if (userProfile.bio != null && userProfile.bio!.isNotEmpty) ...[
                Text(
                  "About Me",
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userProfile.bio!,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Contact Options
              if (userProfile.instagramUsername != null && userProfile.instagramUsername!.isNotEmpty) ...[
                Text(
                  "Contact Options",
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Instagram option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.photo_camera,
                    color: AppColors.primaryBlue,
                  ),
                  title: Text(
                    'Instagram',
                    style: TextStyle(color: primaryTextColor),
                  ),
                  subtitle: Text(
                    '@${userProfile.instagramUsername}',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  onTap: () {
                    if (onInstagramTap != null) {
                      onInstagramTap!(userProfile.instagramUsername!);
                    } else {
                      _launchInstagram(userProfile.instagramUsername!, context);
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
              
              // Action buttons (like/dislike or unmatch)
              if (actionButtons != null) actionButtons!,
              
              // Preferences & Lifestyle section - only show if we have at least some preference data
              if (_hasAnyPreferenceData(userProfile)) ...[
                const SizedBox(height: 24),
                Text(
                  "Preferences & Lifestyle",
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Display available preferences
                if (userProfile.cleanlinessLevel != null)
                  _buildPreferenceItem(
                    'Cleanliness Level',
                    '${userProfile.cleanlinessLevel}/10',
                    Icons.cleaning_services,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.cleanlinessLevel != null)
                  const SizedBox(height: 12),
                
                if (userProfile.sleepTime != null || userProfile.wakeTime != null)
                  _buildPreferenceItem(
                    'Sleep Schedule',
                    _formatSleepSchedule(userProfile.sleepTime, userProfile.wakeTime),
                    Icons.bedtime,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.sleepTime != null || userProfile.wakeTime != null)
                  const SizedBox(height: 12),
                
                if (userProfile.smokingPreference != null)
                  _buildPreferenceItem(
                    'Smoking',
                    userProfile.smokingPreference! ? 'Smoker' : 'Non-smoker',
                    Icons.smoking_rooms,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.smokingPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.drinkingPreference != null)
                  _buildPreferenceItem(
                    'Drinking',
                    userProfile.drinkingPreference! ? 'Drinker' : 'Non-drinker',
                    Icons.local_bar,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.drinkingPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.petPreference != null)
                  _buildPreferenceItem(
                    'Pets',
                    userProfile.petPreference! ? 'Pet friendly' : 'No pets',
                    Icons.pets,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.petPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.musicPreference != null)
                  _buildPreferenceItem(
                    'Music',
                    userProfile.musicPreference! ? 'Enjoys music' : 'Prefers quiet',
                    Icons.music_note,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.musicPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.socialPreference != null)
                  _buildPreferenceItem(
                    'Social Type',
                    _capitalizeSocialPreference(userProfile.socialPreference!),
                    Icons.people,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.socialPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.guestPolicy != null && userProfile.guestPolicy!.isNotEmpty)
                  _buildPreferenceItem(
                    'Guest Policy',
                    userProfile.guestPolicy!,
                    Icons.group_add,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.guestPolicy != null && userProfile.guestPolicy!.isNotEmpty)
                  const SizedBox(height: 12),
                
                if (userProfile.roomTypePreference != null && userProfile.roomTypePreference!.isNotEmpty)
                  _buildPreferenceItem(
                    'Room Type',
                    userProfile.roomTypePreference!,
                    Icons.bedroom_parent,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.roomTypePreference != null && userProfile.roomTypePreference!.isNotEmpty)
                  const SizedBox(height: 12),
                
                if (userProfile.religiousPreference != null && userProfile.religiousPreference!.isNotEmpty)
                  _buildPreferenceItem(
                    'Religious Preference',
                    userProfile.religiousPreference!,
                    Icons.church,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.religiousPreference != null && userProfile.religiousPreference!.isNotEmpty)
                  const SizedBox(height: 12),
                
                if (userProfile.dietaryRestrictions != null && userProfile.dietaryRestrictions!.isNotEmpty)
                  _buildPreferenceItem(
                    'Dietary Restrictions',
                    userProfile.dietaryRestrictions!,
                    Icons.restaurant,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                if (userProfile.dietaryRestrictions != null && userProfile.dietaryRestrictions!.isNotEmpty)
                  const SizedBox(height: 12),
                
                if (userProfile.budgetRange != null)
                  _buildPreferenceItem(
                    'Budget',
                    '\$${userProfile.budgetRange}',
                    Icons.attach_money,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to check if the profile has any preference data to display
  bool _hasAnyPreferenceData(UserProfile profile) {
    return profile.cleanlinessLevel != null ||
        profile.sleepTime != null ||
        profile.wakeTime != null ||
        profile.smokingPreference != null ||
        profile.drinkingPreference != null ||
        profile.petPreference != null ||
        profile.musicPreference != null ||
        profile.socialPreference != null ||
        (profile.guestPolicy != null && profile.guestPolicy!.isNotEmpty) ||
        (profile.roomTypePreference != null && profile.roomTypePreference!.isNotEmpty) ||
        (profile.religiousPreference != null && profile.religiousPreference!.isNotEmpty) ||
        (profile.dietaryRestrictions != null && profile.dietaryRestrictions!.isNotEmpty) ||
        profile.budgetRange != null;
  }
  
  // Helper method to format sleep and wake times
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
  
  // Helper method to capitalize social preference
  String _capitalizeSocialPreference(String value) {
    if (value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1);
  }
  
  // Helper method to build a preference item
  Widget _buildPreferenceItem(String label, String value, IconData icon, Color primaryTextColor, Color secondaryTextColor) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryBlue,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: primaryTextColor,
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
  
  // Helper method to launch Instagram
  void _launchInstagram(String username, BuildContext context) async {
    try {
      final instagramUrl = 'https://instagram.com/$username';
      final Uri uri = Uri.parse(instagramUrl);
      
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $instagramUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Instagram'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

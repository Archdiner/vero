import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'package:url_launcher/url_launcher.dart';

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
                          color: Colors.grey[800],
                          child: const Icon(Icons.person, color: Colors.white54, size: 40),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProfile.university ?? 'Unknown University',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        if (userProfile.yearOfStudy != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Year ${userProfile.yearOfStudy}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (userProfile.major != null && userProfile.major!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            userProfile.major!,
                            style: const TextStyle(
                              color: Colors.white70,
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
                                color: Color(0xFFFF6F40),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${userProfile.compatibilityScore!.toInt()}% Compatible',
                                style: const TextStyle(
                                  color: Color(0xFFFF6F40),
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
                const Text(
                  "About Me",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userProfile.bio!,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 24),
              ],
              
              // Contact Options
              if (userProfile.instagramUsername != null && userProfile.instagramUsername!.isNotEmpty) ...[
                const Text(
                  "Contact Options",
                  style: TextStyle(
                    color: Colors.white,
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
                    color: Color(0xFFFF6F40),
                  ),
                  title: const Text(
                    'Instagram',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '@${userProfile.instagramUsername}',
                    style: const TextStyle(color: Colors.white70),
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
                const Text(
                  "Preferences & Lifestyle",
                  style: TextStyle(
                    color: Colors.white,
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
                  ),
                  
                if (userProfile.cleanlinessLevel != null)
                  const SizedBox(height: 12),
                
                if (userProfile.sleepTime != null || userProfile.wakeTime != null)
                  _buildPreferenceItem(
                    'Sleep Schedule',
                    _formatSleepSchedule(userProfile.sleepTime, userProfile.wakeTime),
                    Icons.bedtime,
                  ),
                  
                if (userProfile.sleepTime != null || userProfile.wakeTime != null)
                  const SizedBox(height: 12),
                
                if (userProfile.smokingPreference != null)
                  _buildPreferenceItem(
                    'Smoking',
                    userProfile.smokingPreference! ? 'Smoker' : 'Non-smoker',
                    Icons.smoking_rooms,
                  ),
                  
                if (userProfile.smokingPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.drinkingPreference != null)
                  _buildPreferenceItem(
                    'Drinking',
                    userProfile.drinkingPreference! ? 'Drinker' : 'Non-drinker',
                    Icons.local_bar,
                  ),
                  
                if (userProfile.drinkingPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.petPreference != null)
                  _buildPreferenceItem(
                    'Pets',
                    userProfile.petPreference! ? 'Pet friendly' : 'No pets',
                    Icons.pets,
                  ),
                  
                if (userProfile.petPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.musicPreference != null)
                  _buildPreferenceItem(
                    'Music',
                    userProfile.musicPreference! ? 'Enjoys music' : 'Prefers quiet',
                    Icons.music_note,
                  ),
                  
                if (userProfile.musicPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.socialPreference != null)
                  _buildPreferenceItem(
                    'Social Type',
                    _capitalizeSocialPreference(userProfile.socialPreference!),
                    Icons.people,
                  ),
                  
                if (userProfile.socialPreference != null)
                  const SizedBox(height: 12),
                
                if (userProfile.guestPolicy != null && userProfile.guestPolicy!.isNotEmpty)
                  _buildPreferenceItem(
                    'Guest Policy',
                    userProfile.guestPolicy!,
                    Icons.group_add,
                  ),
                  
                if (userProfile.guestPolicy != null && userProfile.guestPolicy!.isNotEmpty)
                  const SizedBox(height: 12),
                
                if (userProfile.roomTypePreference != null && userProfile.roomTypePreference!.isNotEmpty)
                  _buildPreferenceItem(
                    'Room Type',
                    userProfile.roomTypePreference!,
                    Icons.bedroom_parent,
                  ),
                  
                if (userProfile.roomTypePreference != null && userProfile.roomTypePreference!.isNotEmpty)
                  const SizedBox(height: 12),
                
                if (userProfile.religiousPreference != null && userProfile.religiousPreference!.isNotEmpty)
                  _buildPreferenceItem(
                    'Religious Preference',
                    userProfile.religiousPreference!,
                    Icons.church,
                  ),
                  
                if (userProfile.religiousPreference != null && userProfile.religiousPreference!.isNotEmpty)
                  const SizedBox(height: 12),
                
                if (userProfile.dietaryRestrictions != null && userProfile.dietaryRestrictions!.isNotEmpty)
                  _buildPreferenceItem(
                    'Dietary Restrictions',
                    userProfile.dietaryRestrictions!,
                    Icons.restaurant,
                  ),
                  
                if (userProfile.dietaryRestrictions != null && userProfile.dietaryRestrictions!.isNotEmpty)
                  const SizedBox(height: 12),
                
                if (userProfile.budgetRange != null)
                  _buildPreferenceItem(
                    'Budget',
                    '\$${userProfile.budgetRange}',
                    Icons.attach_money,
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
  Widget _buildPreferenceItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF6F40),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
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
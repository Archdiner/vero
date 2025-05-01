import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/themes.dart'; // Import the theme system

class DetailedProfileView extends StatelessWidget {
  final UserProfile userProfile;
  final Function(String) onInstagramTap;
  final Widget? actionButtons;

  const DetailedProfileView({
    Key? key,
    required this.userProfile,
    required this.onInstagramTap,
    this.actionButtons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A24),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Profile content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // Header with image and basic info
                    _buildProfileHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // About Me section
                    if (userProfile.bio != null && userProfile.bio!.isNotEmpty)
                      _buildSection(
                        title: 'About Me',
                        icon: Icons.person_outline,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            userProfile.bio!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Preferences & Lifestyle section
                    _buildSection(
                      title: 'Preferences & Lifestyle',
                      icon: Icons.settings_outlined,
                      child: Column(
                        children: [
                          // Cleanliness Level
                          if (userProfile.cleanlinessLevel != null)
                            _buildPreferenceItem(
                              icon: Icons.cleaning_services_outlined,
                              title: 'Cleanliness Level',
                              value: '${userProfile.cleanlinessLevel}/10',
                              color: _getScoreColor(userProfile.cleanlinessLevel! / 10),
                            ),

                          // Sleep Schedule
                          if (userProfile.sleepTime != null && userProfile.wakeTime != null)
                            _buildPreferenceItem(
                              icon: Icons.bedtime_outlined,
                              title: 'Sleep Schedule',
                              value: 'Sleep: ${userProfile.sleepTime} • Wake: ${userProfile.wakeTime}',
                              color: Colors.blue[300]!,
                            ),

                          // Smoking
                          if (userProfile.smokingPreference != null)
                            _buildPreferenceItem(
                              icon: Icons.smoke_free,
                              title: 'Smoking',
                              value: userProfile.smokingPreference! ? 'Yes' : 'No',
                              color: Colors.red[300]!,
                            ),

                          // Drinking
                          if (userProfile.drinkingPreference != null)
                            _buildPreferenceItem(
                              icon: Icons.local_bar_outlined,
                              title: 'Drinking',
                              value: userProfile.drinkingPreference! ? 'Yes' : 'No',
                              color: Colors.amber[300]!,
                            ),

                          // Pets
                          if (userProfile.petPreference != null)
                            _buildPreferenceItem(
                              icon: Icons.pets_outlined,
                              title: 'Pets',
                              value: userProfile.petPreference! ? 'Yes' : 'No',
                              color: Colors.orange[300]!,
                            ),

                          // Guest Policy
                          if (userProfile.guestPolicy != null)
                            _buildPreferenceItem(
                              icon: Icons.group_outlined,
                              title: 'Guest Policy',
                              value: userProfile.guestPolicy!,
                              color: Colors.purple[300]!,
                            ),

                          // Room Type
                          if (userProfile.roomTypePreference != null)
                            _buildPreferenceItem(
                              icon: Icons.door_front_door_outlined,
                              title: 'Room Type',
                              value: userProfile.roomTypePreference!,
                              color: Colors.green[300]!,
                            ),

                          // Budget Range
                          if (userProfile.budgetRange != null)
                            _buildPreferenceItem(
                              icon: Icons.attach_money,
                              title: 'Budget Range',
                              value: '\$${userProfile.budgetRange}',
                              color: Colors.teal[300]!,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Social Media section
                    if (userProfile.instagramUsername != null && userProfile.instagramUsername!.isNotEmpty)
                      _buildSection(
                        title: 'Social Media',
                        icon: Icons.share_outlined,
                        child: _buildSocialButton(
                          icon: Icons.camera_alt_outlined,
                          label: '@${userProfile.instagramUsername}',
                          onTap: () => onInstagramTap(userProfile.instagramUsername!),
                        ),
                      ),

                    if (actionButtons != null) ...[
                      const SizedBox(height: 24),
                      actionButtons!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: AppColors.primaryBlue,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.network(
              userProfile.profilePicture,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.person,
                size: 60,
                color: Colors.white54,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Name and Age
        Text(
          '${userProfile.fullName}, ${userProfile.age}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // University and Year
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    userProfile.university,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (userProfile.yearOfStudy != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Year ${userProfile.yearOfStudy}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Compatibility Score
        if (userProfile.compatibilityScore != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white24,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite,
                  color: _getScoreColor(userProfile.compatibilityScore! / 100),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${userProfile.compatibilityScore!.toInt()}% Compatible',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.pink[300],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return const Color(0xFF4CAF50); // Green
    if (score >= 0.5) return const Color(0xFFFFA726); // Orange
    return const Color(0xFFEF5350); // Red
  }
}

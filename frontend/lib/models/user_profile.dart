class UserProfile {
  final String id;
  final String fullName;
  final int age;
  final String profilePicture;
  final String university;
  final String? major;
  final int? yearOfStudy;
  final int? budgetRange;
  final String? gender;
  final String? socialPreference;
  final int? cleanlinessLevel;
  final bool? smokingPreference;
  final bool? drinkingPreference;
  final bool? petPreference;
  final bool? musicPreference;
  final String? bio;
  final String? instagramUsername;
  final String? sleepTime;
  final String? wakeTime;
  final String? guestPolicy;
  final String? roomTypePreference;
  final String? religiousPreference;
  final String? dietaryRestrictions;
  bool isLiked;
  
  // Match-related fields
  final double? compatibilityScore;
  final String? matchedAt; // ISO 8601 timestamp string when matched
  final String? matchStatus; // Enum string from the database: 'matched', 'pending', etc.
  
  UserProfile({
    required this.id,
    required this.fullName,
    required this.age,
    required this.profilePicture,
    required this.university,
    this.major,
    this.yearOfStudy,
    this.budgetRange,
    this.gender,
    this.socialPreference,
    this.cleanlinessLevel,
    this.smokingPreference,
    this.drinkingPreference,
    this.petPreference,
    this.musicPreference,
    this.bio,
    this.instagramUsername,
    this.sleepTime,
    this.wakeTime,
    this.guestPolicy,
    this.roomTypePreference,
    this.religiousPreference,
    this.dietaryRestrictions,
    this.isLiked = false,
    this.compatibilityScore,
    this.matchedAt,
    this.matchStatus,
  });
  
  // Create a UserProfile from JSON data
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Convert id to String if it's an int
    var userId = json['id'];
    if (userId is int) {
      userId = userId.toString();
    } else if (userId == null) {
      userId = '';
    }
    
    // Format sleep_time and wake_time if provided in raw format
    String? sleepTimeFormatted;
    String? wakeTimeFormatted;
    
    if (json['sleep_time'] != null) {
      if (json['sleep_time'] is String) {
        sleepTimeFormatted = json['sleep_time'];
      } else {
        try {
          final time = DateTime.parse(json['sleep_time'].toString());
          sleepTimeFormatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          sleepTimeFormatted = json['sleep_time'].toString();
        }
      }
    }
    
    if (json['wake_time'] != null) {
      if (json['wake_time'] is String) {
        wakeTimeFormatted = json['wake_time'];
      } else {
        try {
          final time = DateTime.parse(json['wake_time'].toString());
          wakeTimeFormatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          wakeTimeFormatted = json['wake_time'].toString();
        }
      }
    }
    
    return UserProfile(
      id: userId,
      fullName: json['fullname'] ?? 'No Name',
      age: json['age'] ?? 0,
      profilePicture: json['profile_picture'] ?? '',
      university: json['university'] ?? 'Unknown University',
      major: json['major'],
      yearOfStudy: json['year_of_study'],
      budgetRange: json['budget_range'],
      gender: json['gender'],
      socialPreference: json['social_preference'],
      cleanlinessLevel: json['cleanliness_level'],
      smokingPreference: json['smoking_preference'],
      drinkingPreference: json['drinking_preference'],
      petPreference: json['pet_preference'],
      musicPreference: json['music_preference'],
      bio: json['bio'],
      // Check both field names since backend uses 'instagram' but we use 'instagramUsername'
      instagramUsername: json['instagram_username'] ?? json['instagram'],
      sleepTime: sleepTimeFormatted,
      wakeTime: wakeTimeFormatted,
      guestPolicy: json['guest_policy'],
      roomTypePreference: json['room_type_preference'],
      religiousPreference: json['religious_preference'],
      dietaryRestrictions: json['dietary_restrictions'],
      isLiked: json['is_liked'] ?? false,
      // Match-related fields from the roommate_matches table
      compatibilityScore: json['compatibility_score'] != null 
          ? (json['compatibility_score'] is int 
              ? json['compatibility_score'].toDouble() 
              : json['compatibility_score'])
          : null,
      matchedAt: json['created_at'],
      matchStatus: json['match_status'],
    );
  }
  
  // Convert UserProfile to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullName,
      'age': age,
      'profile_picture': profilePicture,
      'university': university,
      'major': major,
      'year_of_study': yearOfStudy,
      'budget_range': budgetRange,
      'gender': gender,
      'social_preference': socialPreference,
      'cleanliness_level': cleanlinessLevel,
      'smoking_preference': smokingPreference,
      'drinking_preference': drinkingPreference,
      'pet_preference': petPreference,
      'music_preference': musicPreference,
      'bio': bio,
      'instagram': instagramUsername, // Use 'instagram' for backend compatibility
      'sleep_time': sleepTime,
      'wake_time': wakeTime,
      'guest_policy': guestPolicy,
      'room_type_preference': roomTypePreference,
      'religious_preference': religiousPreference,
      'dietary_restrictions': dietaryRestrictions,
      'is_liked': isLiked,
      'compatibility_score': compatibilityScore,
      'created_at': matchedAt,
      'match_status': matchStatus,
    };
  }
  
  // Helper method to get social preference display text
  String getSocialPreferenceText() {
    switch (socialPreference) {
      case 'introvert':
        return 'Introvert';
      case 'extrovert':
        return 'Extrovert';
      case 'ambivert':
        return 'Ambivert';
      default:
        return 'Unknown';
    }
  }
  
  // Helper method to format budget
  String getBudgetText() {
    if (budgetRange == null) return 'Budget: Unknown';
    return 'Budget: \$${budgetRange}/month';
  }
  
  // Helper method to format cleanliness level
  String getCleanlinessText() {
    if (cleanlinessLevel == null) return 'Cleanliness: Unknown';
    return 'Cleanliness: ${cleanlinessLevel}/10';
  }
  
  // Helper method to format lifestyle preferences
  List<String> getLifestyleTags() {
    List<String> tags = [];
    
    if (smokingPreference == true) tags.add('Smoking OK');
    if (drinkingPreference == true) tags.add('Drinking OK');
    if (petPreference == true) tags.add('Pet Friendly');
    if (musicPreference == true) tags.add('Music: Speakers');
    else if (musicPreference == false) tags.add('Music: Headphones');
    
    return tags;
  }
} 
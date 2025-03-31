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
  bool isLiked;
  
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
    this.isLiked = false,
  });
  
  // Create a UserProfile from JSON data
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
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
      isLiked: json['is_liked'] ?? false,
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
      'is_liked': isLiked,
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
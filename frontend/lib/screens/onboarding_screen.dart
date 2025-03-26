import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart' as utils;
import '../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Controllers for onboarding fields
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController profilePictureController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  final TextEditingController majorController = TextEditingController();
  final TextEditingController yearOfStudyController = TextEditingController();
  final TextEditingController budgetRangeController = TextEditingController();
  final TextEditingController moveInDateController = TextEditingController();
  final TextEditingController cleanlinessLevelController =
      TextEditingController();
  final TextEditingController mealScheduleController = TextEditingController();
  final TextEditingController socialPreferenceController =
      TextEditingController();
  final TextEditingController snapchatController = TextEditingController();
  final TextEditingController bedtimeController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  String? selectedGender;
  bool smokingPreference = false;
  bool drinkingPreference = false;
  bool petPreference = false;

  bool _isLoading = false;

  Future<void> updateOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    // Retrieve the access token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    final url = '${utils.BASE_URL}/onboarding';

    // Helper function to parse int from string
    int? parseIntOrNull(String value) {
      value = value.trim();
      return value.isEmpty ? null : int.tryParse(value);
    }

    // Process text values
    final instagramValue = instagramController.text.trim();
    final profilePictureValue = profilePictureController.text.trim();
    final universityValue = universityController.text.trim();
    final majorValue = majorController.text.trim();
    final mealScheduleValue = mealScheduleController.text.trim();
    final socialPreferenceValue = socialPreferenceController.text.trim();
    final snapchatValue = snapchatController.text.trim();
    final bedtimeValue = bedtimeController.text.trim();
    final phoneNumberValue = phoneNumberController.text.trim();
    final moveInDateValue = moveInDateController.text.trim();

    // Build the request body
    final body = json.encode({
      "instagram": instagramValue.isEmpty ? null : instagramValue,
      "profile_picture": profilePictureValue.isEmpty ? null : profilePictureValue,
      "age": parseIntOrNull(ageController.text),
      "gender": selectedGender,  // Already null if not selected
      "university": universityValue.isEmpty ? null : universityValue,
      "major": majorValue.isEmpty ? null : majorValue,
      "year_of_study": parseIntOrNull(yearOfStudyController.text),
      "budget_range": parseIntOrNull(budgetRangeController.text),
      "move_in_date": moveInDateValue.isEmpty ? null : moveInDateValue,
      "smoking_preference": smokingPreference,
      "drinking_preference": drinkingPreference,
      "pet_preference": petPreference,
      "cleanliness_level": parseIntOrNull(cleanlinessLevelController.text),
      "meal_schedule": mealScheduleValue.isEmpty ? null : mealScheduleValue,
      "social_preference": socialPreferenceValue.isEmpty ? null : socialPreferenceValue,
      "snapchat": snapchatValue.isEmpty ? null : snapchatValue,
      "bedtime": bedtimeValue.isEmpty ? null : bedtimeValue,
      "phone_number": phoneNumberValue.isEmpty ? null : phoneNumberValue,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // Mark onboarding as completed
        final authService = AuthService();
        await authService.markOnboardingCompleted();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Onboarding completed successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to swipe screen
        Navigator.pushReplacementNamed(context, '/swipe');
      } else {
        final responseBody = json.decode(response.body);
        final errorMsg = responseBody['detail'] ?? 'Failed to update onboarding data';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    instagramController.dispose();
    profilePictureController.dispose();
    ageController.dispose();
    universityController.dispose();
    majorController.dispose();
    yearOfStudyController.dispose();
    budgetRangeController.dispose();
    moveInDateController.dispose();
    cleanlinessLevelController.dispose();
    mealScheduleController.dispose();
    socialPreferenceController.dispose();
    snapchatController.dispose();
    bedtimeController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Onboarding',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Add some extra padding so the fields are not clipped at the bottom
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Welcome!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24, // H5-ish
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Just a few more questions to help personalize your experience",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18, // H3-ish (though typically H3 is larger than H5)
                ),
              ),
              const SizedBox(height: 32),

              // Instagram field
              TextField(
                controller: instagramController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Instagram',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Profile Picture URL
              TextField(
                controller: profilePictureController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Profile Picture URL',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Age field
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Age',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // University field
              TextField(
                controller: universityController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'University',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Major field
              TextField(
                controller: majorController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Major',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Year of Study field
              TextField(
                controller: yearOfStudyController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Year of Study',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Budget Range field
              TextField(
                controller: budgetRangeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Budget Range',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Move In Date with DatePicker
              TextField(
                controller: moveInDateController,
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Move In Date',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    moveInDateController.text = pickedDate.toIso8601String();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Smoking Preference switch
              SwitchListTile(
                title: const Text(
                  'Smoking Preference',
                  style: TextStyle(color: Colors.white),
                ),
                value: smokingPreference,
                onChanged: (val) {
                  setState(() {
                    smokingPreference = val;
                  });
                },
              ),

              // Drinking Preference switch
              SwitchListTile(
                title: const Text(
                  'Drinking Preference',
                  style: TextStyle(color: Colors.white),
                ),
                value: drinkingPreference,
                onChanged: (val) {
                  setState(() {
                    drinkingPreference = val;
                  });
                },
              ),

              // Pet Preference switch
              SwitchListTile(
                title: const Text(
                  'Pet Preference',
                  style: TextStyle(color: Colors.white),
                ),
                value: petPreference,
                onChanged: (val) {
                  setState(() {
                    petPreference = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Cleanliness Level field
              TextField(
                controller: cleanlinessLevelController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Cleanliness Level (1-10)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Meal Schedule field
              TextField(
                controller: mealScheduleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Meal Schedule',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Social Preference field
              TextField(
                controller: socialPreferenceController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Social Preference',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Snapchat field
              TextField(
                controller: snapchatController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Snapchat',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bedtime with TimePicker
              TextField(
                controller: bedtimeController,
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Bedtime',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    // Format time as HH:mm for Pydantic parsing
                    final hours = pickedTime.hour.toString().padLeft(2, '0');
                    final minutes = pickedTime.minute.toString().padLeft(2, '0');
                    bedtimeController.text = "$hours:$minutes";
                  }
                },
              ),
              const SizedBox(height: 16),

              // Phone Number field
              TextField(
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : updateOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Finish Onboarding',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

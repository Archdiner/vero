import 'dart:convert';
import 'dart:math';
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
  // Page controller for multi-stage onboarding
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  bool _isLoading = false;
  
  // Progress indicators
  final int _totalPages = 4;
  final List<String> _pageHeaders = [
    'Basic Information',
    'Education Details',
    'Living Preferences',
    'Contact Information'
  ];

  // Form keys for validation
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  // Controllers for onboarding fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _profilePictureController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _budgetRangeController = TextEditingController();
  final TextEditingController _moveInDateController = TextEditingController();
  final TextEditingController _cleanlinessLevelController = TextEditingController();
  final TextEditingController _snapchatController = TextEditingController();
  final TextEditingController _bedtimeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Drop-down values
  String? _selectedGender;
  String? _selectedUniversity;
  String? _selectedYearOfStudy;
  String? _selectedSocialPreference;
  
  // Slider value for budget
  double _budgetValue = 1500.0;
  double _cleanlinessValue = 5.0;

  // Preference booleans
  bool _smokingPreference = false;
  bool _drinkingPreference = false;
  bool _petPreference = false;

  @override
  void initState() {
    super.initState();
    _budgetRangeController.text = _budgetValue.toInt().toString();
    // Set empty strings for email and name controllers since they'll be fetched from the profile API
    _emailController.text = '';
    _nameController.text = '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _instagramController.dispose();
    _profilePictureController.dispose();
    _ageController.dispose();
    _majorController.dispose();
    _budgetRangeController.dispose();
    _moveInDateController.dispose();
    _cleanlinessLevelController.dispose();
    _snapchatController.dispose();
    _bedtimeController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateOnboarding() async {
    // Check if all required fields are filled
    if (!_validateRequiredFields()) {
      // Create a more descriptive error message
      List<String> missingFields = [];
      
      if (_instagramController.text.isEmpty) missingFields.add('Instagram Username');
      if (_profilePictureController.text.isEmpty) missingFields.add('Profile Picture URL');
      if (_ageController.text.isEmpty) missingFields.add('Age');
      if (_selectedGender == null) missingFields.add('Gender');
      if (_selectedUniversity == null) missingFields.add('University');
      if (_selectedYearOfStudy == null) missingFields.add('Year of Study');
      if (_cleanlinessLevelController.text.isEmpty) missingFields.add('Cleanliness Level');
      if (_selectedSocialPreference == null) missingFields.add('Social Preference');
      
      String errorMessage = "Please fill in the following required fields: ${missingFields.join(', ')}";
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Retrieve the access token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    print('Onboarding: Using token: ${token.isEmpty ? "EMPTY" : token.substring(0, 10) + "..."}');

    // Get user profile to retrieve email and fullname
    String? emailValue;
    String? nameValue;
    
    try {
      final profileUrl = '${utils.BASE_URL}/profile';
      print('Onboarding: Fetching user profile from: $profileUrl');
      
      final profileResponse = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        emailValue = profileData['email'];
        nameValue = profileData['fullname'];
        print('Onboarding: Successfully fetched user profile. Email: $emailValue, Name: $nameValue');
      } else {
        print('Onboarding: Failed to fetch user profile. Status: ${profileResponse.statusCode}');
        // Use empty values if profile fetch fails
        emailValue = '';
        nameValue = '';
      }
    } catch (e) {
      print('Onboarding: Error fetching user profile: $e');
      // Use empty values if profile fetch fails
      emailValue = '';
      nameValue = '';
    }

    final url = '${utils.BASE_URL}/onboarding';
    print('Onboarding: Making request to: $url');

    // Helper function to parse int from string
    int? parseIntOrNull(String value) {
      value = value.trim();
      return value.isEmpty ? null : int.tryParse(value);
    }

    // Process text values
    final instagramValue = _instagramController.text.trim();
    final profilePictureValue = _profilePictureController.text.trim();
    final moveInDateValue = _moveInDateController.text.trim();
    final snapchatValue = _snapchatController.text.trim();
    final bedtimeValue = _bedtimeController.text.trim();
    final phoneNumberValue = _phoneNumberController.text.trim();
    final bioValue = _bioController.text.trim();

    // Map social preference from UI to backend enum
    String? socialPreferenceBackendValue;
    if (_selectedSocialPreference == 'Introvert') {
      socialPreferenceBackendValue = 'introvert';
    } else if (_selectedSocialPreference == 'Extrovert') {
      socialPreferenceBackendValue = 'extrovert';
    } else if (_selectedSocialPreference == 'Ambivert') {
      socialPreferenceBackendValue = 'ambivert';
    }

    // Map gender from UI to backend enum
    String? genderBackendValue;
    if (_selectedGender == 'Male') {
      genderBackendValue = 'male';
    } else if (_selectedGender == 'Female') {
      genderBackendValue = 'female';
    } else if (_selectedGender == 'Other') {
      genderBackendValue = 'other';
    }

    // Build the request body
    final body = json.encode({
      "email": emailValue,
      "fullname": nameValue,
      "instagram": instagramValue,
      "profile_picture": profilePictureValue,
      "age": parseIntOrNull(_ageController.text),
      "gender": genderBackendValue,
      "university": _selectedUniversity,
      "major": _majorController.text.isEmpty ? null : _majorController.text,
      "year_of_study": _selectedYearOfStudy != null ? int.parse(_selectedYearOfStudy!) : null,
      "budget_range": _budgetValue.toInt(),
      "move_in_date": moveInDateValue.isEmpty ? null : moveInDateValue,
      "smoking_preference": _smokingPreference,
      "drinking_preference": _drinkingPreference,
      "pet_preference": _petPreference,
      "cleanliness_level": parseIntOrNull(_cleanlinessLevelController.text),
      "social_preference": socialPreferenceBackendValue,
      "snapchat": snapchatValue.isEmpty ? null : snapchatValue,
      "bedtime": bedtimeValue.isEmpty ? null : bedtimeValue,
      "phone_number": phoneNumberValue.isEmpty ? null : phoneNumberValue,
      "bio": bioValue.isEmpty ? null : bioValue,
    });
    
    print('Onboarding: Request body: ${body.substring(0, min(100, body.length))}...');

    try {
      print('Onboarding: Sending request...');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('Onboarding: Received response with status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Onboarding: Success response body: ${response.body}');
        // Mark onboarding as completed
        final authService = AuthService();
        await authService.markOnboardingCompleted();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Welcome! Your profile has been set up successfully."),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to swipe screen
        Navigator.pushReplacementNamed(context, '/swipe');
      } else {
        final responseBody = json.decode(response.body);
        final errorMsg = responseBody['detail'] ?? 'Failed to update onboarding data';
        print('Onboarding: Error response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Onboarding: Exception during request: $e');
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

  bool _validateRequiredFields() {
    // Debug logging to identify which field fails validation
    final instagramValid = _instagramController.text.isNotEmpty;
    final profilePicValid = _profilePictureController.text.isNotEmpty;
    final ageValid = _ageController.text.isNotEmpty;
    final genderValid = _selectedGender != null;
    final universityValid = _selectedUniversity != null;
    final yearOfStudyValid = _selectedYearOfStudy != null;
    final cleanlinessValid = _cleanlinessLevelController.text.isNotEmpty;
    final socialPrefValid = _selectedSocialPreference != null;
    
    print('Validation results:');
    print('- Instagram: $instagramValid (${_instagramController.text})');
    print('- Profile Picture: $profilePicValid (${_profilePictureController.text})');
    print('- Age: $ageValid (${_ageController.text})');
    print('- Gender: $genderValid ($_selectedGender)');
    print('- University: $universityValid ($_selectedUniversity)');
    print('- Year of Study: $yearOfStudyValid ($_selectedYearOfStudy)');
    print('- Cleanliness: $cleanlinessValid (${_cleanlinessLevelController.text})');
    print('- Social Preference: $socialPrefValid ($_selectedSocialPreference)');
    
    // Check required fields based on the user's requirements
    return instagramValid &&
           profilePicValid &&
           ageValid &&
           genderValid &&
           universityValid &&
           yearOfStudyValid &&
           cleanlinessValid &&
           socialPrefValid;
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      // Validate current form before proceeding
      if (_formKeys[_currentPage].currentState?.validate() ?? false) {
        print('Successfully validated page ${_currentPage + 1}');
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        print('Failed to validate page ${_currentPage + 1}');
      }
    } else {
      // On last page, submit the form
      final isValid = _formKeys[_currentPage].currentState?.validate() ?? false;
      print('Last page validation result: $isValid');
      
      if (isValid && _validateRequiredFields()) {
        print('All validation passed, submitting form');
        _updateOnboarding();
      } else {
        print('Final validation failed, not submitting');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fill in all required fields"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Create Your Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _pageHeaders[_currentPage],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Step ${_currentPage + 1}/$_totalPages',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6F40)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildBasicInfoPage(),
                _buildEducationPage(),
                _buildLivingPreferencesPage(),
                _buildContactInfoPage(),
              ],
            ),
          ),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button (hidden on first page)
                _currentPage > 0
                    ? TextButton(
                        onPressed: _previousPage,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Back'),
                      )
                    : const SizedBox(width: 80),
                // Next/Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F40),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentPage == _totalPages - 1 ? 'Submit' : 'Next',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 1: Basic Information
  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Let\'s get to know you',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This information helps us create your profile',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Age field
            _buildRequiredTextField(
              controller: _ageController,
              label: 'Age',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Age is required';
                }
                final age = int.tryParse(value);
                if (age == null || age < 18 || age > 100) {
                  return 'Please enter a valid age (18-100)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Gender dropdown
            _buildRequiredDropdown(
              label: 'Gender',
              value: _selectedGender,
              items: const ['Male', 'Female', 'Other'],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your gender';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Profile Picture URL (moved from education page)
            _buildRequiredTextField(
              controller: _profilePictureController,
              label: 'Profile Picture URL',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Profile picture URL is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Bio field
            _buildTextField(
              controller: _bioController,
              label: 'Bio (Optional)',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Page 2: Education Details
  Widget _buildEducationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Education',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tell us about your academic background',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // University dropdown
            _buildRequiredDropdown(
              label: 'University',
              value: _selectedUniversity,
              items: const ['Columbia University', 'Cornell University'],
              onChanged: (value) {
                setState(() {
                  _selectedUniversity = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your university';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Major field
            _buildTextField(
              controller: _majorController,
              label: 'Major (Optional)',
            ),
            const SizedBox(height: 16),
            
            // Year of Study dropdown
            _buildRequiredDropdown(
              label: 'Year of Study',
              value: _selectedYearOfStudy,
              items: const ['1', '2', '3', '4', '5'],
              onChanged: (value) {
                setState(() {
                  _selectedYearOfStudy = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your year of study';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // Page 3: Living Preferences
  Widget _buildLivingPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Living Preferences',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Help us find your perfect roommate match',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Budget Range slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maximum Monthly Budget',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${_budgetValue.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Up to \$5000',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Slider(
                  value: _budgetValue,
                  min: 0,
                  max: 5000,
                  divisions: 50,
                  activeColor: const Color(0xFFFF6F40),
                  inactiveColor: Colors.grey[800],
                  onChanged: (value) {
                    setState(() {
                      _budgetValue = value;
                      _budgetRangeController.text = value.toInt().toString();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Move In Date with DatePicker
            _buildTextField(
              controller: _moveInDateController,
              label: 'Move In Date (Optional)',
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2025),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFFFF6F40),
                          onPrimary: Colors.white,
                          surface: Colors.grey,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    _moveInDateController.text = pickedDate.toIso8601String().split('T')[0];
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            
            // Cleanliness Level slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cleanliness Level',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_cleanlinessValue.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '1 (Very Messy) - 10 (Very Clean)',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Slider(
                  value: _cleanlinessValue,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFFFF6F40),
                  inactiveColor: Colors.grey[800],
                  onChanged: (value) {
                    setState(() {
                      _cleanlinessValue = value;
                      // Optionally update your controller if needed for the request body
                      _cleanlinessLevelController.text = value.toInt().toString();
                    });
                  },
                ),
              ],
),
            const SizedBox(height: 16),
            
            // Social Preference dropdown
            _buildRequiredDropdown(
              label: 'Social Preference',
              value: _selectedSocialPreference,
              items: const ['Introvert', 'Extrovert', 'Ambivert'],
              onChanged: (value) {
                setState(() {
                  _selectedSocialPreference = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your social preference';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Bedtime with TimePicker (moved from contact info)
            _buildTextField(
              controller: _bedtimeController,
              label: 'Typical Bedtime (Optional)',
              readOnly: true,
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFFFF6F40),
                          onPrimary: Colors.white,
                          surface: Colors.grey,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedTime != null) {
                  final hours = pickedTime.hour.toString().padLeft(2, '0');
                  final minutes = pickedTime.minute.toString().padLeft(2, '0');
                  setState(() {
                    _bedtimeController.text = "$hours:$minutes";
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            
            // Preference toggles
            const Text(
              'Lifestyle Preferences',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildToggleSwitch(
              title: 'Smoking Friendly',
              value: _smokingPreference,
              onChanged: (value) {
                setState(() {
                  _smokingPreference = value;
                });
              },
            ),
            _buildToggleSwitch(
              title: 'Drinking Friendly',
              value: _drinkingPreference,
              onChanged: (value) {
                setState(() {
                  _drinkingPreference = value;
                });
              },
            ),
            _buildToggleSwitch(
              title: 'Pet Friendly',
              value: _petPreference,
              onChanged: (value) {
                setState(() {
                  _petPreference = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Page 4: Contact Information
  Widget _buildContactInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'How potential roommates can reach you',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Instagram field (moved from education page)
            _buildRequiredTextField(
              controller: _instagramController,
              label: 'Instagram Username',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Instagram username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Snapchat field
            _buildTextField(
              controller: _snapchatController,
              label: 'Snapchat (Optional)',
            ),
            const SizedBox(height: 16),
            
            // Phone Number field
            _buildTextField(
              controller: _phoneNumberController,
              label: 'Phone Number (Optional)',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            
            // Final message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFFFF6F40), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Almost done!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Click Submit to complete your profile setup and start finding your perfect roommate match.',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for building UI components
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFF6F40)),
        ),
      ),
    );
  }

  Widget _buildRequiredTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    // Ensure there's a default validator if none is provided
    final finalValidator = validator ?? (value) {
      if (value == null || value.isEmpty) {
        return '$label is required';
      }
      return null;
    };
    
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      validator: finalValidator,
      decoration: InputDecoration(
        labelText: '$label *',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6F40)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        errorStyle: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildRequiredDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    String? hint,
  }) {
    // Ensure there's a default validator if none is provided
    final finalValidator = validator ?? (value) {
      if (value == null || value.isEmpty) {
        return '$label is required';
      }
      return null;
    };
    
    return DropdownButtonFormField<String>(
      value: value,
      validator: finalValidator,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: '$label *',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6F40)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        errorStyle: const TextStyle(color: Colors.red),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
    );
  }

  Widget _buildToggleSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        value: value,
        activeColor: const Color(0xFFFF6F40),
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

import 'dart:convert';
import '../utils/themes.dart'; // Import the theme system
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/config.dart' as utils;
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../widgets/furniture_pattern_background.dart';

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
  bool _isValidatingInstagram = false;
  
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
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _budgetRangeController = TextEditingController();
  final TextEditingController _cleanlinessLevelController = TextEditingController();
  final TextEditingController _snapchatController = TextEditingController();
  final TextEditingController _bedtimeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  // New controllers for enhanced matching
  final TextEditingController _wakeTimeController = TextEditingController();
  final TextEditingController _sleepTimeController = TextEditingController();

  // Validation patterns
  final RegExp _instagramRegExp = RegExp(r'^(?!.*\.\.)(?!.*\.$)[^\W][\w.]{0,29}$');
  final RegExp _snapchatRegExp = RegExp(r'^[a-zA-Z0-9._-]{3,15}$');
  final RegExp _phoneRegExp = RegExp(r'^\+?[0-9]{10,15}$');
  
  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Uint8List? _webImage; // For web platform
  String? _imageUrl;
  bool _isUploadingImage = false;

  // Drop-down values
  String? _selectedGender;
  String? _selectedUniversity;
  String? _selectedYearOfStudy;
  String? _selectedSocialPreference;
  String? _selectedMusicPreference;
  
  // New dropdown values for enhanced matching
  String? _selectedGuestPolicy;
  String? _selectedRoomType;
  String? _selectedReligiousPreference;
  String? _selectedDietaryRestriction;
  
  // Slider value for budget and cleanliness
  double _budgetValue = 1000.0;
  double _cleanlinessValue = 5.0;

  // Preference booleans
  bool _smokingPreference = false;
  bool _drinkingPreference = false;
  bool _petPreference = false;
  bool _musicPreference = false;

  // Validation methods
  String? _validateInstagram(String? value) {
    if (value == null || value.isEmpty) {
      return 'Instagram username is required';
    }
    
    // Basic format validation
    if (!_instagramRegExp.hasMatch(value)) {
      return 'Invalid Instagram username format';
    }
    
    // Advanced format rules
    if (value.contains('..') || value.endsWith('.')) {
      return 'Instagram username cannot contain consecutive periods or end with a period';
    }
    
    return null;
  }

  String? _validateSnapchat(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    if (!_snapchatRegExp.hasMatch(value)) {
      return 'Invalid Snapchat username format';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    if (!_phoneRegExp.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 17 || age > 100) {
      return 'Age must be between 17 and 100';
    }
    return null;
  }

  String? _validateCleanliness(String? value) {
    if (value == null || value.isEmpty) {
      return 'Cleanliness level is required';
    }
    final level = int.tryParse(value);
    if (level == null) {
      return 'Please enter a valid number';
    }
    if (level < 1 || level > 10) {
      return 'Level must be between 1 and 10';
    }
    return null;
  }

  String? _validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Time is required';
    }
    // Check if time is in the format HH:MM
    if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) {
      return 'Invalid time format (HH:MM)';
    }
    return null;
  }

  // Function to validate Instagram username against a real account
  Future<bool> _verifyInstagramAccount(String username) async {
    setState(() {
      _isValidatingInstagram = true;
    });
    
    try {
      // Option 1: Use a more reliable third-party API for Instagram validation
      // This is a mock call - you would replace this with a real API call
      final bool useThirdPartyApi = false; // Set to true if you have a third-party API
      
      if (useThirdPartyApi) {
        // Example using RapidAPI Instagram Data Scraper (you'll need to sign up)
        // Replace with your actual API key and endpoint
        // final response = await http.get(
        //   Uri.parse('https://instagram-data-scraper.p.rapidapi.com/user/$username'),
        //   headers: {
        //     'X-RapidAPI-Key': 'YOUR_API_KEY_HERE',
        //     'X-RapidAPI-Host': 'instagram-data-scraper.p.rapidapi.com'
        //   },
        // );
        // 
        // return response.statusCode == 200 && !response.body.contains('error');
        
        // Simulating API response for now
        await Future.delayed(Duration(seconds: 1));
        return true;
      }
      
      // Option 2: Enhanced format validation (offline approach)
      // Instagram usernames must:
      // - Be between 1-30 characters
      // - Only contain letters, numbers, periods, and underscores
      // - Cannot have consecutive periods
      // - Cannot end with a period
      // - Cannot start with a number or special character
      
      if (!_instagramRegExp.hasMatch(username)) {
        return false;
      }
      
      // Additional offline validation rules
      if (username.contains('..') || username.endsWith('.')) {
        return false;
      }
      
      // For demo purposes, consider the username valid if it passes format validation
      // In production, you might want to implement a more sophisticated check
      return true;
    } catch (e) {
      print('Error verifying Instagram account: $e');
      // Fall back to just accepting the format validation
      return _instagramRegExp.hasMatch(username);
    } finally {
      setState(() {
        _isValidatingInstagram = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _budgetRangeController.text = _budgetValue.toInt().toString();
    _cleanlinessLevelController.text = _cleanlinessValue.toInt().toString();
    // Set empty strings for email and name controllers since they'll be fetched from the profile API
    _emailController.text = '';
    _nameController.text = '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _instagramController.dispose();
    _ageController.dispose();
    _majorController.dispose();
    _budgetRangeController.dispose();
    _cleanlinessLevelController.dispose();
    _snapchatController.dispose();
    _bedtimeController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    
    // Dispose new controllers
    _wakeTimeController.dispose();
    _sleepTimeController.dispose();
    
    super.dispose();
  }

  // Image Selection Method
  Future<void> _pickImage() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web platform
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageUrl = null; // Reset the uploaded URL when a new image is selected
          });
          // Upload image after setting state
          _uploadProfileImage();
        } else {
          // For mobile platforms
          setState(() {
            _selectedImage = File(pickedFile.path);
            _imageUrl = null; // Reset the uploaded URL when a new image is selected
          });
          // Upload image automatically after selection
          _uploadProfileImage();
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload profile image to Supabase Storage
  Future<void> _uploadProfileImage() async {
    // Check if there's an image to upload
    if (!kIsWeb && _selectedImage == null) return;
    if (kIsWeb && _webImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Get user email to use as user ID
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? 'unknown_user';
      
      // Make email safe for use in file names by removing special characters
      final safeUserId = userEmail.replaceAll(RegExp(r'[^\w\s]+'), '_');

      // Upload image to Supabase Storage
      final supabaseService = SupabaseService();
      
      if (!supabaseService.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supabase service is not initialized. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }
      
      // Use the appropriate image source based on platform
      final imageSource = kIsWeb ? _webImage : _selectedImage;
      
      final uploadedUrl = await supabaseService.uploadProfileImage(
        imageSource: imageSource,
        userId: safeUserId,
      );

      if (uploadedUrl != null) {
        setState(() {
          _imageUrl = uploadedUrl;
        });
        print('Image uploaded successfully: $_imageUrl');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      String errorMessage = 'Error uploading image';
      
      if (e.toString().contains('storage/object-too-large')) {
        errorMessage = 'Image is too large. Please choose a smaller image.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check your Supabase configuration.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _updateOnboarding() async {
    // Validate all fields across all forms
    for (int i = 0; i < _formKeys.length; i++) {
      final formState = _formKeys[i].currentState;
      if (formState != null && !formState.validate()) {
        // If any form is invalid, navigate to that page
        _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please correct the errors before submitting'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    
    // Additional validation for required fields not covered by form validation
    if (_selectedGender == null ||
        _selectedUniversity == null ||
        _selectedYearOfStudy == null ||
        _selectedSocialPreference == null ||
        _ageController.text.isEmpty ||
        _instagramController.text.isEmpty ||
        _cleanlinessLevelController.text.isEmpty ||
        _selectedGuestPolicy == null ||
        _selectedRoomType == null ||
        _sleepTimeController.text.isEmpty ||
        _wakeTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all required fields in each section before submitting.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Validate Instagram username format more thoroughly
    if (!await _verifyInstagramAccount(_instagramController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The Instagram username format appears to be invalid. Please check and try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      // Navigate to the Instagram input page
      _pageController.animateToPage(
        3, // Contact Info page
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Retrieve access token from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Get user profile to access email and full name
      final response = await http.get(
        Uri.parse('${utils.BASE_URL}/auth/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get user profile');
      }

      final profileData = jsonDecode(response.body);
      final email = profileData['email'];
      final fullName = profileData['full_name'];

      // Construct request body with all fields including new ones
      final Map<String, dynamic> userData = {
        'email': email,
        'full_name': fullName,
        'instagram': _instagramController.text,
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'university': _selectedUniversity,
        'year_of_study': _selectedYearOfStudy,
        'major': _majorController.text,
        'profile_picture': _imageUrl,
        'bio': _bioController.text,
        'budget_range': int.parse(_budgetRangeController.text),
        'cleanliness_level': int.parse(_cleanlinessLevelController.text),
        'social_preference': _selectedSocialPreference,
        'music_preference': _musicPreference,
        'smoking_preference': _smokingPreference,
        'drinking_preference': _drinkingPreference,
        'pet_preference': _petPreference,
        'snapchat': _snapchatController.text.isEmpty
            ? null
            : _snapchatController.text,
        'phone_number': _phoneNumberController.text.isEmpty
            ? null
            : _phoneNumberController.text,
        // New fields
        'wake_time': _wakeTimeController.text,
        'sleep_time': _sleepTimeController.text,
        'guest_policy': _selectedGuestPolicy,
        'room_type_preference': _selectedRoomType,
        'religious_preference': _selectedReligiousPreference == 'None' ? null : _selectedReligiousPreference,
        'dietary_restrictions': _selectedDietaryRestriction == 'None' ? null : _selectedDietaryRestriction,
        'onboarding_completed': true,
      };

      // Send update request
      final updateResponse = await http.post(
        Uri.parse('${utils.BASE_URL}/auth/update-onboarding'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (updateResponse.statusCode == 200) {
        // Use AuthService to mark onboarding as completed
        final authService = AuthService();
        await authService.markOnboardingCompleted();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to the swipe screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/swipe');
        }
      } else {
        final errorData = jsonDecode(updateResponse.body);
        throw Exception(errorData['detail'] ?? 'Failed to update profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    // Validate current form before proceeding
    if (_formKeys[_currentPage].currentState?.validate() ?? false) {
      if (_currentPage < _totalPages - 1) {
        bool canProceed = true;
        String errorMessage = '';
        
        // Additional validation based on current page
        if (_currentPage == 0) { // Basic Info page
          if (_selectedGender == null) {
            canProceed = false;
            errorMessage = 'Please select your gender.';
          }
        } else if (_currentPage == 1) { // Education page
          if (_selectedUniversity == null || _selectedYearOfStudy == null) {
            canProceed = false;
            errorMessage = 'Please select your university and year of study.';
          }
        } else if (_currentPage == 2) { // Living Preferences page
          if (_selectedSocialPreference == null ||
              _selectedGuestPolicy == null ||
              _selectedRoomType == null) {
            canProceed = false;
            errorMessage = 'Please complete all required dropdown selections.';
          }
        }
        
        if (canProceed) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else {
        // If we're on the last page, submit the form
        _formKeys[_currentPage].currentState?.save();
        _updateOnboarding();
      }
    } else {
      // Show a message that there are validation errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before proceeding'),
          backgroundColor: AppColors.error,
        ),
      );
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

  // Add a method to complete onboarding
  Future<void> _completeOnboarding() async {
    try {
      // Use the AuthService to properly mark onboarding as completed
      final authService = AuthService();
      await authService.markOnboardingCompleted();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/swipe');
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving your profile: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = const Color(0xFF0F1A24);  // Dark blue background
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // Background Pattern
          const FurniturePatternBackground(
            opacity: 0.2,
            spacing: 70,
            iconColor: Color(0xFF293542),
          ),

          // Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.6,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scaffoldBg.withOpacity(0.0),
                    scaffoldBg.withOpacity(0.5),
                    scaffoldBg.withOpacity(0.9),
                    scaffoldBg,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // Back Button and Title in Row
                          Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    "Create Your Profile",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 36),
                            ],
                          ),
                          const SizedBox(height: 32),

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
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (_currentPage + 1) / _totalPages,
                                  backgroundColor: Colors.grey[800],
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonBlue),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Page content with Expanded
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
                    Padding(
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
                          SizedBox(
                            width: 120,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
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
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
            Text(
              'Let\'s get to know you',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This information helps us create your profile',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            
            // Profile image picker
            Column(
              children: [
                Text(
                  'Profile Picture',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.buttonBlue, width: 2),
                          image: _imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : _webImage != null
                                  ? DecorationImage(
                                      image: MemoryImage(_webImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : _selectedImage != null
                                      ? DecorationImage(
                                          image: FileImage(_selectedImage!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                        ),
                        child: (_imageUrl == null && _selectedImage == null && _webImage == null)
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white70,
                              )
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.buttonBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (_isUploadingImage)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                if (_imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Image uploaded',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Age field
            _buildTextField(
              controller: _ageController,
              label: 'Age',
              keyboardType: TextInputType.number,
              validator: _validateAge,
            ),
            const SizedBox(height: 16),
            
            // Gender dropdown
            _buildDropdown(
              label: 'Gender',
              value: _selectedGender,
              items: const ['Male', 'Female', 'Other'],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
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
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tell us about your academic background',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // University dropdown
            _buildDropdown(
              label: 'University',
              value: _selectedUniversity,
              items: const ['Columbia University', 'Cornell University'],
              onChanged: (value) {
                setState(() {
                  _selectedUniversity = value;
                });
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
            _buildDropdown(
              label: 'Year of Study',
              value: _selectedYearOfStudy,
              items: const ['1', '2', '3', '4', '5'],
              onChanged: (value) {
                setState(() {
                  _selectedYearOfStudy = value;
                });
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
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Help us find your perfect roommate match',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Budget Range slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maximum Monthly Budget',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${_budgetValue.toInt()}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Up to \$5000',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Slider(
                  value: _budgetValue,
                  min: 0,
                  max: 5000,
                  divisions: 50,
                  activeColor: AppColors.primaryBlue,
                  inactiveColor: Colors.grey[800],
                  onChanged: (value) {
                    setState(() {
                      _budgetValue = value;
                      _budgetRangeController.text = value.toInt().toString();
                    });
                  },
                ),
                // Add a hidden FormField for validation purposes
                FormField<String>(
                  initialValue: _budgetRangeController.text,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Budget is required';
                    }
                    final budget = int.tryParse(value);
                    if (budget == null) {
                      return 'Please enter a valid budget';
                    }
                    if (budget < 0) {
                      return 'Budget cannot be negative';
                    }
                    return null;
                  },
                  builder: (FormFieldState<String> state) {
                    if (state.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      );
                    }
                    return Container();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cleanliness Level slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Room Tidiness Level',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_cleanlinessValue.toInt()}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '1 (Messy) - 10 (Organized)',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Slider(
                  value: _cleanlinessValue,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: AppColors.primaryBlue,
                  inactiveColor: Colors.grey[800],
                  onChanged: (value) {
                    setState(() {
                      _cleanlinessValue = value;
                      _cleanlinessLevelController.text = value.toInt().toString();
                    });
                  },
                ),
                // Add a hidden FormField for validation purposes
                FormField<String>(
                  initialValue: _cleanlinessLevelController.text,
                  validator: _validateCleanliness,
                  builder: (FormFieldState<String> state) {
                    if (state.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      );
                    }
                    return Container();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Social Preference dropdown
            _buildDropdown(
              label: 'Social Preference',
              value: _selectedSocialPreference,
              items: const ['Introvert', 'Extrovert', 'Ambivert'],
              onChanged: (value) {
                setState(() {
                  _selectedSocialPreference = value;
                });
              },
            ),
            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Music Preference',
              value: _selectedMusicPreference,
              items: const ['Headphones', 'Speakers'],
              onChanged: (value) {
                setState(() {
                  _selectedMusicPreference = value;
                  // Map the selection to a boolean: 'Headphones' = false, 'Speakers' = true
                  _musicPreference = (value == 'Speakers');
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Sleep/Wake Schedule Section
            const Text(
              'Sleep & Wake Schedule',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            
            // Sleep Time with validation
            TextFormField(
              controller: _sleepTimeController,
              style: const TextStyle(color: AppColors.textPrimary),
              readOnly: true,
              validator: _validateTime,
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primaryBlue,
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
                    _sleepTimeController.text = "$hours:$minutes";
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Sleep Time *',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.inputBackground,
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
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                errorStyle: const TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
            
            // Wake time with validation
            TextFormField(
              controller: _wakeTimeController,
              style: const TextStyle(color: AppColors.textPrimary),
              readOnly: true,
              validator: _validateTime,
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primaryBlue,
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
                    _wakeTimeController.text = "$hours:$minutes";
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Wake Time *',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.inputBackground,
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
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                errorStyle: const TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 20),
            
            // Guest Policy dropdown
            _buildDropdown(
              label: 'Guest Policy',
              value: _selectedGuestPolicy,
              items: const ['Frequent', 'Occasional', 'Rare', 'None'],
              onChanged: (value) {
                setState(() {
                  _selectedGuestPolicy = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Room Type Preference dropdown
            _buildDropdown(
              label: 'Room Type Preference',
              value: _selectedRoomType,
              items: const ['2-person', '3-person', '4-person', '5-person', 'Any'],
              onChanged: (value) {
                setState(() {
                  _selectedRoomType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Religious Preference dropdown
            _buildDropdown(
              label: 'Religious/Cultural Preference (Optional)',
              value: _selectedReligiousPreference,
              items: const ['Muslim', 'Christian', 'Jewish', 'Hindu', 'Buddhist', 'None', 'Other'],
              onChanged: (value) {
                setState(() {
                  _selectedReligiousPreference = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Dietary Restrictions dropdown
            _buildDropdown(
              label: 'Dietary Restrictions (Optional)',
              value: _selectedDietaryRestriction,
              items: const ['Halal', 'Kosher', 'Vegetarian', 'Vegan', 'None', 'Other'],
              onChanged: (value) {
                setState(() {
                  _selectedDietaryRestriction = value;
                });
              },
            ),
            const SizedBox(height: 20),
            
            // Preference toggles
            const Text(
              'Lifestyle Preferences',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
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
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'How potential roommates can reach you',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Instagram field with validation and user guidance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _instagramController,
                  label: 'Instagram Username',
                  validator: _validateInstagram,
                  helperText: 'Enter your username without the @ symbol',
                ),
                if (_isValidatingInstagram)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Validating username format...',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                  child: Text(
                    'Format: Letters, numbers, underscore (_) and periods (.)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Snapchat field with validation
            TextFormField(
              controller: _snapchatController,
              style: const TextStyle(color: AppColors.textPrimary),
              validator: _validateSnapchat,
              decoration: InputDecoration(
                labelText: 'Snapchat (Optional)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.inputBackground,
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
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                errorStyle: const TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
            
            // Phone Number field with validation
            TextFormField(
              controller: _phoneNumberController,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.phone,
              validator: _validatePhoneNumber,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.inputBackground,
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
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                errorStyle: const TextStyle(color: AppColors.error),
              ),
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
                      Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Almost done!',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Click Submit to complete your profile setup and start finding your perfect roommate match.',
                    style: TextStyle(color: AppColors.textSecondary),
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
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
            onTap: onTap,
            validator: validator,
            decoration: InputDecoration(
              hintText: 'Write here',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              helperText: helperText,
              helperStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              errorStyle: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      activeColor: AppColors.buttonBlue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Helper method for building dropdowns with consistent styling
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}

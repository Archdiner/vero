import 'dart:convert';
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
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _budgetRangeController = TextEditingController();
  final TextEditingController _moveInDateController = TextEditingController();
  final TextEditingController _cleanlinessLevelController = TextEditingController();
  final TextEditingController _snapchatController = TextEditingController();
  final TextEditingController _bedtimeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  // New controllers for enhanced matching
  final TextEditingController _wakeTimeController = TextEditingController();
  final TextEditingController _sleepTimeController = TextEditingController();

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
    _moveInDateController.dispose();
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
    // Check for required fields
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
          backgroundColor: Colors.red,
        ),
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
        'instagram_username': _instagramController.text,
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'university': _selectedUniversity,
        'year_of_study': _selectedYearOfStudy,
        'major': _majorController.text,
        'profile_picture_url': _imageUrl,
        'bio': _bioController.text,
        'move_in_date': _moveInDateController.text.isNotEmpty
            ? _moveInDateController.text
            : null,
        'budget_range': int.parse(_budgetRangeController.text),
        'cleanliness_level': int.parse(_cleanlinessLevelController.text),
        'social_preference': _selectedSocialPreference,
        'music_preference': _musicPreference,
        'smoking_preference': _smokingPreference,
        'drinking_preference': _drinkingPreference,
        'pet_preference': _petPreference,
        'snapchat_username': _snapchatController.text.isEmpty
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
        // Update shared preferences to indicate onboarding is completed
        await prefs.setBool('onboarding_completed', true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Call _completeOnboarding to update preferences and navigate to swipe screen
        _completeOnboarding();
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
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      bool canProceed = true;
      String errorMessage = '';
      
      // Validate based on current page
      if (_currentPage == 0) { // Basic Info page
        if (_ageController.text.isEmpty ||
            _selectedGender == null) {
          canProceed = false;
          errorMessage = 'Please fill all required fields on this page: age and gender.';
        }
      } else if (_currentPage == 1) { // Education page
        if (_selectedUniversity == null || _selectedYearOfStudy == null) {
          canProceed = false;
          errorMessage = 'Please select your university and year of study.';
        }
      } else if (_currentPage == 2) { // Living Preferences page
        if (_cleanlinessLevelController.text.isEmpty ||
            _selectedSocialPreference == null ||
            _selectedGuestPolicy == null ||
            _selectedRoomType == null ||
            _sleepTimeController.text.isEmpty ||
            _wakeTimeController.text.isEmpty) {
          canProceed = false;
          errorMessage = 'Please fill all required living preference fields.';
        }
      } else if (_currentPage == 3) { // Contact Information page
        if (_instagramController.text.isEmpty) {
          canProceed = false;
          errorMessage = 'Please provide your Instagram username.';
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
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // If we're on the last page, submit the form
      _formKeys[_currentPage].currentState?.save();
      _updateOnboarding();
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
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
            
            // Profile image picker
            Column(
              children: [
                const Text(
                  'Profile Picture',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
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
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF6F40), width: 2),
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6F40),
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
                    child: CircularProgressIndicator(),
                  ),
                if (_imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Image uploaded',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
              ],
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

            // Cleanliness Level slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Room Tidiness Level',
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
                      '1 (Messy) - 10 (Organized)',
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
                  lastDate: DateTime(2025, 12, 31),
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

            _buildRequiredDropdown(
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your music preference';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Sleep/Wake Schedule Section
            const Text(
              'Sleep & Wake Schedule',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            
            // Bedtime with TimePicker (moved from contact info)
            _buildTextField(
              controller: _sleepTimeController,
              label: 'Sleep Time',
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
                    _sleepTimeController.text = "$hours:$minutes";
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Wake time with TimePicker
            _buildTextField(
              controller: _wakeTimeController,
              label: 'Wake Time',
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
                    _wakeTimeController.text = "$hours:$minutes";
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            
            // Guest Policy dropdown
            _buildRequiredDropdown(
              label: 'Guest Policy',
              value: _selectedGuestPolicy,
              items: const ['Frequent', 'Occasional', 'Rare', 'None'],
              onChanged: (value) {
                setState(() {
                  _selectedGuestPolicy = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your guest policy preference';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Room Type Preference dropdown
            _buildRequiredDropdown(
              label: 'Room Type Preference',
              value: _selectedRoomType,
              items: const ['2-person', '3-person', '4-person', '5-person', 'Any'],
              onChanged: (value) {
                setState(() {
                  _selectedRoomType = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your preferred room type';
                }
                return null;
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
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white),
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
        style: const TextStyle(color: Colors.white),
      ),
      value: value,
      activeColor: const Color(0xFFFF6F40),
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Build a dropdown field without required validation
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

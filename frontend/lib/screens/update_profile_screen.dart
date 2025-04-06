import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart' as utils;
import '../utils/themes.dart'; // Import your theme file
import '../main.dart'; // For accessing global objects if needed

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController yearOfStudyController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController snapController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();

  String? selectedGender; // For gender dropdown

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${utils.BASE_URL}/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          fullNameController.text = data['fullname'] ?? '';
          emailController.text = data['email'] ?? '';
          ageController.text = data['age'] != null ? data['age'].toString() : '';
          yearOfStudyController.text = data['year_of_study'] != null ? data['year_of_study'].toString() : '';
          instagramController.text = data['instagram'] ?? '';
          snapController.text = data['snapchat'] ?? '';
          phoneNumberController.text = data['phone_number'] ?? '';
          selectedGender = data['gender'] ?? null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load profile")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> updateProfile() async {
    // Validate password change fields if new password is provided.
    if (newPasswordController.text.isNotEmpty) {
      if (oldPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your old password")),
        );
        return;
      }
      if (newPasswordController.text != confirmNewPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New passwords do not match")),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = '${utils.BASE_URL}/update_profile';
    final Map<String, dynamic> requestBody = {
      "fullname": fullNameController.text.trim(),
      "email": emailController.text.trim(),
    };

    if (ageController.text.isNotEmpty) {
      requestBody["age"] = int.tryParse(ageController.text.trim());
    }
    if (yearOfStudyController.text.isNotEmpty) {
      requestBody["year_of_study"] = int.tryParse(yearOfStudyController.text.trim());
    }
    if (instagramController.text.isNotEmpty) {
      requestBody["instagram"] = instagramController.text.trim();
    }
    if (snapController.text.isNotEmpty) {
      requestBody["snapchat"] = snapController.text.trim();
    }
    if (phoneNumberController.text.isNotEmpty) {
      requestBody["phone_number"] = phoneNumberController.text.trim();
    }
    if (selectedGender != null && selectedGender!.isNotEmpty) {
      requestBody["gender"] = selectedGender;
    }
    if (newPasswordController.text.isNotEmpty) {
      requestBody["old_password"] = oldPasswordController.text;
      requestBody["new_password"] = newPasswordController.text;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      } else {
        final data = json.decode(response.body);
        final errorMsg = data['detail'] ?? 'Update failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    ageController.dispose();
    yearOfStudyController.dispose();
    instagramController.dispose();
    snapController.dispose();
    phoneNumberController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: brightness == Brightness.dark ? Colors.black : AppColors.primaryBlue,
        leadingWidth: 80,
        // Back button: white in light mode, blue in dark mode.
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Back",
            style: TextStyle(
              color: brightness == Brightness.light ? Colors.white : AppColors.primaryBlue,
              fontSize: 16,
            ),
          ),
        ),
        title: const Text(
          "Update Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: fullNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                brightness: brightness,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: emailController,
                label: 'Email',
                hint: 'Enter your email',
                brightness: brightness,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Row for Age and Gender
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: ageController,
                      label: 'Age',
                      hint: 'Enter your age',
                      brightness: brightness,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedGender,
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        labelStyle: TextStyle(
                          color: brightness == Brightness.light
                              ? Colors.black54
                              : AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: brightness == Brightness.light ? Colors.white : AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(
                        color: brightness == Brightness.light ? Colors.black87 : AppColors.textPrimary,
                      ),
                      dropdownColor: brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row for Year of Study and Phone Number
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: yearOfStudyController,
                      label: 'Year of Study',
                      hint: 'Enter your year of study',
                      brightness: brightness,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: phoneNumberController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      brightness: brightness,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row for Instagram and Snapchat
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: instagramController,
                      label: 'Instagram',
                      hint: 'Enter your Instagram username',
                      brightness: brightness,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: snapController,
                      label: 'Snapchat',
                      hint: 'Enter your Snapchat username',
                      brightness: brightness,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Old Password field
              _buildTextField(
                controller: oldPasswordController,
                label: 'Old Password',
                hint: 'Enter your old password',
                brightness: brightness,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              // Row for New Password and Confirm New Password fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: newPasswordController,
                      label: 'New Password',
                      hint: 'Enter new password',
                      brightness: brightness,
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: confirmNewPasswordController,
                      label: 'Confirm New Password',
                      hint: 'Re-enter new password',
                      brightness: brightness,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Save Changes button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: brightness == Brightness.light ? Colors.white : AppColors.textPrimary,
                        )
                      : Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: brightness == Brightness.light ? Colors.white : AppColors.textPrimary,
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

  // Helper widget to build text fields with correct colors for dark/light mode.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Brightness brightness,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        color: brightness == Brightness.light ? Colors.black87 : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: brightness == Brightness.light ? Colors.black54 : AppColors.textSecondary,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: brightness == Brightness.light ? Colors.black26 : AppColors.textDisabled,
        ),
        filled: true,
        // Use a light grey fill color in light mode for more visible input fields.
        fillColor: brightness == Brightness.light ? Colors.grey[200] : AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

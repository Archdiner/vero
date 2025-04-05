import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart' as utils;
import '../utils/themes.dart'; // Import your theme file

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leadingWidth: 80,
        // Do not change this button; leave it as is.
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Back",
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 16,
            ),
          ),
        ),
        title: const Text("Update Profile", style: TextStyle(color: AppColors.textPrimary)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name field
              TextField(
                controller: fullNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'Enter your full name',
                  hintStyle: const TextStyle(color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Email field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'Enter your email',
                  hintStyle: const TextStyle(color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Row for Age and Gender
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Age',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'Enter your age',
                        hintStyle: const TextStyle(color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
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
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row for Year of Study and Phone Number
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: yearOfStudyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Year of Study',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'Enter your year of study',
                        hintStyle: const TextStyle(color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: phoneNumberController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'Enter your phone number',
                        hintStyle: const TextStyle(color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row for Instagram and Snapchat
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: instagramController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Instagram',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'Enter your Instagram username',
                        hintStyle: const TextStyle(color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: snapController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Snapchat',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'Enter your Snapchat username',
                        hintStyle: const TextStyle(color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Old Password field
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'Enter your old password',
                  hintStyle: const TextStyle(color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Row for New Password and Confirm New Password fields
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'Enter new password',
                        hintStyle: const TextStyle(color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: confirmNewPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'Re-enter new password',
                        hintStyle: const TextStyle(color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
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
                      ? const CircularProgressIndicator(color: AppColors.textPrimary)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
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

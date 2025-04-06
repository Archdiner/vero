import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart' as utils;
import '../utils/themes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers for the text fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController verifyPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureVerifyPassword = true;

  // Email validation regex pattern
  final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  // Password validation: at least 8 characters with at least one letter and one number
  final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
  );

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegExp.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (!_passwordRegExp.hasMatch(password)) {
      return 'Password must be at least 8 characters with at least one letter and one number';
    }
    return null;
  }

  String? _validateFullName(String fullName) {
    if (fullName.isEmpty) {
      return 'Full name is required';
    }
    if (fullName.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  Future<void> register() async {
    // Validate email
    final emailError = _validateEmail(emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate password
    final passwordError = _validatePassword(passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate full name
    final fullNameError = _validateFullName(fullNameController.text);
    if (fullNameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fullNameError), backgroundColor: Colors.red),
      );
      return;
    }

    // Check if passwords match
    if (passwordController.text != verifyPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = '${utils.BASE_URL}/register';

    try {
      final requestBody = {
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "fullname": fullNameController.text.trim()
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();

        if (data['access_token'] == null) {
          throw Exception("No access token received");
        }
        
        await prefs.setString('access_token', data['access_token']);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful!")),
        );

        // Navigate to onboarding screen
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        final responseBody = json.decode(response.body);
        String errorMsg = responseBody['detail'] ?? 'Registration failed';
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message
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
    // Dispose controllers when the widget is removed from the widget tree
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    verifyPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top "Register" text
                Text(
                  "Register",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Big welcome text
                Text(
                  "Welcome to Vero!",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name field
                TextField(
                  controller: fullNameController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                    hintText: 'Write here',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                    hintText: 'Write here',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                    hintText: 'Write here',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Verify Password field
                TextField(
                  controller: verifyPasswordController,
                  obscureText: _obscureVerifyPassword,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Verify Password',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                    hintText: 'Write here',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureVerifyPassword = !_obscureVerifyPassword;
                        });
                      },
                      icon: Icon(
                        _obscureVerifyPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // "Continue" button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue, // Use theme blue color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // "Continue with" row (Google, Apple, etc.)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.g_mobiledata, color: Theme.of(context).iconTheme.color),
                      onPressed: () {
                        // Handle Google sign-up logic
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.apple, color: Theme.of(context).iconTheme.color),
                      onPressed: () {
                        // Handle Apple sign-up logic
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // "Already have an account? Log in"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        "Log in",
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

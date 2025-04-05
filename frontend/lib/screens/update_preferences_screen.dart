import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart' as utils;
import '../utils/themes.dart'; // Provides AppColors and AppTheme

class UpdatePreferencesScreen extends StatefulWidget {
  const UpdatePreferencesScreen({Key? key}) : super(key: key);

  @override
  State<UpdatePreferencesScreen> createState() => _UpdatePreferencesScreenState();
}

class _UpdatePreferencesScreenState extends State<UpdatePreferencesScreen> {
  // Slider values
  double _budgetValue = 1000.0;
  double _cleanlinessValue = 5.0;

  // Toggles
  bool _smokingPreference = false;
  bool _drinkingPreference = false;
  bool _petPreference = false;
  bool _musicPreference = false;

  // Controllers for text fields (for date and times)
  final TextEditingController _moveInDateController = TextEditingController();
  final TextEditingController _sleepTimeController = TextEditingController();
  final TextEditingController _wakeTimeController = TextEditingController();

  // Dropdown selections
  String? _selectedGuestPolicy; // e.g., 'Frequent', 'Occasional', 'Rare', 'None'
  String? _selectedRoomType;    // e.g., '2-person', '3-person', '4-person', '5-person', 'Any'
  String? _selectedReligiousPreference; // e.g., 'Muslim', 'Christian', 'Jewish', etc.
  String? _selectedDietaryRestriction;    // e.g., 'halal', 'kosher', 'vegetarian', 'vegan', 'none', 'other'
  String? _selectedSocialPreference;       // e.g., 'introvert', 'extrovert', 'ambivert'

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  Future<void> _loadCurrentPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    try {
      // Assumes /profile returns preference data along with other fields.
      final response = await http.get(
        Uri.parse('${utils.BASE_URL}/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _budgetValue = data['budget_range'] != null ? data['budget_range'].toDouble() : 1000.0;
          _cleanlinessValue = data['cleanliness_level'] != null ? data['cleanliness_level'].toDouble() : 5.0;
          _smokingPreference = data['smoking_preference'] ?? false;
          _drinkingPreference = data['drinking_preference'] ?? false;
          _petPreference = data['pet_preference'] ?? false;
          _musicPreference = data['music_preference'] ?? false;
          _moveInDateController.text = data['move_in_date'] ?? '';
          _sleepTimeController.text = data['sleep_time'] != null
              ? data['sleep_time'].toString().substring(0, 5)
              : '';
          _wakeTimeController.text = data['wake_time'] != null
              ? data['wake_time'].toString().substring(0, 5)
              : '';
          _selectedGuestPolicy = data['guest_policy'];
          _selectedRoomType = data['room_type_preference'];
          _selectedReligiousPreference = data['religious_preference'];
          _selectedDietaryRestriction = data['dietary_restrictions'] != null 
              ? data['dietary_restrictions'].toString().toLowerCase() 
              : null;
          _selectedSocialPreference = data['social_preference'] != null 
              ? data['social_preference'].toString().toLowerCase() 
              : null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load preferences")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> updatePreferences() async {
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    
    final url = '${utils.BASE_URL}/update_preferences';
    final Map<String, dynamic> requestBody = {
      "budget_range": _budgetValue.toInt(),
      "cleanliness_level": _cleanlinessValue.toInt(),
      "smoking_preference": _smokingPreference,
      "drinking_preference": _drinkingPreference,
      "pet_preference": _petPreference,
      "music_preference": _musicPreference,
      "move_in_date": _moveInDateController.text.isNotEmpty ? _moveInDateController.text : null,
      "sleep_time": _sleepTimeController.text.isNotEmpty ? _sleepTimeController.text : null,
      "wake_time": _wakeTimeController.text.isNotEmpty ? _wakeTimeController.text : null,
      "guest_policy": _selectedGuestPolicy,
      "room_type_preference": _selectedRoomType,
      "religious_preference": _selectedReligiousPreference,
      "dietary_restrictions": _selectedDietaryRestriction,
      "social_preference": _selectedSocialPreference,
    };
    
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
          const SnackBar(content: Text("Preferences updated successfully")),
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

  Future<void> _pickMoveInDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
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
    if (picked != null) {
      setState(() {
        _moveInDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }
  
  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
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
    if (picked != null) {
      final hours = picked.hour.toString().padLeft(2, '0');
      final minutes = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = "$hours:$minutes";
      });
    }
  }

  @override
  void dispose() {
    _moveInDateController.dispose();
    _sleepTimeController.dispose();
    _wakeTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leadingWidth: 80,
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
        title: const Text("Update Preferences", style: TextStyle(color: AppColors.textPrimary)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budget Range slider (alone)
              Text(
                'Maximum Monthly Budget',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${_budgetValue.toInt()}',
                    style: TextStyle(
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
                  });
                },
              ),
              const SizedBox(height: 16),
              // Cleanliness Level slider (alone)
              Text(
                'Room Tidiness Level',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_cleanlinessValue.toInt()}',
                    style: TextStyle(
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
                  });
                },
              ),
              const SizedBox(height: 16),
              // Row for toggles: Smoking and Drinking
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: Text(
                        'Smoking',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      value: _smokingPreference,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          _smokingPreference = val;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      title: Text(
                        'Drinking',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      value: _drinkingPreference,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          _drinkingPreference = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              // Row for toggles: Pet and Music
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: Text(
                        'Pet Friendly',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      value: _petPreference,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          _petPreference = val;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      title: Text(
                        'Music Preference',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      value: _musicPreference,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          _musicPreference = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row for Move In Date and Guest Policy
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _moveInDateController,
                      readOnly: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      onTap: _pickMoveInDate,
                      decoration: InputDecoration(
                        labelText: 'Move In Date',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'Select date',
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
                      value: _selectedGuestPolicy,
                      items: const [
                        DropdownMenuItem(value: 'Frequent', child: Text('Frequent')),
                        DropdownMenuItem(value: 'Occasional', child: Text('Occasional')),
                        DropdownMenuItem(value: 'Rare', child: Text('Rare')),
                        DropdownMenuItem(value: 'None', child: Text('None')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGuestPolicy = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Guest Policy',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row for Sleep and Wake Time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sleepTimeController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      readOnly: true,
                      onTap: () => _pickTime(_sleepTimeController),
                      decoration: InputDecoration(
                        labelText: 'Sleep Time',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'HH:MM',
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
                    child: TextFormField(
                      controller: _wakeTimeController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      readOnly: true,
                      onTap: () => _pickTime(_wakeTimeController),
                      decoration: InputDecoration(
                        labelText: 'Wake Time',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: 'HH:MM',
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
              // Row for Dietary Restrictions and Social Preference
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDietaryRestriction,
                      items: const [
                        DropdownMenuItem(value: 'halal', child: Text('Halal')),
                        DropdownMenuItem(value: 'kosher', child: Text('Kosher')),
                        DropdownMenuItem(value: 'vegetarian', child: Text('Vegetarian')),
                        DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                        DropdownMenuItem(value: 'none', child: Text('None')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDietaryRestriction = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Dietary Restrictions',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSocialPreference,
                      // Use lowercase values to match loaded data
                      items: const [
                        DropdownMenuItem(value: 'introvert', child: Text('Introvert')),
                        DropdownMenuItem(value: 'extrovert', child: Text('Extrovert')),
                        DropdownMenuItem(value: 'ambivert', child: Text('Ambivert')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSocialPreference = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Social Preference',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: AppColors.textPrimary),
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
                  onPressed: _isLoading ? null : updatePreferences,
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
  
  // Helper methods for building text fields and dropdowns
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        helperText: helperText,
        helperStyle: TextStyle(color: AppColors.textSecondary),
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
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item.toLowerCase(), // Ensure value is lowercase
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

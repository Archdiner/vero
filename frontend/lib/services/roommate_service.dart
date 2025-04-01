import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart' as utils;
import '../models/user_profile.dart';

class RoommateService {
  // Base URL from config
  final String _baseUrl = utils.BASE_URL;
  
  // Fetch potential roommate matches
  // Temporarily fetching all users until matching logic is implemented
  Future<List<UserProfile>> fetchPotentialMatches({
    required int offset,
    required int limit,
  }) async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }
      
      // Make API request for potential roommates
      final response = await http.get(
        Uri.parse('$_baseUrl/potential_roommates?offset=$offset&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Fetched ${data.length} potential roommates');
        return data.map((json) => UserProfile.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load potential roommates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching potential matches: $e');
      // Return empty list in case of error to avoid app crashes
      return [];
    }
  }
  
  // Like a potential roommate
  Future<bool> likeUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }
      
      // Convert string userId to int for the API
      int? roommateId = int.tryParse(userId);
      if (roommateId == null) {
        throw Exception('Invalid user ID format');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/like/$roommateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Usually the endpoint returns if it's a match
        final isMatch = data['is_match'] ?? false;
        
        // TODO: Handle match notification if isMatch is true
        if (isMatch) {
          print('It\'s a match!');
        }
        
        return true;
      } else {
        throw Exception('Failed to like user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error liking user: $e');
      return false;
    }
  }
  
  // Dislike a potential roommate
  Future<bool> dislikeUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }
      
      // Convert string userId to int for the API
      int? roommateId = int.tryParse(userId);
      if (roommateId == null) {
        throw Exception('Invalid user ID format');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/reject/$roommateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to dislike user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error disliking user: $e');
      return false;
    }
  }
  
  // Get current user's profile info
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }
      
      // First try to get the complete profile from the standard endpoint
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final basicUserData = json.decode(response.body);
        
        // Try to get profile picture from SharedPreferences first as a fallback
        String? profilePicture = await _getProfilePictureFromPrefs();
        
        // If we have a profile picture in the basic data, use it
        if (basicUserData.containsKey('profile_picture') && 
            basicUserData['profile_picture'] != null && 
            basicUserData['profile_picture'].toString().isNotEmpty) {
          profilePicture = basicUserData['profile_picture'];
        } else {
          // Otherwise, attempt to get detailed profile info
          try {
            final detailedResponse = await http.get(
              Uri.parse('$_baseUrl/auth/profile'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );
            
            if (detailedResponse.statusCode == 200) {
              final detailedData = json.decode(detailedResponse.body);
              // Update profile picture if available in detailed data
              if (detailedData.containsKey('profile_picture') && 
                  detailedData['profile_picture'] != null && 
                  detailedData['profile_picture'].toString().isNotEmpty) {
                profilePicture = detailedData['profile_picture'];
              }
              
              // Add any additional fields from the detailed response
              basicUserData.addAll(detailedData);
            }
          } catch (e) {
            print('Error fetching detailed profile: $e');
            // Continue with basic data, no need to throw
          }
        }
        
        // Add profile picture to the user data
        if (profilePicture != null && profilePicture.isNotEmpty) {
          basicUserData['profile_picture'] = profilePicture;
        }
        
        return basicUserData;
      } else {
        throw Exception('Failed to get user profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return {};
    }
  }
  
  // Helper method to get profile picture from SharedPreferences
  Future<String?> _getProfilePictureFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('profile_image_url');
    } catch (e) {
      print('Error getting profile picture from prefs: $e');
      return null;
    }
  }
} 
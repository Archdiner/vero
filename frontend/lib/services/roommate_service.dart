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
      
      // Send like request to backend
      // Backend should handle updating the roommate_matches table:
      // - If no record exists, create a new one with appropriate user_liked field set to true
      // - If record exists, update the appropriate user_liked field
      // - If both users have liked each other, update match_status accordingly
      final response = await http.post(
        Uri.parse('$_baseUrl/like/$roommateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if it's a match - the backend should determine this based on
        // both user1_liked and user2_liked being true in the roommate_matches table
        final isMatch = data['is_match'] ?? false;
        
        if (isMatch) {
          print('It\'s a match!');
        }
        
        return isMatch; // Return whether it's a match or not
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
      
      // Send reject request to backend
      // Backend should handle updating the roommate_matches table:
      // - Set rejected_at timestamp
      // - Update match_status to rejected
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
  
  // Fetch all successful matches for the current user
  Future<List<UserProfile>> fetchMatches() async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }
      
      // Make API request for matches based on the roommate_matches table
      final response = await http.get(
        Uri.parse('$_baseUrl/matches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Fetched ${data.length} matches');
        
        // Debug: Print the first match data to see what fields are included
        if (data.isNotEmpty) {
          print('First match response fields: ${data[0].keys.join(', ')}');
          print('First match data: ${data[0]}');
        }
        
        // Convert the response data to UserProfile objects
        List<UserProfile> matchProfiles = data.map((json) => UserProfile.fromJson(json)).toList();
        
        // Fetch additional profile details for each match
        List<UserProfile> enhancedProfiles = [];
        for (var match in matchProfiles) {
          try {
            // Add missing fields by getting user details
            final enhancedMatch = await _enhanceUserProfile(match);
            enhancedProfiles.add(enhancedMatch);
          } catch (e) {
            print('Error enhancing profile for ${match.fullName}: $e');
            enhancedProfiles.add(match); // Add original if enhancement fails
          }
        }
        
        return enhancedProfiles;
      } else {
        throw Exception('Failed to load matches: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching matches: $e');
      // Return empty list in case of error to avoid app crashes
      return [];
    }
  }
  
  // Helper method to enhance a user profile with missing data
  Future<UserProfile> _enhanceUserProfile(UserProfile profile) async {
    // Check if the profile is already complete
    if ((profile.university != 'Unknown University' && profile.university.isNotEmpty) && 
        profile.instagramUsername != null) {
      print('Profile for ${profile.fullName} is already complete, skipping enhancement');
      return profile; // Already has needed data
    }
    
    print('Enhancing profile for ${profile.fullName} - Missing university or Instagram');
    
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // First approach: Try to get complete user data from potential_roommates endpoint
      // This endpoint includes more fields than the matches endpoint
      final response = await http.get(
        Uri.parse('$_baseUrl/potential_roommates?offset=0&limit=100'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        
        // Find the matching user by ID
        final matchingUser = users.firstWhere(
          (user) => user['id'].toString() == profile.id,
          orElse: () => null
        );
        
        if (matchingUser != null) {
          print('Found matching user in potential_roommates: ${matchingUser['fullname']}');
          
          // Create a merged profile with existing data and new data
          final Map<String, dynamic> mergedData = profile.toJson();
          
          // Update only missing fields from matching user
          if (profile.university == 'Unknown University' || profile.university.isEmpty) {
            mergedData['university'] = matchingUser['university'];
          }
          
          if (profile.instagramUsername == null && matchingUser['instagram'] != null) {
            mergedData['instagram'] = matchingUser['instagram'];
          }
          
          // Return enhanced profile
          return UserProfile.fromJson(mergedData);
        }
      }
      
      // Second approach: Try to get direct profile from backend
      // This is useful when we need specific user data and is more future-proof
      print('Getting individual profile data for ID: ${profile.id}');
      
      // Request user profile directly using user ID - this endpoint may need to be added to backend
      final profileResponse = await http.get(
        Uri.parse('$_baseUrl/profile/${profile.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (profileResponse.statusCode == 200) {
        final userData = json.decode(profileResponse.body);
        print('Got profile data: ${userData.keys.join(', ')}');
        
        // Create merged profile data
        final Map<String, dynamic> mergedData = profile.toJson();
        
        // Update university if available
        if (userData['university'] != null) {
          mergedData['university'] = userData['university'];
        }
        
        // Update instagram if available (try both possible field names)
        if (userData['instagram'] != null) {
          mergedData['instagram'] = userData['instagram'];
        } else if (userData['instagram_username'] != null) {
          mergedData['instagram'] = userData['instagram_username'];
        }
        
        return UserProfile.fromJson(mergedData);
      }
      
      // Third approach: Try to use current user's university if college roommate matching
      // This assumes roommates are likely from the same university
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile.containsKey('university') && 
          currentUserProfile['university'] != null &&
          currentUserProfile['university'].isNotEmpty) {
        
        print('Using current user university: ${currentUserProfile['university']}');
        
        // Use the current user's university as a fallback since they're likely at same university
        final Map<String, dynamic> mergedData = profile.toJson();
        mergedData['university'] = currentUserProfile['university'];
        
        // We can't guess Instagram, but we can at least populate university
        return UserProfile.fromJson(mergedData);
      }
      
      // If all approaches fail, return original profile
      print('All enhancement approaches failed, returning original profile');
      return profile;
      
    } catch (e) {
      print('Error enhancing profile: $e');
      return profile; // Return original profile if enhancement fails
    }
  }
  
  // Unmatch from a user
  Future<bool> unmatchUser(String userId) async {
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
      
      // Send unmatch request to backend
      // Backend should handle updating the roommate_matches table:
      // - Update match_status to 'unmatched'
      final response = await http.post(
        Uri.parse('$_baseUrl/unmatch/$roommateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to unmatch user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unmatching user: $e');
      return false;
    }
  }
} 
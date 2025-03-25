import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../utils/config.dart' as utils;

class ApiService {
  final String baseUrl = '${utils.BASE_URL}';

  Future<List<Restaurant>> fetchRestaurants({int offset = 0, int limit = 10}) async {
    final response = await http.get(Uri.parse('$baseUrl/restaurants?offset=$offset&limit=$limit'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Restaurant.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load restaurants');
    }
  }

  // New method to toggle the favorite status of a restaurant
  Future<bool> toggleFavorite(int chainId) async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.post(
      Uri.parse('$baseUrl/toggle_favorite'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'},
      body: jsonEncode({
        "chain_id": chainId,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["current_state"];
    } else {
      throw Exception("Failed to toggle favorite");
    }
  }

  // Add this new method
  Future<String> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/get_user_name'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['first_name'];
      } else {
        throw Exception('Failed to load user name');
      }
    } catch (e) {
      print('Error getting user name: $e');
      return 'User'; // fallback name
    }
  }
}

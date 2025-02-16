import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';

class ApiService {
  final String baseUrl = 'http://10.0.2.2:8000';  // Works on Android Emulator

  Future<List<Restaurant>> fetchRestaurants({int offset = 0, int limit = 10}) async {
    final response = await http.get(Uri.parse('$baseUrl/restaurants?offset=$offset&limit=$limit'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Restaurant.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load restaurants');
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CityApiService {
  String get baseUrl{
    if(kIsWeb){
      return 'http://localhost:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  Future<List<Map<String, dynamic>>> autocompleteCities(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final uri = Uri.parse('$baseUrl/cities/autocomplete?q=$query');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch city suggestions');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> validateCity(String query) async {
    final uri = Uri.parse('$baseUrl/cities/validate?q=$query');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to validate city');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (data['valid'] == true) {
      return data['city'] as Map<String, dynamic>;
    }

    return null;
  }
}